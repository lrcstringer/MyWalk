import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/memorization_item.dart';
import '../../domain/entities/memorization_circle.dart';
import '../../domain/repositories/memorization_repository.dart';

class FirestoreMemorizationRepository implements MemorizationRepository {
  final FirebaseFirestore _db;

  FirestoreMemorizationRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('FirestoreMemorizationRepository: no authenticated user');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _db.collection('users').doc(_uid).collection('memorizations');

  CollectionReference<Map<String, dynamic>> _attemptsRef(String itemId) =>
      _itemsRef.doc(itemId).collection('attempts');

  CollectionReference<Map<String, dynamic>> _sharesRef(String itemId) =>
      _itemsRef.doc(itemId).collection('shares');

  CollectionReference<Map<String, dynamic>> get _circlesRef =>
      _db.collection('memorizationCircles');

  CollectionReference<Map<String, dynamic>> _commentsRef(String circleId) =>
      _circlesRef.doc(circleId).collection('comments');

  // ---------------------------------------------------------------------------
  // MemorizationItem — CRUD + stream
  // ---------------------------------------------------------------------------

  @override
  Stream<List<MemorizationItem>> watchItems() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _itemsRef
        .where('status', whereIn: ['active', 'mastered'])
        .orderBy('nextReviewDate')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MemorizationItem.fromFirestore(d))
            .toList());
  }

  @override
  Future<List<MemorizationItem>> loadItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    final snap = await _itemsRef
        .where('status', whereIn: ['active', 'mastered'])
        .orderBy('nextReviewDate')
        .get();
    return snap.docs.map((d) => MemorizationItem.fromFirestore(d)).toList();
  }

  @override
  Future<void> saveItem(MemorizationItem item) async {
    _itemsRef.doc(item.id).set(item.toFirestore()).ignore();
  }

  @override
  Future<void> updateItem(MemorizationItem item) async {
    _itemsRef.doc(item.id).set(item.toFirestore(), SetOptions(merge: true)).ignore();
  }

  @override
  Future<void> deleteItem(String itemId) async {
    // Firestore batch limit is 500 ops. Chunk deletes into groups of 400 to
    // leave headroom for the shares docs and the root document itself.
    const batchLimit = 400;

    final allDocs = <DocumentReference>[];

    final attempts = await _attemptsRef(itemId).get();
    allDocs.addAll(attempts.docs.map((d) => d.reference));

    final shares = await _sharesRef(itemId).get();
    allDocs.addAll(shares.docs.map((d) => d.reference));

    // Root document — always last so sub-collections are gone before the parent.
    allDocs.add(_itemsRef.doc(itemId));

    for (var i = 0; i < allDocs.length; i += batchLimit) {
      final batch = _db.batch();
      final end = (i + batchLimit).clamp(0, allDocs.length);
      for (final ref in allDocs.sublist(i, end)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  // ---------------------------------------------------------------------------
  // ReviewAttempt
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveAttempt({
    required ReviewAttempt attempt,
    required MemorizationItem updatedItem,
  }) async {
    // Atomic batch: write the attempt sub-document + update parent SM2 state.
    final batch = _db.batch();
    batch.set(_attemptsRef(updatedItem.id).doc(attempt.id), attempt.toFirestore());
    batch.set(_itemsRef.doc(updatedItem.id), updatedItem.toFirestore(), SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Stream<List<ReviewAttempt>> watchAttempts(String itemId) {
    return _attemptsRef(itemId)
        .orderBy('attemptedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReviewAttempt.fromFirestore(d))
            .toList());
  }

  // ---------------------------------------------------------------------------
  // Sharing
  // ---------------------------------------------------------------------------

  @override
  Future<void> shareItem({
    required String itemId,
    required String friendUid,
  }) async {
    await _sharesRef(itemId).doc(friendUid).set({
      'sharedAt': FieldValue.serverTimestamp(),
      'accessLevel': 'read_only',
      // Denormalised fields needed by the watchSharedWithMe() collection group query.
      'sharedWithUid': friendUid,
      'ownerUid': _uid,
      'itemId': itemId,
    });
  }

  @override
  Future<void> unshareItem({
    required String itemId,
    required String friendUid,
  }) async {
    await _sharesRef(itemId).doc(friendUid).delete();
  }

  @override
  Stream<List<MemorizationItem>> watchSharedWithMe() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    // Collection group query across all /shares sub-collections.
    // Requires a single-field index on sharedWithUid (auto-created by Firestore).
    return _db
        .collectionGroup('shares')
        .where('sharedWithUid', isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) async {
      final items = <MemorizationItem>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final ownerUid = data['ownerUid'] as String?;
        final itemId = data['itemId'] as String?;
        if (ownerUid == null || itemId == null) continue;
        final itemDoc = await _db
            .collection('users')
            .doc(ownerUid)
            .collection('memorizations')
            .doc(itemId)
            .get();
        if (itemDoc.exists) {
          items.add(MemorizationItem.fromFirestore(itemDoc));
        }
      }
      return items;
    });
  }

  // ---------------------------------------------------------------------------
  // MemorizationCircles
  // ---------------------------------------------------------------------------

  @override
  Stream<List<MemorizationCircle>> watchCircles() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _circlesRef
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MemorizationCircle.fromFirestore(d))
            .toList());
  }

  @override
  Future<void> saveCircle(MemorizationCircle circle) async {
    await _circlesRef.doc(circle.id).set(circle.toFirestore());
  }

  @override
  Future<void> updateCircle(MemorizationCircle circle) async {
    await _circlesRef
        .doc(circle.id)
        .set(circle.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> updateMemberMastery({
    required String circleId,
    required String uid,
    required double masteryPercent,
  }) async {
    await _circlesRef.doc(circleId).update({'memberMastery.$uid': masteryPercent});
  }

  // ---------------------------------------------------------------------------
  // Circle comments
  // ---------------------------------------------------------------------------

  @override
  Stream<List<CircleComment>> watchCircleComments(String circleId) {
    return _commentsRef(circleId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CircleComment.fromFirestore(d)).toList());
  }

  @override
  Future<void> addCircleComment({
    required String circleId,
    required String text,
  }) async {
    await _commentsRef(circleId).add({
      'authorUid': _uid,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
