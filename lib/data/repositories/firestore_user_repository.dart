import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _db;

  FirestoreUserRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  @override
  Future<UserProfile?> getProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final snap = await _userDoc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromFirestore(uid, snap.data()!);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final uid = _uid;
    if (uid == null) return;
    await _userDoc(uid).set(profile.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> updateFields(Map<String, Object?> fields) async {
    final uid = _uid;
    if (uid == null) return;
    await _userDoc(uid).set(fields, SetOptions(merge: true));
  }

  @override
  Future<bool> isPremium() async {
    final uid = _uid;
    if (uid == null) return false;
    final snap = await _userDoc(uid).collection('subscription').doc('status').get();
    if (!snap.exists || snap.data() == null) return false;
    final data = snap.data()!;
    final status = data['status'] as String?;
    if (status != 'active') return false;
    // lifetime subscriptions have no expiry
    final expiresAt = data['expiresAt'];
    if (expiresAt == null) return true;
    final expiry = expiresAt is Timestamp ? expiresAt.toDate() : null;
    return expiry != null && expiry.isAfter(DateTime.now());
  }
}
