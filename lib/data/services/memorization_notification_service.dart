import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/entities/memorization_item.dart';

// Schedules a local notification when a memorization item is due for review.
// Uses flutter_local_notifications (already installed in the app).

class MemorizationNotificationService {
  static final MemorizationNotificationService instance =
      MemorizationNotificationService._();
  MemorizationNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initFuture; // serialises concurrent initialize() calls

  static const _channelId = 'memorization_reviews';
  static const _channelName = 'Scripture Review Reminders';

  final _functions = FirebaseFunctions.instance;

  Future<void> initialize() {
    if (_initialized) return Future.value();
    // Concurrent callers all await the same future — prevents double-init.
    _initFuture ??= _doInitialize();
    return _initFuture!;
  }

  Future<void> _doInitialize() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    _initialized = true;
  }

  /// Schedules both a local notification and an FCM push for [item.nextReviewDate].
  /// Cancels any existing notification for this item first.
  Future<void> scheduleReviewReminder(MemorizationItem item) async {
    await initialize();
    await cancelReminder(item.id);

    final now = DateTime.now();
    if (item.nextReviewDate.isBefore(now)) return;

    // Local notification (fires even when server is unreachable).
    final notificationId = _idFromItemId(item.id);
    await _plugin.zonedSchedule(
      notificationId,
      'Time to review: ${item.title}',
      '"Thy word have I hid in mine heart…" — Psalm 119:11',
      _toTZDateTime(item.nextReviewDate),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // FCM push via Cloud Function (fires when app is closed / on other devices).
    _functions
        .httpsCallable('scheduleReviewReminder')
        .call<dynamic>({
          'itemId': item.id,
          'itemTitle': item.title,
          'dueAt': item.nextReviewDate.toIso8601String(),
        })
        .ignore();
  }

  Future<void> cancelReminder(String itemId) async {
    await initialize();
    await _plugin.cancel(_idFromItemId(itemId));

    _functions
        .httpsCallable('cancelReviewReminder')
        .call<dynamic>({'itemId': itemId})
        .ignore();
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  // Derive a stable int ID from the item UUID (first 8 hex chars → int).
  int _idFromItemId(String itemId) {
    final hex = itemId.replaceAll('-', '').substring(0, 8);
    return int.parse(hex, radix: 16).abs() % 0x7FFFFFFF;
  }

  tz.TZDateTime _toTZDateTime(DateTime dt) {
    return tz.TZDateTime.from(dt, tz.local);
  }
}
