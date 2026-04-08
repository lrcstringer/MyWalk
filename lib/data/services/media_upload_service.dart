import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import 'local_voice_cache_service.dart';

/// Describes a single local media file waiting to be uploaded.
class PendingMediaFile {
  final String type;       // 'image' | 'voice'
  final String localPath;
  final int index;         // image index (0-based); -1 for voice

  const PendingMediaFile({
    required this.type,
    required this.localPath,
    required this.index,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'localPath': localPath,
        'index': index,
      };

  factory PendingMediaFile.fromJson(Map<String, dynamic> j) => PendingMediaFile(
        type: j['type'] as String,
        localPath: j['localPath'] as String,
        index: (j['index'] as num).toInt(),
      );
}

class _PendingEntry {
  final String entryId;
  final List<PendingMediaFile> files;

  _PendingEntry({required this.entryId, required this.files});

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'files': files.map((f) => f.toJson()).toList(),
      };

  factory _PendingEntry.fromJson(Map<String, dynamic> j) => _PendingEntry(
        entryId: j['entryId'] as String,
        files: (j['files'] as List)
            .map((f) => PendingMediaFile.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList(),
      );
}

/// Manages offline-first media uploads for journal entries.
///
/// When a journal entry is saved with images or a voice note while offline,
/// the media files are stored locally and their paths are queued here.
/// This service processes the queue when connectivity is restored.
class MediaUploadService {
  MediaUploadService._();
  static final instance = MediaUploadService._();

  static const _queueKey = 'journal_upload_queue';

  late SharedPreferences _prefs;
  late JournalRepository _repo;

  /// Called after each entry's uploads are committed to Firestore.
  void Function(String entryId)? _onEntryUpdated;

  bool _processing = false;
  bool _needsRerun = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Future<void> init(SharedPreferences prefs, JournalRepository repo) async {
    // Cancel any existing connectivity subscription before re-subscribing so
    // that calling init() more than once (e.g. after re-authentication) does
    // not leave orphaned listeners that fire processQueue() indefinitely.
    _connectivitySub?.cancel();

    _prefs = prefs;
    _repo = repo;
    LocalVoiceCacheService.instance.init(prefs);

    // Listen for connectivity changes and process queue when online.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) processQueue().ignore();
    });

