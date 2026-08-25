import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ApplyReferralResult {
  success,
  invalidCode,
  selfReferral,
  alreadyApplied,
  networkError,
}

class ReferralData {
  final String? code;
  final int confirmedCount;
  final bool tier1Granted;
  final bool tier2Granted;

  const ReferralData({
    required this.code,
    required this.confirmedCount,
    required this.tier1Granted,
    required this.tier2Granted,
  });
}

class ReferralService {
  static final ReferralService shared = ReferralService._();
  ReferralService._();

  final _fn = FirebaseFunctions.instanceFor(region: 'us-central1');
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<ApplyReferralResult> applyReferralCode(String code) async {
    try {
      final callable = _fn.httpsCallable('applyReferralCode');
      await callable.call<Map<String, dynamic>>({'code': code.trim().toUpperCase()});
      return ApplyReferralResult.success;
    } on FirebaseFunctionsException catch (e) {
      return switch (e.message) {
        'invalid-code'              => ApplyReferralResult.invalidCode,
        'cannot-self-refer'         => ApplyReferralResult.selfReferral,
        'referral-already-applied'  => ApplyReferralResult.alreadyApplied,
        _                           => ApplyReferralResult.networkError,
      };
    } catch (_) {
      return ApplyReferralResult.networkError;
    }
  }

  Future<String?> generateReferralCode() async {
    try {
      final callable = _fn.httpsCallable('generateReferralCode');
      final result = await callable.call<Map<String, dynamic>>({});
      return result.data['code'] as String?;
    } catch (_) {
      return null;
    }
  }

  Stream<ReferralData> watchReferralData() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) {
        return const ReferralData(
          code: null,
          confirmedCount: 0,
          tier1Granted: false,
          tier2Granted: false,
        );
      }
      final data = snap.data()!;
      final rewards = (data['referralRewards'] as Map<String, dynamic>?) ?? {};
      return ReferralData(
        code: data['referralCode'] as String?,
        confirmedCount: (data['referralCount'] as int?) ?? 0,
        tier1Granted: (rewards['tier1Granted'] as bool?) ?? false,
        tier2Granted: (rewards['tier2Granted'] as bool?) ?? false,
      );
    });
  }
}
