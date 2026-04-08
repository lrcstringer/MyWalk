import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerMessage {
  final String id;
  final String partnershipId;
  final String senderId;
  final String senderDisplayName;
  final String body;
  final DateTime sentAt;
  final bool isRead;

  const PartnerMessage({
    required this.id,
    required this.partnershipId,
    required this.senderId,
    required this.senderDisplayName,
    required this.body,
    required this.sentAt,
    required this.isRead,
  });

  factory PartnerMessage.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PartnerMessage(
      id: doc.id,
      partnershipId: d['partnershipId'] as String,
      senderId: d['senderId'] as String,
      senderDisplayName: d['senderDisplayName'] as String? ?? '',
      body: d['body'] as String? ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: d['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'partnershipId': partnershipId,
        'senderId': senderId,
        'senderDisplayName': senderDisplayName,
        'body': body,
        'sentAt': Timestamp.fromDate(sentAt),
        'isRead': isRead,
      };
}