    // Process any leftover queue from a previous session.
    processQueue().ignore();
  }

  /// Register a callback invoked after each entry's media is successfully
  /// uploaded and committed to Firestore. Used by [JournalProvider] to keep
  /// its in-memory state in sync without a direct cross-layer dependency.
  void registerEntryUpdatedCallback(void Function(String entryId) callback) {
    _onEntryUpdated = callback;
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  /// Remove a journal entry from the upload queue and delete its staged local
  /// files. Call this when a journal entry is deleted while its upload is still
  /// pending, to prevent orphaned Firebase Storage objects.
  ///
  /// If a [processQueue] run is currently uploading the entry, the upload will
  /// still complete (it has already snapshotted the queue). The resulting
  /// Storage objects will not be referenced anywhere and the Firestore write
  /// will be skipped (entry no longer in [allEntries]). This is an accepted
  /// narrow race window — the files are then permanently orphaned in Storage.
  /// To eliminate this entirely a running-entry cancellation token would be
  /// required; for now, the window is the duration of a single Storage PUT.
  Future<void> cancelEntry(String entryId) async {
    final queue = _loadQueue();
    final entry = queue.where((e) => e.entryId == entryId).firstOrNull;
    if (entry == null) return;

    // Delete staged local files synchronously before clearing the queue entry.
    for (final file in entry.files) {
      try { File(file.localPath).deleteSync(); } catch (_) {}
    }

    queue.removeWhere((e) => e.entryId == entryId);
    await _saveQueue(queue);

    if (_processing) {
      // If currently processing, the running snapshot already has this entry.
      // Flag a re-run so it won't be re-added after the current run finishes.
      _needsRerun = false;
    }
  }

  /// Enqueue media files for a journal entry and start processing immediately.
  Future<void> enqueueUploads(String entryId, List<PendingMediaFile> files) async {
    if (files.isEmpty) return;
    final queue = _loadQueue();
    // Replace any existing entry for this id (e.g. re-save after edit).
    queue.removeWhere((e) => e.entryId == entryId);
    queue.add(_PendingEntry(entryId: entryId, files: files));
    // Await the write so the queue is on disk before processQueue reads it.
    await _saveQueue(queue);
    if (_processing) {
      // A run is already in progress and has already loaded its queue snapshot.
      // Flag it to re-run when it finishes so the new entry isn't skipped.
      _needsRerun = true;
    } else {
      processQueue().ignore();
    }
  }

  /// Process all pending uploads. Safe to call concurrently — only one run at a time.
  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      final queue = _loadQueue();
      if (queue.isEmpty) return;

      // Check connectivity first.
      final results = await Connectivity().checkConnectivity();
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (!isOnline) return;

      // Load journal entries once for the entire run rather than once per
      // pending entry. The list is fetched lazily on first use so an empty
      // queue (caught above) never triggers a Firestore read.
      List<JournalEntry>? cachedEntries;
      for (final pending in List.of(queue)) {
        cachedEntries ??= await _repo.loadEntries();
        await _processEntry(pending, queue, cachedEntries);
      }
    } finally {
      _processing = false;
      // If enqueueUploads was called while we were running, process those
      // entries now rather than waiting for the next connectivity event.
      if (_needsRerun) {
        _needsRerun = false;
        processQueue().ignore();
      }
    }
  }

  Future<void> _processEntry(
    _PendingEntry pending,
    List<_PendingEntry> queue,
    List<JournalEntry> allEntries,
  ) async {
    // Track files uploaded to Storage this run (but not yet committed to Firestore).
    // Local files are NOT deleted until the Firestore write succeeds.
    final uploaded = <({PendingMediaFile file, String url})>[];
    final stillPending = List<PendingMediaFile>.from(pending.files);

    for (final file in List.of(stillPending)) {
      if (!File(file.localPath).existsSync()) {
        // Local file missing (e.g. user uninstalled + reinstalled) — drop silently.
        stillPending.remove(file);
        continue;
      }
      try {
        final filename = file.type == 'voice'
            ? 'voice.m4a'
            : 'image_${file.index}.jpg';
        final url = await _repo.uploadMedia(file.localPath, pending.entryId, filename);
        uploaded.add((file: file, url: url));
      } catch (_) {
        // Upload failed — stop processing this entry; retry on next queue run.
        break;
      }
    }

    if (uploaded.isEmpty) {
      if (stillPending.isEmpty) {
        // All files were missing (dropped above) — no upload is possible or needed.
        // Clear uploadPending in Firestore so the banner doesn't stick forever,
        // then remove the entry from the queue.
        try {
          final current =
              allEntries.where((e) => e.id == pending.entryId).firstOrNull;
          if (current != null && current.uploadPending) {
            await _repo.updateEntry(current.copyWith(uploadPending: false));
          }
          _onEntryUpdated?.call(pending.entryId);
        } catch (_) {
          // Best-effort — if this fails the banner will show until next retry.
        }
      }
      // If stillPending is non-empty, files exist but uploads failed — keep the
      // queue entry and retry on the next processQueue run.
      await _commitQueue(queue, pending.entryId, stillPending);
      return;
    }

    // Attempt to commit uploaded URLs to Firestore.
    // IMPORTANT: local files are only deleted after this succeeds, so a failed
    // Firestore write does not result in orphaned Storage objects.
    bool committed = false;
    try {
      final current = allEntries.where((e) => e.id == pending.entryId).firstOrNull;
      if (current != null) {
        final newImages = uploaded
            .where((u) => u.file.type == 'image')
            .map((u) => u.url)
            .toList();
        final newVoice = uploaded
            .where((u) => u.file.type == 'voice')
            .map((u) => u.url)
            .firstOrNull;
        // Files remaining after this commit = stillPending minus uploaded.
        final afterCommit = stillPending
            .where((f) => !uploaded.any((u) => u.file.localPath == f.localPath))
            .toList();
        final updated = current.copyWith(
          imageUrls: [...current.imageUrls, ...newImages],
          voiceUrl: newVoice ?? current.voiceUrl,
          uploadPending: afterCommit.isNotEmpty,
        );
        await _repo.updateEntry(updated);
      }
      // Entry deleted between save and upload — no Firestore doc to update;
      // treat as committed so we don't retry indefinitely.
      committed = true;
    } catch (_) {
      // Firestore write failed — local files are NOT deleted here; will retry.
    }

    if (committed) {
      // Clean up local staging files; retain voice files for offline playback.
      for (final (:file, url: _) in uploaded) {
        if (file.type == 'voice') {
          // Keep the voice file for offline playback and register it.
          LocalVoiceCacheService.instance
              .setPath(pending.entryId, file.localPath)
              .ignore();
        } else {
          try { File(file.localPath).deleteSync(); } catch (_) {}
        }
        stillPending.remove(file);
      }
      _onEntryUpdated?.call(pending.entryId);
    }
    // If not committed, stillPending still holds the uploaded files → will retry,
    // re-uploading to Storage (same filename = overwrite), then retry Firestore.

    await _commitQueue(queue, pending.entryId, stillPending);
  }

  Future<void> _commitQueue(
      List<_PendingEntry> queue, String entryId, List<PendingMediaFile> remaining) async {
    queue.removeWhere((e) => e.entryId == entryId);
    if (remaining.isNotEmpty) {
      queue.add(_PendingEntry(entryId: entryId, files: remaining));
    }
    await _saveQueue(queue);
  }

  List<_PendingEntry> _loadQueue() {
    final raw = _prefs.getString(_queueKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => _PendingEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveQueue(List<_PendingEntry> queue) async {
    await _prefs.setString(_queueKey, jsonEncode(queue.map((e) => e.toJson()).toList()));
  }
}
