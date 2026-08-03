enum CircleNotificationType { sos, prayerRequest, announcement, partnershipInvite, partnerMessage, partnershipAccepted, event, groupActivity, encouragement, prayerList }

enum NotificationAction { pray, imHere, accept, decline, illBeThere, unableToMakeIt, countMeIn, unableToDo, gotIt, thankYou }

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
  // Only set for partnershipInvite notifications.
  final String? partnerInviteToken;

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
    this.partnerInviteToken,
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
        partnerInviteToken: partnerInviteToken,
      );

  static CircleNotificationType _typeFromString(String s) {
    switch (s) {
      case 'sos':
        return CircleNotificationType.sos;
      case 'prayer_request':
        return CircleNotificationType.prayerRequest;
      case 'partnership_invite':
        return CircleNotificationType.partnershipInvite;
      case 'partner_message':
        return CircleNotificationType.partnerMessage;
      case 'partnership_accepted':
        return CircleNotificationType.partnershipAccepted;
      case 'event':
        return CircleNotificationType.event;
      case 'group_activity':
        return CircleNotificationType.groupActivity;
      case 'encouragement':
        return CircleNotificationType.encouragement;
      case 'prayer_list':
        return CircleNotificationType.prayerList;
      default:
        return CircleNotificationType.announcement;
    }
  }

  static NotificationAction? _actionFromString(String? s) {
    if (s == 'pray') return NotificationAction.pray;
    if (s == 'im_here') return NotificationAction.imHere;
    if (s == 'accept') return NotificationAction.accept;
    if (s == 'decline') return NotificationAction.decline;
    if (s == 'ill_be_there') return NotificationAction.illBeThere;
    if (s == 'unable_to_make_it') return NotificationAction.unableToMakeIt;
    if (s == 'count_me_in') return NotificationAction.countMeIn;
    if (s == 'unable_to_do') return NotificationAction.unableToDo;
    if (s == 'got_it') return NotificationAction.gotIt;
    if (s == 'thank_you') return NotificationAction.thankYou;
    return null;
  }

  factory CircleNotification.fromJson(Map<String, dynamic> j) =>
      CircleNotification(
        id: j['id'] as String,
        type: _typeFromString(j['type'] as String),
        circleId: j['circleId'] as String? ?? '',
        circleName: j['circleName'] as String? ?? '',
        senderUid: j['senderUid'] as String? ?? '',
        senderName: j['senderName'] as String? ?? '',
        message: j['message'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isRead: j['isRead'] as bool? ?? false,
        actionTaken: _actionFromString(j['actionTaken'] as String?),
        suppressActions: j['suppressActions'] as bool? ?? false,
        partnerInviteToken: j['partnerInviteToken'] as String?,
      );
}
