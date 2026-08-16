import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/memorization_item.dart';
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

  // Kept private — used only in deleteItem to clean up legacy share docs.
  CollectionReference<Map<String, dynamic>> _sharesRef(String itemId) =>
      _itemsRef.doc(itemId).collection('shares');

  // ---------------------------------------------------------------------------
  // MemorizationItem — CRUD + stream
  // ---------------------------------------------------------------------------

  @override
  Stream<List<MemorizationItem>> watchItems() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _itemsRef
        .where('status', whereIn: ['active', 'mastered'])
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((d) => MemorizationItem.fromFirestore(d))
              .toList();
          items.sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
          return items;
        });
  }

  @override
  Future<List<MemorizationItem>> loadItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    final snap = await _itemsRef
        .where('status', whereIn: ['active', 'mastered'])
        .get();
    final items = snap.docs
        .map((d) => MemorizationItem.fromFirestore(d))
        .toList();
    items.sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
    return items;
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

    // Clean up any legacy share sub-docs.
    final shares = await _sharesRef(itemId).get();
    allDocs.addAll(shares.docs.map((d) => d.reference));

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
}
