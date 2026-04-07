import '../entities/circle.dart';

abstract class CircleRepository {
  // ── Existing methods ────────────────────────────────────────────────────────
  Future<List<Circle>> listCircles();
  Future<CircleDetails> getCircleDetail(String circleId);
  Future<Circle> createCircle(String name, {String description});
  Future<JoinCircleResult> joinCircle(String inviteCode);
  Future<void> leaveCircle(String circleId);
  Future<void> sendSOS(String circleId, String message, List<String> recipientIds);
  Future<List<SOSMessage>> getRecentSOS({String? circleId, int limit});
  Future<String> generateShareLink(String circleId);
  Future<CircleWeeklySummary> getSundaySummary(String circleId);
  Future<void> setSOSContacts(String circleId, List<String> contactUserIds);
  Future<GratitudeWall> getGratitudeWall(String circleId, {int weeksBack});
  Future<void> shareGratitude({
    required List<String> circleIds,
    required String gratitudeText,
    required bool isAnonymous,
    String? displayName,
  });
  Future<void> deleteGratitude(String circleId, String gratitudeId);
  Future<int> getGratitudeNewCount(String circleId);
  Future<void> markGratitudesSeen(String circleId);
  Future<int> getGratitudeWeekCount(String circleId);
  Future<CircleHeatmap> getCircleHeatmap(String circleId, {int weekCount});
  Future<CollectiveMilestones> getCircleMilestones(String circleId);
  Future<void> submitHeatmapData(String circleId, List<Map<String, dynamic>> weekData);

  // ── Circle Settings ─────────────────────────────────────────────────────────
  Future<void> updateCircleSettings(String circleId, CircleSettings settings);
  Future<void> updateMemberRole(String circleId, String targetUserId, String role);

  // ── Feature 1: Prayer List ──────────────────────────────────────────────────
  Future<List<PrayerRequest>> getPrayerRequests(String circleId);
  Future<void> createPrayerRequest({
    required String circleId,
    required String requestText,
    required PrayerDuration duration,
    bool anonymous = false,
  });
  Future<void> prayForRequest(String circleId, String requestId);
  Future<void> markPrayerAnswered(
    String circleId,
    String requestId, {
    String? answeredNote,
  });

  // ── Feature 2: Scripture Threads ───────────────────────────────────────────
  Stream<List<ScriptureThread>> watchThreads(String circleId,
      {required bool isAdmin});
  Stream<List<ScriptureComment>> watchComments(
      String circleId, String threadId);
  Future<void> createThread({
    required String circleId,
    required String reference,
    required String passageText,
    required String translation,
  });
  Future<void> closeThread(String circleId, String threadId);
  Future<void> deleteThread(String circleId, String threadId);
  Future<void> addComment({
    required String circleId,
    required String threadId,
    required String text,
    String? parentId,
  });
  Future<void> deleteComment(
      String circleId, String threadId, String commentId);

  // ── Feature 3: Circle Habits ────────────────────────────────────────────────
  Future<List<CircleHabit>> getCircleHabits(String circleId);
  Future<CircleHabitDailySummary?> getCircleHabitDailySummary(
    String circleId,
    String habitId,
    String date,
  );
  Future<void> createCircleHabit({
    required String circleId,
    required String name,
    required CircleHabitTrackingType trackingType,
    int? targetValue,
    required CircleHabitFrequency frequency,
    List<int>? specificDays,
    String? anchorVerse,
    String? purposeStatement,
    String? description,
  });
  Future<void> completeCircleHabit({
    required String circleId,
    required String habitId,
    required int value,
    required String date,
  });
  Future<void> updateCircleHabit({
    required String circleId,
    required String habitId,
    required String name,
    required CircleHabitTrackingType trackingType,
    int? targetValue,
    required CircleHabitFrequency frequency,
    List<int>? specificDays,
    String? anchorVerse,
    String? purposeStatement,
    String? description,
  });
  Future<void> deleteCircleHabit(String circleId, String habitId);
  Future<void> deactivateCircleHabit(String circleId, String habitId);

  // ── Feature 4: Encouragements ───────────────────────────────────────────────
  Future<List<Encouragement>> getReceivedEncouragements(String circleId);
  Future<List<Encouragement>> getSentEncouragements(String circleId);
  Future<void> sendEncouragement({
    required String circleId,
    required String recipientId,
    required EncouragementMessageType messageType,
    String? presetKey,
    String? customText,
    required bool isAnonymous,
  });
  Future<void> markEncouragementRead(String circleId, String encouragementId);

  // ── Feature 5: Milestone Shares ─────────────────────────────────────────────
  Future<List<MilestoneShare>> getMilestoneShares(String circleId);
  Future<void> shareMilestone({
    required List<String> circleIds,
    required MilestoneShareType milestoneType,
    required int milestoneValue,
    required String habitName,
    required String userDisplayName,
  });
  Future<void> celebrateMilestone(String circleId, String shareId);

  // ── Feature 6: Weekly Pulse ─────────────────────────────────────────────────
  Future<WeeklyPulse?> getCurrentWeeklyPulse(String circleId);
  Future<PulseResponse?> getMyPulseResponse(String circleId, String weekId);
  Future<void> submitPulseResponse({
    required String circleId,
    required PulseStatus status,
    String? note,
    required bool isAnonymous,
  });

  // ── Circle Habit Milestones ─────────────────────────────────────────────────
  Future<List<CircleHabitMilestone>> getCircleHabitMilestones(String circleId);

  // ── Group Prayer List ───────────────────────────────────────────────────────
  Future<CirclePrayerList?> getGroupPrayerList(String circleId);
  Future<void> saveGroupPrayerList(CirclePrayerList list);
  Future<void> upsertGroupPrayerItem(String circleId, CirclePrayerItem item);
  Future<void> deleteGroupPrayerItem(String circleId, String itemId);

  // ── Feature 7: Events ───────────────────────────────────────────────────────
  Future<List<CircleEvent>> getUpcomingEvents(String circleId);
  Future<void> createEvent({
    required String circleId,
    required String title,
    required DateTime eventDate,
    String? description,
    String? location,
    String? meetingLink,
  });
  Future<void> updateEvent({
    required String circleId,
    required String eventId,
    required String title,
    required DateTime eventDate,
    String? description,
    String? location,
    String? meetingLink,
  });
  Future<void> deleteEvent(String circleId, String eventId);
}
