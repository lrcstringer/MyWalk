import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/iap_repository.dart';

/// Firestore + Firebase Functions implementation of [IAPRepository].
///
/// Clean Architecture: this class lives in the data layer.
/// All Firebase dependencies are injected via the constructor so this class
/// is fully testable.
///
/// [getUid] is a callback that returns the current user's Firebase UID, or
/// null when the user is not authenticated. Injecting a callback (rather than
/// the full [FirebaseAuth] instance) keeps the repository decoupled from the
/// auth SDK and avoids the sealed-class constraint in tests.
class FirestoreIAPRepository implements IAPRepository {
  final FirebaseFirestore _db;
  final String? Function() _getUid;
  final FirebaseFunctions _fn;

  FirestoreIAPRepository({
    FirebaseFirestore? db,
    String? Function()? getUid,
    FirebaseFunctions? fn,
  })  : _db = db ?? FirebaseFirestore.instance,
        _getUid = getUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
        _fn = fn ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  // ── IAPRepository ─────────────────────────────────────────────────────────

  /// Reads `users/{uid}/subscription/status` from Firestore.
  ///
  /// Returns:
  ///   `false` — unauthenticated, document absent, or status ≠ 'active'.
  ///   `true`  — status == 'active' AND (lifetime OR expiry is in the future).
  ///   `null`  — transient network/Firestore error; caller leaves state unchanged.
  @override
  Future<bool?> getPremiumStatus() async {
    final uid = _getUid();
    if (uid == null) return false;

    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('subscription')
          .doc('status')
          .get();

      if (!snap.exists) return false;

      final data = snap.data();
      if (data == null) return false;

      final status = data['status'] as String?;
      if (status != 'active') return false;

      // Lifetime purchase: expiresAt is null — never expires.
      final expiresAt = data['expiresAt'];
      if (expiresAt == null) return true;

      // Subscription: check expiry timestamp.
      final expiry = expiresAt is Timestamp ? expiresAt.toDate() : null;
      if (expiry == null) return false;
      return expiry.isAfter(DateTime.now());
    } catch (_) {
      // Network error — signal caller to leave current state unchanged.
      return null;
    }
  }

  /// Calls the `validateReceipt` Firebase callable function.
  ///
  /// Throws [StateError] if the user is not authenticated.
  /// Throws [FirebaseFunctionsException] if the callable function fails.
  @override
  Future<bool> validateReceipt({
    required String platform,
    required String productId,
    String? purchaseToken,
    String? receiptData,
  }) async {
    final uid = _getUid();
    if (uid == null) throw StateError('validateReceipt called while unauthenticated');

    assert(
      (platform == 'android' && purchaseToken != null) ||
          (platform == 'ios' && receiptData != null),
      'android requires purchaseToken; ios requires receiptData',
    );

    final payload = <String, dynamic>{
      'platform': platform,
      'productId': productId,
    };
    if (purchaseToken != null) payload['purchaseToken'] = purchaseToken;
    if (receiptData != null) payload['receiptData'] = receiptData;

    final callable = _fn.httpsCallable('validateReceipt');
    final result = await callable.call<Map<String, dynamic>>(payload);
    return result.data['isPremium'] as bool? ?? false;
  }
}
