import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/recovery_path.dart';
import '../../domain/entities/recovery_session.dart';
import '../../domain/repositories/recovery_path_repository.dart';
import '../services/encryption_service.dart';

class FirestoreRecoveryPathRepository implements RecoveryPathRepository {
  final FirebaseFirestore _db;
  final EncryptionService _enc;

  FirestoreRecoveryPathRepository({
    FirebaseFirestore? db,
    EncryptionService? enc,
  })  : _db = db ?? FirebaseFirestore.instance,
        _enc = enc ?? EncryptionService();

  CollectionReference<Map<String, dynamic>> get _paths =>
      _db.collection('recovery_paths');

  CollectionReference<Map<String, dynamic>> _sessions(String habitId) =>
      _paths.doc(habitId).collection('recovery_sessions');

  @override
  Future<RecoveryPath?> getPath(String habitId) async {
    final doc = await _paths.doc(habitId).get();
    if (!doc.exists) return null;
    return RecoveryPath.fromFirestore(doc);
  }

  @override
  Future<RecoveryPath> startPath({
    required String habitId,
    required String userId,
  }) async {
    final now = DateTime.now();
    // Initialize lastCheckInAt to epoch so scheduled CF reminder queries
    // (where 'module1.lastCheckInAt' < today) catch brand-new paths immediately.
    final path = RecoveryPath(
      id: habitId,
      userId: userId,
      habitId: habitId,
      startedAt: now,
      module1: RecoveryModule1State(
        lastCheckInAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    final data = path.toFirestore();
    // m2NotifSent is a CF-managed sentinel field — never written by updatePath().
    // Set to false on creation so rpM2UnlockReminder can query 'where m2NotifSent == false'.
    data['m2NotifSent'] = false;
    await _paths.doc(habitId).set(data);
    return path;
  }

  @override
  Future<void> updatePath(RecoveryPath path) async {
    await _paths.doc(path.id).update(path.toFirestore());
  }

  @override
  Future<void> saveSession(RecoverySession session, {required String uid}) async {
    final encrypted = _enc.encryptField(session.responseText, uid) ?? '';
    await _sessions(session.habitId)
        .doc(session.id)
        .set(session.toFirestore(encryptedText: encrypted));
  }

  @override
  Future<List<RecoverySession>> getSessions(
    String habitId, {
    required String uid,
    RecoverySessionType? type,
  }) async {
    Query<Map<String, dynamic>> q =
        _sessions(habitId).orderBy('createdAt', descending: true);
    if (type != null) {
      q = q.where('sessionType', isEqualTo: type.value);
    }
    final snap = await q.get();
    return snap.docs.map((doc) {
      final encrypted = doc.data()['responseText'] as String? ?? '';
      final decrypted = _enc.decryptField(encrypted, uid) ?? '';
      return RecoverySession.fromFirestore(doc, decryptedText: decrypted);
    }).toList();
  }

  @override
  Future<bool> hasDailyCheckInToday(String habitId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final snap = await _sessions(habitId)
        .where('sessionType',
            isEqualTo: RecoverySessionType.m1DailyCheckIn.value)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  @override
  Future<bool> hasWeeklyCompassThisWeek(String habitId) async {
    final now = DateTime.now();
    // Week starts on Monday.
    final daysSinceMonday = (now.weekday - 1) % 7;
    final startOfWeek =
        DateTime(now.year, now.month, now.day - daysSinceMonday);
    final snap = await _sessions(habitId)
        .where('sessionType',
            isEqualTo: RecoverySessionType.m3WeeklyCompass.value)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}
