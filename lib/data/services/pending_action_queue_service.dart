import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/remote/api_service.dart';

/// Queues notification actions (pray / im_here) when the network call fails
/// and flushes them automatically once connectivity is restored.
///
/// [_queue] is the single source of truth, loaded once from SharedPreferences
/// in the constructor and mutated synchronously before each async persist.
/// This eliminates the read-modify-write race that a SharedPreferences-only
/// approach has between concurrent [_persist] and [flush] calls.
class PendingActionQueueService {
  static const _prefsKey = 'pending_notification_actions';

  final SharedPreferences _prefs;

  // In-memory queue is the authoritative state. All mutations happen here
  // first (synchronously), then the new state is persisted asynchronously.
  final List<Map<String, dynamic>> _queue;

  // Guards against concurrent flush() invocations (Dart is single-threaded,
  // but async suspension points allow re-entry from the connectivity listener).
  bool _flushing = false;

  PendingActionQueueService(this._prefs)
      : _queue = _loadFromPrefs(_prefs.getString(_prefsKey)) {
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        flush();
      }
    });
  }

  /// Tries to send [action] for [notifId] immediately. If the call fails,
  /// adds it to the in-memory queue and persists it for retry on the next
  /// connectivity-restored event.
  Future<void> enqueue(String notifId, String action) async {
    try {
      await APIService.shared.recordNotificationAction(notifId, action);
      // Success — nothing to queue.
    } catch (_) {
      _addOrReplace(notifId, action);   // synchronous mutation
      await _saveQueue();
    }
  }

  /// Drains all queued actions, removing each one that succeeds.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      if (_queue.isEmpty) return;

      // Snapshot so that items added by concurrent enqueue() calls during the
      // flush are not dispatched in this run (they will be picked up next time).
      final snapshot = List<Map<String, dynamic>>.from(_queue);
      for (final item in snapshot) {
        try {
          await APIService.shared.recordNotificationAction(
            item['notifId'] as String,
            item['action'] as String,
          );
          // Remove the exact same object reference — safe because snapshot
          // elements are the same instances held in _queue.
          _queue.remove(item);          // synchronous mutation
          // Persist after each success so a mid-flush app kill does not cause
          // duplicate sends on the next launch.
          await _saveQueue();
        } catch (_) {
          // Leave item in queue for next retry.
        }
      }
    } finally {
      _flushing = false;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Deduplicate: keep only the latest action per notifId.
  void _addOrReplace(String notifId, String action) {
    _queue.removeWhere((e) => e['notifId'] == notifId);
    _queue.add({'notifId': notifId, 'action': action});
  }

  Future<void> _saveQueue() async {
    if (_queue.isEmpty) {
      await _prefs.remove(_prefsKey);
    } else {
      await _prefs.setString(_prefsKey, jsonEncode(_queue));
    }
  }

  static List<Map<String, dynamic>> _loadFromPrefs(String? raw) {
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).cast<Map<String, dynamic>>());
    } catch (_) {
      // Corrupt data — start with an empty queue rather than crashing.
      return [];
    }
  }
}
