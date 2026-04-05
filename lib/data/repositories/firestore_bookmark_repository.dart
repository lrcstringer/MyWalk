import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/bible_entities.dart';
import '../../domain/repositories/bookmark_repository.dart';

/// Firestore-backed implementation of [BookmarkRepository].
///
/// Path: users/{uid}/bookmarks/{bookNum}_{chapter}_{verseNum}
class FirestoreBookmarkRepository implements BookmarkRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirestoreBookmarkRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('bookmarks');
  }

  @override
  Future<List<BibleBookmark>> getBookmarks() async {
    final col = _collection;
    if (col == null) return [];
    try {
      final snap = await col.orderBy('savedAt', descending: true).get();
      return snap.docs
          .map((d) => _fromFirestore(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addBookmark(BibleBookmark bookmark) async {
    final col = _collection;
    if (col == null) return;
    await col.doc(bookmark.id).set(_toFirestore(bookmark));
  }

  @override
  Future<void> removeBookmark(String id) async {
    final col = _collection;
    if (col == null) return;
    await col.doc(id).delete();
  }

  @override
  Stream<List<BibleBookmark>> watchBookmarks() {
    final col = _collection;
    if (col == null) return const Stream.empty();
    return col
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _fromFirestore(d.data()))
            .toList())
        .handleError((Object _) {});
  }

  // ── Serialization (kept in the data layer, not the domain entity) ────────────

  static Map<String, dynamic> _toFirestore(BibleBookmark b) => {
        'bookNum': b.bookNum,
        'chapter': b.chapter,
        'verseNum': b.verseNum,
        'bookName': b.bookName,
        'text': b.text,
        'savedAt': b.savedAt.toIso8601String(),
      };

  static BibleBookmark _fromFirestore(Map<String, dynamic> data) =>
      BibleBookmark(
        bookNum: data['bookNum'] as int,
        chapter: data['chapter'] as int,
        verseNum: data['verseNum'] as int,
        bookName: data['bookName'] as String,
        text: data['text'] as String,
        savedAt: DateTime.parse(data['savedAt'] as String),
      );
}
