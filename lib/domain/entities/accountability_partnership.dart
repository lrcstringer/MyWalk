import 'package:cloud_firestore/cloud_firestore.dart';

enum PartnershipStatus {
  pending,
  active,
  declined,
  cancelled,
  ended;

  static PartnershipStatus fromString(String? value) {
    switch (value) {
      case 'active':
        return PartnershipStatus.active;
      case 'declined':
        return PartnershipStatus.declined;
      case 'cancelled':
        return PartnershipStatus.cancelled;
      case 'ended':
        return PartnershipStatus.ended;
      default:
        return PartnershipStatus.pending;
    }
  }

  String get value => name;
}

class AccountabilityPartnership {
  final String id;

  /// The user who created the invite (owns the habit).
  final String ownerId;
  final String ownerDisplayName;

  /// The user who accepted the invite (null until accepted).
  final String? partnerId;
  final String? partnerDisplayName;

  final String habitId;
  final String habitName;

  final PartnershipStatus status;

  /// UUID token used in the share link: /accountability/accept/:inviteToken
  final String inviteToken;

  /// Denormalized for Firestore `arrayContains` rules — contains ownerId and
  /// partnerId (once accepted). Used instead of per-read `get()` calls.
  final List<String> participantIds;

  final DateTime createdAt;
  final DateTime? acceptedAt;

  final String? lastMessagePreview;
  final DateTime? lastMessageAt;

  const AccountabilityPartnership({
    required this.id,
    required this.ownerId,
    required this.ownerDisplayName,
    this.partnerId,
    this.partnerDisplayName,
    required this.habitId,
    required this.habitName,
    required this.status,
    required this.inviteToken,
    required this.participantIds,
    required this.createdAt,
    this.acceptedAt,
    this.lastMessagePreview,
    this.lastMessageAt,
  });

  factory AccountabilityPartnership.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AccountabilityPartnership(
      id: doc.id,
      ownerId: d['ownerId'] as String,
      ownerDisplayName: d['ownerDisplayName'] as String? ?? '',
      partnerId: d['partnerId'] as String?,
      partnerDisplayName: d['partnerDisplayName'] as String?,
      habitId: d['habitId'] as String,
      habitName: d['habitName'] as String? ?? '',
      status: PartnershipStatus.fromString(d['status'] as String?),
      inviteToken: d['inviteToken'] as String? ?? '',
      participantIds: List<String>.from(d['participantIds'] as List? ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (d['acceptedAt'] as Timestamp?)?.toDate(),
      lastMessagePreview: d['lastMessagePreview'] as String?,
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ownerId': ownerId,
        'ownerDisplayName': ownerDisplayName,
        if (partnerId != null) 'partnerId': partnerId,
        if (partnerDisplayName != null) 'partnerDisplayName': partnerDisplayName,
        'habitId': habitId,
        'habitName': habitName,
        'status': status.value,
        'inviteToken': inviteToken,
        'participantIds': participantIds,
        'createdAt': Timestamp.fromDate(createdAt),
        if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
        if (lastMessagePreview != null) 'lastMessagePreview': lastMessagePreview,
        if (lastMessageAt != null) 'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
      };

  AccountabilityPartnership copyWith({
    String? partnerId,
    String? partnerDisplayName,
    PartnershipStatus? status,
    List<String>? participantIds,
    DateTime? acceptedAt,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
  }) =>
      AccountabilityPartnership(
        id: id,
        ownerId: ownerId,
        ownerDisplayName: ownerDisplayName,
        partnerId: partnerId ?? this.partnerId,
        partnerDisplayName: partnerDisplayName ?? this.partnerDisplayName,
        habitId: habitId,
        habitName: habitName,
        status: status ?? this.status,
        inviteToken: inviteToken,
        participantIds: participantIds ?? this.participantIds,
        createdAt: createdAt,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      );
}
