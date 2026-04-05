enum CircleNotificationType { sos, prayerRequest, announcement }

enum NotificationAction { pray, imHere }

class CircleNotification {
  final String id;
  final CircleNotificationType type;
  final String circleId;
  final String circleName;
  final String senderUid;
  final String senderName;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final NotificationAction? actionTaken;
  final bool suppressActions;

  const CircleNotification({
    required this.id,
    required this.type,
    required this.circleId,
    required this.circleName,
    required this.senderUid,
    required this.senderName,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.actionTaken,
    required this.suppressActions,
  });

  CircleNotification copyWith({bool? isRead, NotificationAction? actionTaken}) =>
      CircleNotification(
        id: id,
        type: type,
        circleId: circleId,
        circleName: circleName,
        senderUid: senderUid,
        senderName: senderName,
        message: message,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        actionTaken: actionTaken ?? this.actionTaken,
        suppressActions: suppressActions,
      );

  static CircleNotificationType _typeFromString(String s) {
    switch (s) {
      case 'sos':
        return CircleNotificationType.sos;
      case 'prayer_request':
        return CircleNotificationType.prayerRequest;
      default:
        return CircleNotificationType.announcement;
    }
  }

  static NotificationAction? _actionFromString(String? s) {
    if (s == 'pray') return NotificationAction.pray;
    if (s == 'im_here') return NotificationAction.imHere;
    return null;
  }

  factory CircleNotification.fromJson(Map<String, dynamic> j) =>
      CircleNotification(
        id: j['id'] as String,
        type: _typeFromString(j['type'] as String),
        circleId: j['circleId'] as String,
        circleName: j['circleName'] as String,
        senderUid: j['senderUid'] as String,
        senderName: j['senderName'] as String,
        message: j['message'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isRead: j['isRead'] as bool? ?? false,
        actionTaken: _actionFromString(j['actionTaken'] as String?),
        suppressActions: j['suppressActions'] as bool? ?? false,
      );
}
