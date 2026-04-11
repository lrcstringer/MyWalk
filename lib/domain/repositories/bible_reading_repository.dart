import '../entities/bible_reading_plan.dart';

abstract class BibleReadingRepository {
  /// Stream of the user's plan state. Emits null if no plan doc exists.
  Stream<BibleReadingPlanState?> watchPlanState();

  /// Fetch once (used on start-up before stream is ready).
  Future<BibleReadingPlanState?> getPlanState();

  /// Persist plan state (creates or overwrites the settings doc).
  Future<void> savePlanState(BibleReadingPlanState state);

  /// Mark a single section done/undone and persist atomically.
  Future<void> setSectionDone(
    int weekIndex,
    int dayIndex,
    BibleReadingSection section,
    bool done,
  );

  /// Persist milestone shown so it is never shown again.
  Future<void> addMilestoneShown(int weekIndex);

  /// Update only the plan status field atomically (no full-doc overwrite).
  Future<void> updatePlanStatus(BibleReadingPlanStatus status);

  /// Update streak fields atomically.
  Future<void> updateStreak(int streakDays, DateTime? lastStreakDate);

  /// Delete the entire plan state document (reset).
  Future<void> resetPlan();
}
