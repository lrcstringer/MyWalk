import '../entities/circle_notification.dart';

abstract class NotificationRepository {
  /// Real-time stream of the caller's inbox (newest first).
  Stream<List<CircleNotification>> watchInbox();

  /// Fetch current inbox once.
  Future<List<CircleNotification>> getInbox({int limit, bool onlyUnread});

  /// Unread count (for badge).
  Future<int> getUnreadCount();

  /// Mark a single notification as read.
  Future<void> markRead(String notifId);

  /// Record an action against a notification.
  Future<void> recordAction(String notifId, NotificationAction action);

  /// Send a circle announcement (admin only).
  Future<void> sendAnnouncement({
    required String circleId,
    required String message,
  });

  /// Send a help / prayer request to chosen recipients.
  Future<void> sendPrayerRequest({
    required String circleId,
    required String message,
    required List<String> recipientIds,
  });
}
