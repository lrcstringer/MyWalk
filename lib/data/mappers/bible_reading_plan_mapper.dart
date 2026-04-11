import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/bible_reading_plan.dart';

/// Converts [BibleReadingPlanState] to/from the Firestore wire format.
/// Kept in the data layer so the domain entity has no infrastructure dependency.
class BibleReadingPlanMapper {
  BibleReadingPlanMapper._();

  static Map<String, dynamic> toMap(BibleReadingPlanState s) => {
        'startDate': s.startDate != null ? Timestamp.fromDate(s.startDate!) : null,
        'liveDate': s.liveDate != null ? Timestamp.fromDate(s.liveDate!) : null,
        'status': s.status.name,
        'sectionsDone': s.sectionsDone,
        'milestonesShown': s.milestonesShown,
        'streakDays': s.streakDays,
        'lastStreakDate':
            s.lastStreakDate != null ? Timestamp.fromDate(s.lastStreakDate!) : null,
      };

  static BibleReadingPlanState fromMap(Map<String, dynamic> data) {
    DateTime? tsDate(String field) {
      final v = data[field];
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return BibleReadingPlanState(
      startDate: tsDate('startDate'),
      liveDate: tsDate('liveDate'),
      status: BibleReadingPlanStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? 'notStarted'),
        orElse: () => BibleReadingPlanStatus.notStarted,
      ),
      sectionsDone: Map<String, bool>.from(
        (data['sectionsDone'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v == true)),
      ),
      milestonesShown: List<int>.from(
        (data['milestonesShown'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt()),
      ),
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      lastStreakDate: tsDate('lastStreakDate'),
    );
  }
}
