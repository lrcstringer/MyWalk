import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/remote/api_service.dart';

/// Queues outbound notification sends when the device is offline and flushes
/// them automatically once connectivity is restored.
///
/// SOS is included — guaranteed eventual delivery is more important than
/// immediate failure. The queue tries to dispatch immediately; if the device
/// is offline the item persists to disk and is retried on next connectivity.
///
/// Each queued item is a JSON map with a 'type' discriminator:
///   sos           : { circleId, message, recipientIds }
///   announcement  : { circleId, message }
///   prayer_request: { circleId, message, recipientIds }
///   encouragement : { circleId, recipientId, messageType, presetKey?, customText?, isAnonymous }
class PendingNotificationSendQueue {
  static const _prefsKey = 'pending_notification_sends';

  final SharedPreferences _prefs;
  final FirebaseFunctions _fn;

  // In-memory list is the single source of truth, initialised once from
  // SharedPreferences on construction. All mutations are applied here first,
  // then persisted. This eliminates the read-modify-write race condition that
  // a naive SharedPreferences-only approach would have.
  final List<Map<String, dynamic>> _queue;

  bool _flushing = false;

  PendingNotificationSendQueue(this._prefs)
      : _fn = FirebaseFunctions.instanceFor(region: 'us-central1'),
        _queue = _loadFromPrefs(_prefs.getString(_prefsKey)) {
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        // Intentionally unawaited — errors are swallowed inside flush().
        flush();
      }
    });
  }

  /// Attempts to send [payload] immediately. Persists to queue on failure.
  Future<void> enqueue(Map<String, dynamic> payload) async {
    try {
      await _dispatch(payload);
    } catch (_) {
      _queue.add(payload);
      await _saveQueue();
    }
  }

  /// Drains the queue, removing each item immediately after it succeeds.
  /// Items that fail are left in place and retried on the next flush.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      // Snapshot so that items added by concurrent enqueue() calls during the
      // flush are not dispatched in this run (they'll be picked up next time).
      final snapshot = List<Map<String, dynamic>>.from(_queue);
      for (final item in snapshot) {
        try {
          await _dispatch(item);
          // Remove the exact same object reference — safe because snapshot
          // elements are the same instances held in _queue.
          _queue.remove(item);
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

  Future<void> _dispatch(Map<String, dynamic> payload) async {
    final type = payload['type'] as String;
    switch (type) {
      case 'sos':
        await APIService.shared.sendSOS(
          payload['circleId'] as String,
          payload['message'] as String,
          List<String>.from(payload['recipientIds'] as List),
        );
      case 'announcement':
        await APIService.shared.sendAnnouncement(
          circleId: payload['circleId'] as String,
          message: payload['message'] as String,
        );
      case 'prayer_request':
        await APIService.shared.sendPrayerRequest(
          circleId: payload['circleId'] as String,
          message: payload['message'] as String,
          recipientIds: List<String>.from(payload['recipientIds'] as List),
        );
      case 'encouragement':
        final params = Map<String, dynamic>.from(payload)..remove('type');
        await _fn.httpsCallable('circleSendEncouragement').call(params);
      default:
        // Throw so the item stays in the queue rather than being silently
        // dropped. An unrecognised type most likely means a version mismatch
        // or a serialisation bug — keeping it is safer than discarding it.
        throw UnsupportedError('Unknown notification send type: $type');
    }
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
