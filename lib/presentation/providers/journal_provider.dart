import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../data/services/local_image_cache_service.dart';
import '../../data/services/local_voice_cache_service.dart';
import '../../data/services/media_upload_service.dart';
import '../../domain/entities/fruit.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';

enum JournalSortOrder { newestFirst, oldestFirst, byHabit, byFruit }

class JournalProvider extends ChangeNotifier {
  final JournalRepository _repository;

  JournalProvider(this._repository) {
    // Register upload-completion callback so the UI reflects finished uploads.
    MediaUploadService.instance.registerEntryUpdatedCallback(refreshEntry);
    AuthService.shared.addListener(_onAuthChanged);
    if (AuthService.shared.isAuthenticated) _subscribeToEntries();
  }

  // Latest 50 entries kept in sync by the Firestore stream.
  List<JournalEntry> _streamedEntries = [];
  // Older entries loaded on demand via loadMore().
  List<JournalEntry> _olderEntries = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String _searchQuery = '';
  JournalSortOrder _sortOrder = JournalSortOrder.newestFirst;

  StreamSubscription<List<JournalEntry>>? _entriesSub;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  JournalSortOrder get sortOrder => _sortOrder;

  // Merged view: live top-50 + older paginated entries (deduplicated).
  List<JournalEntry> get _entries {
    if (_olderEntries.isEmpty) return _streamedEntries;
    final streamedIds = _streamedEntries.map((e) => e.id).toSet();
    return [
      ..._streamedEntries,
      ..._olderEntries.where((e) => !streamedIds.contains(e.id)),
    ];
  }

