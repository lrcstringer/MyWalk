import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';
import '../datasources/remote/api_service.dart';

class CircleRepositoryImpl implements CircleRepository {
  final APIService _api;
  CircleRepositoryImpl(this._api);

  @override
  Future<List<Circle>> listCircles() async {
    final items = await _api.listCircles();
    return items
        .map((e) => Circle(
              id: e.id,
              name: e.name,
              description: e.description,
              memberCount: e.memberCount,
              role: e.role,
              inviteCode: e.inviteCode,
            ))
        .toList();
  }

  @override
  Future<CircleDetails> getCircleDetail(String circleId) async {
    final d = await _api.getCircleDetail(circleId);
    return CircleDetails(
      id: d.id,
      name: d.name,
      description: d.description,
      memberCount: d.memberCount,
      inviteCode: d.inviteCode,
      createdAt: d.createdAt,
      members: d.members
          .map((m) =>
              CircleMember(userId: m.userId, role: m.role, joinedAt: m.joinedAt))
          .toList(),
    );
  }

  @override
  Future<Circle> createCircle(String name, {String description = ''}) async {
    final r = await _api.createCircle(name, description: description);
    return Circle(
        id: r.id,
        name: r.name,
        description: description,
        memberCount: 1,
        role: 'admin',
        inviteCode: r.inviteCode);
  }

  @override
  Future<JoinCircleResult> joinCircle(String inviteCode) async {
    final r = await _api.joinCircle(inviteCode);
    return JoinCircleResult(
        id: r.id, name: r.name, alreadyMember: r.alreadyMember);
  }

  @override
  Future<void> leaveCircle(String circleId) => _api.leaveCircle(circleId);

  @override
  Future<void> sendSOS(
          String circleId, String message, List<String> recipientIds) =>
      _api.sendSOS(circleId, message, recipientIds);

  @override
  Future<List<SOSMessage>> getRecentSOS(
      {String? circleId, int limit = 20}) async {
    final items = await _api.getRecentSOS(circleId: circleId, limit: limit);
    return items
        .map((e) => SOSMessage(
              id: e.id,
              senderId: e.senderId,
              circleId: e.circleId,
              message: e.message,
              createdAt: e.createdAt,
              isMine: e.isMine,
            ))
        .toList();
  }

  @override
  Future<String> generateShareLink(String circleId) async {
    final r = await _api.generateShareLink(circleId);
    return r.shareUrl;
  }

  @override
  Future<CircleWeeklySummary> getSundaySummary(String circleId) async {
    final r = await _api.getSundaySummary(circleId);
    return CircleWeeklySummary(
      circleId: r.circleId,
      weekOf: r.weekOf,
      totalMembers: r.totalMembers,
      activeMembers: r.activeMembers,
      averageScore: r.averageScore,
      topMembers: r.topStreaks
          .map((s) => CircleWeeklyTopMember(userId: s.userId, streak: s.streak))
          .toList(),
    );
  }

  @override
  Future<void> setSOSContacts(
          String circleId, List<String> contactUserIds) =>
      _api.setSOSContacts(circleId, contactUserIds);

  @override
  Future<GratitudeWall> getGratitudeWall(String circleId,
      {int weeksBack = 0}) async {
    final r = await _api.getGratitudeWall(circleId, weeksBack: weeksBack);
    return GratitudeWall(
      circleId: r.circleId,
      weeksBack: r.weeksBack,
      gratitudes: r.gratitudes
          .map((g) => GratitudePost(
                id: g.id,
                gratitudeText: g.gratitudeText,
                isAnonymous: g.isAnonymous,
                displayName: g.displayName,
                sharedAt: g.sharedAt,
                isMine: g.isMine,
              ))
          .toList(),
    );
  }

  @override
  Future<void> shareGratitude({
    required List<String> circleIds,
    required String gratitudeText,
    required bool isAnonymous,
    String? displayName,
  }) =>
      _api.shareGratitude(
        circleIds: circleIds,
        gratitudeText: gratitudeText,
        isAnonymous: isAnonymous,
        displayName: displayName,
      );

  @override
  Future<void> deleteGratitude(String circleId, String gratitudeId) =>
      _api.deleteGratitude(circleId, gratitudeId);

  @override
  Future<int> getGratitudeNewCount(String circleId) async {
    final r = await _api.getGratitudeNewCount(circleId);
    return r.newCount;
  }

  @override
  Future<void> markGratitudesSeen(String circleId) =>
      _api.markGratitudesSeen(circleId);

  @override
  Future<int> getGratitudeWeekCount(String circleId) async {
    final r = await _api.getGratitudeWeekCount(circleId);
    return r.weekCount;
  }

  @override
  Future<CircleHeatmap> getCircleHeatmap(String circleId,
      {int weekCount = 1}) async {
    final r = await _api.getCircleHeatmap(circleId, weekCount: weekCount);
    return CircleHeatmap(
      circleId: r.circleId,
      weekCount: r.weekCount,
      days: r.days
          .map((d) => HeatmapDay(date: d.date, intensity: d.intensity))
          .toList(),
    );
  }

  @override
  Future<CollectiveMilestones> getCircleMilestones(String circleId) async {
    final r = await _api.getCircleMilestones(circleId);
    return CollectiveMilestones(
      circleId: r.circleId,
      totalGivingDays: r.totalGivingDays,
      totalHours: r.totalHours,
      totalGratitudeDays: r.totalGratitudeDays,
      milestones: r.milestones
          .map((m) => CollectiveMilestone(
                id: m.id,
                title: m.title,
                message: m.message,
                achievedAt: m.achievedAt,
              ))
          .toList(),
    );
  }

  @override
  Future<void> submitHeatmapData(
          String circleId, List<Map<String, dynamic>> weekData) =>
      _api.submitHeatmapData(circleId, weekData);
}
