import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/bible_reading_plan.dart';
import '../../domain/repositories/bible_reading_repository.dart';
import '../mappers/bible_reading_plan_mapper.dart';

class FirestoreBibleReadingRepository implements BibleReadingRepository {
  final FirebaseFirestore _db;

  FirestoreBibleReadingRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('FirestoreBibleReadingRepository: no authenticated user');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      _db.collection('users').doc(_uid).collection('bibleReadingPlan').doc('settings');

  @override
  Stream<BibleReadingPlanState?> watchPlanState() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _settingsRef.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return BibleReadingPlanMapper.fromMap(snap.data()!);
    });
  }

  @override
  Future<BibleReadingPlanState?> getPlanState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _settingsRef.get();
    if (!snap.exists || snap.data() == null) return null;
    return BibleReadingPlanMapper.fromMap(snap.data()!);
  }

  @override
  Future<void> savePlanState(BibleReadingPlanState state) async {
    await _settingsRef.set(BibleReadingPlanMapper.toMap(state));
  }

  @override
  Future<void> setSectionDone(
    int weekIndex,
    int dayIndex,
    BibleReadingSection section,
    bool done,
  ) async {
    final key = '${weekIndex}_${dayIndex}_${section.key}';
    // Use update() with dot-notation so only this one entry in the sectionsDone
    // map is touched — set(..., merge: true) replaces the whole map value.
    await _settingsRef.update({'sectionsDone.$key': done});
  }

  @override
  Future<void> addMilestoneShown(int weekIndex) async {
    await _settingsRef.set(
      {'milestonesShown': FieldValue.arrayUnion([weekIndex])},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> updatePlanStatus(BibleReadingPlanStatus status) async {
    await _settingsRef.update({'status': status.name});
  }

  @override
  Future<void> updateStreak(int streakDays, DateTime? lastStreakDate) async {
    await _settingsRef.set(
      {
        'streakDays': streakDays,
        'lastStreakDate':
            lastStreakDate != null ? Timestamp.fromDate(lastStreakDate) : null,
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> resetPlan() async {
    await _settingsRef.delete();
  }
}