  @override
  void dispose() {
    _entriesSub?.cancel();
    AuthService.shared.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (AuthService.shared.isAuthenticated) {
      _subscribeToEntries();
    } else {
      _entriesSub?.cancel();
      _entriesSub = null;
      _streamedEntries = [];
      _olderEntries = [];
      _hasMore = false;
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _subscribeToEntries() {
    _entriesSub?.cancel();
    _olderEntries = [];
    _hasMore = false;
    _isLoadingMore = false;
    _isLoading = true;
    notifyListeners();
    _entriesSub = _repository.watchEntries().listen(
      (entries) {
        _streamedEntries = entries;
        // If the stream returned a full page, older entries may exist.
        _hasMore = entries.length >= 50;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// All entries, unfiltered and unsorted. Use for lookups by specific criteria
  /// (e.g. modal views) where the active search query must not hide results.
  List<JournalEntry> get allEntries => List.unmodifiable(_entries);

  /// Returns the entry with [id] from the raw (unfiltered) list, or null.
  JournalEntry? getEntry(String id) =>
      _entries.where((e) => e.id == id).firstOrNull;

  List<JournalEntry> get filteredEntries {
    var result = List<JournalEntry>.from(_entries);

    // Apply search filter.
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) {
        final textMatch = JournalEntry.extractPlainText(e.text).toLowerCase().contains(q);
        final habitMatch = e.habitName?.toLowerCase().contains(q) ?? false;
        final fruitMatch = e.fruitTag?.label.toLowerCase().contains(q) ?? false;
        return textMatch || habitMatch || fruitMatch;
      }).toList();
    }

    // Apply sort — all multi-key sorts use createdAt descending as stable tiebreaker.
    switch (_sortOrder) {
      case JournalSortOrder.newestFirst:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case JournalSortOrder.oldestFirst:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case JournalSortOrder.byHabit:
        result.sort((a, b) {
          final primary = (a.habitName ?? '').compareTo(b.habitName ?? '');
          return primary != 0 ? primary : b.createdAt.compareTo(a.createdAt);
        });
      case JournalSortOrder.byFruit:
        result.sort((a, b) {
          final primary =
              (a.fruitTag?.label ?? '').compareTo(b.fruitTag?.label ?? '');
          return primary != 0 ? primary : b.createdAt.compareTo(a.createdAt);
        });
    }

    // Float pinned entries to the top, preserving the selected sort within each group.
    final pinned = result.where((e) => e.pinned).toList();
    final unpinned = result.where((e) => !e.pinned).toList();
    return [...pinned, ...unpinned];
  }

  /// Save a new journal entry.
  ///
  /// Media files ([imageLocalPaths], [voiceLocalPath]) are copied to a stable
  /// app-documents directory and queued for upload via [MediaUploadService].
  Future<void> saveEntry({
    String? text,
    List<String> imageLocalPaths = const [],
    String? voiceLocalPath,
    String? habitId,
    String? habitName,
    FruitType? fruitTag,
    required String sourceType,
  }) async {
    final hasPendingMedia = imageLocalPaths.isNotEmpty || voiceLocalPath != null;

    final entry = JournalEntry.create(
      text: text,
      imageUrls: const [],
      voiceUrl: null,
      uploadPending: hasPendingMedia,
      habitId: habitId,
      habitName: habitName,
      fruitTag: fruitTag,
      sourceType: sourceType,
    );

    // Copy media to stable local paths before saving.
    final pendingFiles = await _stageMediaFiles(entry.id, imageLocalPaths, voiceLocalPath);

    // Fire-and-forget: Firestore queues offline; stream reflects update automatically.
    _repository.saveEntry(entry).ignore();

    if (pendingFiles.isNotEmpty) {
      await MediaUploadService.instance.enqueueUploads(entry.id, pendingFiles);
    }
  }

  /// Update an existing journal entry's text and/or add/remove media.
  ///
  /// Pass [clearText] = true to explicitly set the text field to null (empty).
  /// If [text] is null and [clearText] is false, the existing text is preserved.
  Future<void> updateEntry(
    JournalEntry entry, {
    String? text,
    bool clearText = false,
    List<String> newImageLocalPaths = const [],
    String? newVoiceLocalPath,
    List<String>? removedImageUrls,
    bool? removeVoice,
  }) async {
    final hasPendingMedia = newImageLocalPaths.isNotEmpty || newVoiceLocalPath != null;

    // Delete removed media from Storage (fire-and-forget).
    if (removedImageUrls != null) {
      for (final url in removedImageUrls) {
        _repository.deleteMedia(url).ignore();
      }
    }
    if (removeVoice == true && entry.voiceUrl != null) {
      _repository.deleteMedia(entry.voiceUrl!).ignore();
    }

    final updatedImageUrls = removedImageUrls != null
        ? entry.imageUrls.where((u) => !removedImageUrls.contains(u)).toList()
        : entry.imageUrls;

    // Build updated entry directly to support explicit text clearing.
    // JournalEntry.copyWith cannot set text to null (no sentinel), so we
    // construct the entry here when clearText is needed.
    final resolvedText = clearText ? null : (text ?? entry.text);
    final updated = JournalEntry(
      id: entry.id,
      createdAt: entry.createdAt,
      updatedAt: DateTime.now(),
      text: resolvedText,
      imageUrls: updatedImageUrls,
      voiceUrl: removeVoice == true ? null : entry.voiceUrl,
      uploadPending: hasPendingMedia,
      habitId: entry.habitId,
      habitName: entry.habitName,
      fruitTag: entry.fruitTag,
      sourceType: entry.sourceType,
      pinned: entry.pinned,
    );

    final pendingFiles =
        await _stageMediaFiles(entry.id, newImageLocalPaths, newVoiceLocalPath);

    // Fire-and-forget: stream reflects update automatically for entries in the
    // top-50 window. For older (paginated) entries, update the local list directly.
    _repository.updateEntry(updated).ignore();
    final olderIdx = _olderEntries.indexWhere((e) => e.id == entry.id);
    if (olderIdx != -1) {
      _olderEntries[olderIdx] = updated;
      notifyListeners();
    }

    if (pendingFiles.isNotEmpty) {
      await MediaUploadService.instance.enqueueUploads(entry.id, pendingFiles);
    }
  }

  /// Delete every journal entry owned by the current user, including all media.
  Future<void> deleteAllEntries() async {
    final all = List<JournalEntry>.from(_entries);
    await Future.wait(all.map(deleteEntry));
  }

  /// Delete a journal entry and all its Storage media.
  Future<void> deleteEntry(JournalEntry entry) async {
    // Cancel any in-flight upload for this entry. This deletes the staged
    // local files and removes the queue entry, preventing orphaned Storage
    // objects when the entry is deleted before its upload completes.
    await MediaUploadService.instance.cancelEntry(entry.id);

    // Delete already-uploaded Storage media (fire-and-forget).
    for (final url in entry.imageUrls) {
      _repository.deleteMedia(url).ignore();
    }
    if (entry.voiceUrl != null) {
      _repository.deleteMedia(entry.voiceUrl!).ignore();
    }

    LocalVoiceCacheService.instance.removePath(entry.id).ignore();

    // Delete cached local image files and remove from index.
    final localImagePaths = LocalImageCacheService.instance
        .getPaths(entry.id, entry.imageUrls.length);
    for (final path in localImagePaths) {
      if (path != null) try { File(path).deleteSync(); } catch (_) {}
    }
    LocalImageCacheService.instance.removePaths(entry.id).ignore();

    // Remove from older entries list immediately (stream handles the streamed window).
    _olderEntries.removeWhere((e) => e.id == entry.id);

    // Fire-and-forget: stream reflects deletion automatically.
    _repository.deleteEntry(entry.id).ignore();
  }

  /// Fetch the next page of older entries and append them to [_olderEntries].
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final oldest = _entries.lastOrNull;
    if (oldest == null) return;

    _isLoadingMore = true;
    notifyListeners();
    try {
      const pageSize = 50;
      final page = await _repository.loadEntriesBefore(
        oldest.createdAt,
        limit: pageSize,
      );
      if (page.isEmpty) {
        _hasMore = false;
      } else {
        final knownIds = _entries.map((e) => e.id).toSet();
        final fresh = page.where((e) => !knownIds.contains(e.id)).toList();
        _olderEntries = [..._olderEntries, ...fresh];
        _hasMore = page.length >= pageSize;
      }
    } catch (_) {
      // Network error — leave _hasMore unchanged so user can retry by scrolling.
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> togglePin(JournalEntry entry) async {
    final updated = entry.copyWith(pinned: !entry.pinned);
    _repository.updateEntry(updated).ignore();
  }

  void setSortOrder(JournalSortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  /// Called by [MediaUploadService] after successful uploads.
  /// The stream subscription reflects server-side changes automatically.
  Future<void> refreshEntry(String entryId) async {}

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Copies media files to a stable app-documents subdirectory so the paths
  /// survive across sessions. Returns the list of [PendingMediaFile] items.
  Future<List<PendingMediaFile>> _stageMediaFiles(
    String entryId,
    List<String> imageLocalPaths,
    String? voiceLocalPath,
  ) async {
    if (imageLocalPaths.isEmpty && voiceLocalPath == null) return [];

    final appDir = await getApplicationDocumentsDirectory();
    final entryDir = Directory('${appDir.path}/journal/$entryId');
    await entryDir.create(recursive: true);

    final pending = <PendingMediaFile>[];

    for (var i = 0; i < imageLocalPaths.length; i++) {
      final src = File(imageLocalPaths[i]);
      if (!src.existsSync()) continue;
      final dest = '${entryDir.path}/image_$i.jpg';
      await src.copy(dest);
      pending.add(PendingMediaFile(type: 'image', localPath: dest, index: i));
    }

    if (voiceLocalPath != null) {
      final src = File(voiceLocalPath);
      if (src.existsSync()) {
        final dest = '${entryDir.path}/voice.m4a';
        await src.copy(dest);
        pending.add(PendingMediaFile(type: 'voice', localPath: dest, index: -1));
      }
    }

    return pending;
  }
}
