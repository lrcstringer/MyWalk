import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/remote/api_service.dart';

/// Queues notification actions (pray / im_here) when the network call fails
/// and flushes them automatically once connectivity is restored.
class PendingActionQueueService {
  static const _prefsKey = 'pending_notification_actions';

  final SharedPreferences _prefs;

  // Guards against concurrent flush() invocations (Dart single-threaded,
  // but async suspension points allow re-entry from the connectivity listener).
  bool _flushing = false;

  PendingActionQueueService(this._prefs) {
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        flush();
      }
    });
  }

  /// Tries to send [action] for [notifId] immediately. If the call fails,
  /// persists it to the queue for retry on next connectivity restored event.
  Future<void> enqueue(String notifId, String action) async {
    try {
      await APIService.shared.recordNotificationAction(notifId, action);
      // Success — nothing to queue.
    } catch (_) {
      await _persist(notifId, action);
    }
  }

  /// Drains all queued actions, removing each one that succeeds.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final raw = _prefs.getString(_prefsKey);
      if (raw == null) return;

      final list = List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).cast<Map<String, dynamic>>());
      if (list.isEmpty) return;

      final remaining = <Map<String, dynamic>>[];
      for (final item in list) {
        try {
          await APIService.shared.recordNotificationAction(
            item['notifId'] as String,
            item['action'] as String,
          );
        } catch (_) {
          remaining.add(item);
        }
      }

      if (remaining.isEmpty) {
        await _prefs.remove(_prefsKey);
      } else {
        await _prefs.setString(_prefsKey, jsonEncode(remaining));
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _persist(String notifId, String action) async {
    final raw = _prefs.getString(_prefsKey);
    final list = raw != null
        ? List<Map<String, dynamic>>.from(
            (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
        : <Map<String, dynamic>>[];
    // Deduplicate: keep only latest action per notifId.
    list.removeWhere((e) => e['notifId'] == notifId);
    list.add({'notifId': notifId, 'action': action});
    await _prefs.setString(_prefsKey, jsonEncode(list));
  }
}
