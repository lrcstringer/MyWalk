import '../entities/circle.dart';

abstract class CircleRepository {
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
}
