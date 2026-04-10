import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/accountability_partnership.dart';
import '../../domain/entities/partner_message.dart';
import '../../domain/repositories/accountability_repository.dart';

class FirestoreAccountabilityRepository implements AccountabilityRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _fn;

  FirestoreAccountabilityRepository()
      : _db = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance,
        _fn = FirebaseFunctions.instanceFor(region: 'us-central1');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    return user.uid;
  }

  // ── Collection references ──────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _partnerships =>
      _db.collection('accountability_partnerships');

  CollectionReference<Map<String, dynamic>> _messages(String partnershipId) =>
      _partnerships.doc(partnershipId).collection('partner_messages');

  // ── Callable helper ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _call(
      String name, Map<String, dynamic> data) async {
    final result =
        await _fn.httpsCallable(name).call<Map<Object?, Object?>>(data);
    return Map<String, dynamic>.from(result.data);
  }

  // ── AccountabilityRepository ───────────────────────────────────────────────

  @override
  Future<InviteResult> createInvite({
    required String habitId,
    required String habitName,
    required String ownerDisplayName,
    String? recipientEmail,
  }) async {
    final result = await _call('accountabilityCreateInvite', {
      'habitId': habitId,
      'habitName': habitName,
      'ownerDisplayName': ownerDisplayName,
      'recipientEmail': recipientEmail,
    });
    return InviteResult(
      shareUrl: result['shareUrl'] as String,
      shortCode: result['shortCode'] as String,
      inAppSent: result['inAppSent'] as bool? ?? false,
    );
  }

  @override
  Future<AccountabilityPartnership> acceptViaToken({
    required String token,
    required String partnerDisplayName,
  }) async {
    final result = await _call('accountabilityAcceptInvite', {
      'token': token,
      'partnerDisplayName': partnerDisplayName,
    });
    final partnershipId = result['partnershipId'] as String;
    final snap = await _partnerships
        .doc(partnershipId)
        .withConverter<AccountabilityPartnership>(
          fromFirestore: (s, _) =>
              AccountabilityPartnership.fromFirestore(s),
          toFirestore: (p, _) => p.toFirestore(),
        )
        .get();
    return snap.data()!;
  }

  @override
  Future<void> declineViaToken(String token) async {
    await _call('accountabilityDeclineInvite', {'token': token});
  }

  @override
  Future<void> cancelPartnership(String partnershipId) async {
    await _partnerships.doc(partnershipId).update({'status': 'cancelled'});
  }

  @override
  Future<void> endPartnership(String partnershipId) async {
    await _partnerships.doc(partnershipId).update({'status': 'ended'});
  }

  @override
  Future<void> sendMessage({
    required String partnershipId,
    required String body,
    required String senderDisplayName,
  }) async {
    final uid = _uid;
    final now = FieldValue.serverTimestamp();
    final msgRef = _messages(partnershipId).doc();
    final batch = _db.batch();
    batch.set(msgRef, {
      'partnershipId': partnershipId,
      'senderId': uid,
      'senderDisplayName': senderDisplayName,
      'body': body,
      'sentAt': now,
      'isRead': false,
    });
    batch.update(_partnerships.doc(partnershipId), {
      'lastMessagePreview': body.length > 80 ? '${body.substring(0, 80)}…' : body,
      'lastMessageAt': now,
    });
    await batch.commit();

    // Notify the other participant via Cloud Function (best-effort).
    _call('accountabilityNotifyParticipant', {
      'partnershipId': partnershipId,
      'messagePreview': body.length > 80 ? '${body.substring(0, 80)}…' : body,
    }).catchError((_) => <String, dynamic>{});
  }

  @override
  Future<void> markMessagesRead(String partnershipId) async {
    final uid = _uid;
    final unread = await _messages(partnershipId)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: uid)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Stream<List<AccountabilityPartnership>> watchPartnershipsForUser() {
    final uid = _uid;
    return _partnerships
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AccountabilityPartnership.fromFirestore(d))
            .toList());
  }

  @override
  Stream<List<PartnerMessage>> watchMessages(String partnershipId) {
    return _messages(partnershipId)
        .orderBy('sentAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PartnerMessage.fromFirestore(d)).toList());
  }

  @override
  Future<AccountabilityPartnership?> findByToken(String token) async {
    try {
      final snap = await _partnerships
          .where('inviteToken', isEqualTo: token)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return AccountabilityPartnership.fromFirestore(snap.docs.first);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> endPartnershipsForHabit(String habitId, {String reason = 'deleted'}) async {
    await _call('accountabilityEndForHabit', {'habitId': habitId, 'reason': reason});
  }

  @override
  Future<AccountabilityPartnership?> findByShortCode(String code) async {
    try {
      final snap = await _partnerships
          .where('shortCode', isEqualTo: code.toUpperCase())
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return AccountabilityPartnership.fromFirestore(snap.docs.first);
    } catch (_) {
      return null;
    }
  }
}
