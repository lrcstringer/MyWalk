import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../data/datasources/local/notification_service.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../domain/entities/recovery_path.dart';
import '../../domain/entities/recovery_session.dart';
import '../../domain/repositories/recovery_path_repository.dart';
import '../../domain/services/recovery_phase_calculator.dart';

class RecoveryPathProvider extends ChangeNotifier {
  final RecoveryPathRepository _repo;

  RecoveryPathProvider(this._repo) {
    AuthService.shared.addListener(_onAuthChanged);
  }

  // Per-habit cache of loaded paths.
  final Map<String, RecoveryPath?> _paths = {};
  final Map<String, bool> _loading = {};
  final Map<String, bool> _checkInDoneToday = {};
  final Map<String, bool> _compassDoneThisWeek = {};
  final _zeroLogNudgeChecked = <String>{};

  String? _errorFor(String habitId) => _errors[habitId];
  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    AuthService.shared.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!AuthService.shared.isAuthenticated) {
      _paths.clear();
      _loading.clear();
      _errors.clear();
      _checkInDoneToday.clear();
      _compassDoneThisWeek.clear();
      _zeroLogNudgeChecked.clear();
      notifyListeners();
    }
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  RecoveryPath? pathFor(String habitId) => _paths[habitId];
  bool isLoadingFor(String habitId) => _loading[habitId] ?? false;
  String? errorFor(String habitId) => _errorFor(habitId);

  bool checkInDoneToday(String habitId) => _checkInDoneToday[habitId] ?? false;
  bool compassDoneThisWeek(String habitId) =>
      _compassDoneThisWeek[habitId] ?? false;

  int phaseFor(String habitId) {
    final path = _paths[habitId];
    if (path == null) return 1;
    return RecoveryPhaseCalculator.calculate(path);
  }

  bool isModuleUnlocked(String habitId, int moduleNumber) {
    final path = _paths[habitId];
    if (path == null) return false;
    return RecoveryPhaseCalculator.isModuleUnlocked(path, moduleNumber);
  }

  /// Returns "Day X" based on startedAt.
  int dayNumberFor(String habitId) {
    final path = _paths[habitId];
    if (path == null) return 1;
    return DateTime.now().difference(path.startedAt).inDays + 1;
  }

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadPath(String habitId) async {
    if (_loading[habitId] == true) return;
    _loading[habitId] = true;
    _errors[habitId] = null;
    notifyListeners();

    try {
      final path = await _repo.getPath(habitId);
      // Abort if the user signed out while the request was in flight.
      if (!AuthService.shared.isAuthenticated) return;
      _paths[habitId] = path;
      if (path != null) {
        await _refreshStatusFlags(habitId);
        await _maybeWriteBackPhase(path);
        _checkZeroLogNudge(habitId).ignore();
      }
    } catch (e) {
      _errors[habitId] = e.toString();
    } finally {
      _loading[habitId] = false;
      notifyListeners();
    }
  }

  Future<void> _refreshStatusFlags(String habitId) async {
    final [checkIn, compass] = await Future.wait([
      _repo.hasDailyCheckInToday(habitId),
      _repo.hasWeeklyCompassThisWeek(habitId),
    ]);
    _checkInDoneToday[habitId] = checkIn;
    _compassDoneThisWeek[habitId] = compass;
  }

  /// Write phase back to Firestore if it has changed since last load.
  Future<void> _maybeWriteBackPhase(RecoveryPath path) async {
    final calculated = RecoveryPhaseCalculator.calculate(path);
    if (calculated != path.currentPhase) {
      final updated = path.copyWith(currentPhase: calculated);
      _paths[path.id] = updated;
      await _repo.updatePath(updated);
    }
  }

  Future<void> _checkZeroLogNudge(String habitId) async {
    if (_zeroLogNudgeChecked.contains(habitId)) return;
    _zeroLogNudgeChecked.add(habitId);
    try {
      final uid = AuthService.shared.userId;
      if (uid == null) return;
      final sessions = await _repo.getSessions(habitId, uid: uid, type: RecoverySessionType.m1BehaviourLog);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final hasRecent = sessions.any((s) => s.createdAt.isAfter(sevenDaysAgo));
      if (!hasRecent) {
        await NotificationService.shared.scheduleZeroLogNudge(habitId);
      }
    } catch (_) {}
  }

  // ── Start path ───────────────────────────────────────────────────────────

  Future<RecoveryPath> startPath(String habitId) async {
    final uid = AuthService.shared.userId!;
    final path = await _repo.startPath(habitId: habitId, userId: uid);
    _paths[habitId] = path;
    _checkInDoneToday[habitId] = false;
    _compassDoneThisWeek[habitId] = false;
    notifyListeners();
    NotificationService.shared.scheduleRecoveryPathReminder().ignore();
    return path;
  }

  // ── Save session ─────────────────────────────────────────────────────────

  Future<void> saveSession(RecoverySession session) async {
    final uid = AuthService.shared.userId!;
    await _repo.saveSession(session, uid: uid);

    final habitId = session.habitId;
    final path = _paths[habitId];
    if (path == null) return;

    RecoveryPath updated = path;

    switch (session.sessionType) {
      case RecoverySessionType.m1DailyCheckIn:
        // Parse structured rating/outcome written by DailyCheckInScreen.
        int? rating;
        String? outcome;
        try {
          final parsed = jsonDecode(session.responseText) as Map<String, dynamic>;
          rating = parsed['rating'] as int?;
          outcome = parsed['outcome'] as String?;
        } catch (_) {}
        updated = path.copyWith(
          module1: path.module1.copyWith(
            dailyCheckInCount: path.module1.dailyCheckInCount + 1,
            lastCheckInAt: session.createdAt,
          ),
          dailyCheckInEmotionalRating: rating,
          dailyCheckInOutcome: outcome,
        );
        _checkInDoneToday[habitId] = true;
      case RecoverySessionType.m3ValuesInventory:
        updated = path.copyWith(
          module3: path.module3.copyWith(valuesInventoryDone: true),
        );
      case RecoverySessionType.m3WeeklyCompass:
        updated = path.copyWith(
          module3: path.module3.copyWith(lastCompassAt: session.createdAt),
        );
        _compassDoneThisWeek[habitId] = true;
      case RecoverySessionType.m4UrgeSurfing:
        updated = path.copyWith(
          module4: path.module4.copyWith(
            urgeSurfingCount: path.module4.urgeSurfingCount + 1,
          ),
        );
      case RecoverySessionType.m5RecoveryLetter:
        updated = path.copyWith(
          module5: path.module5.copyWith(recoveryLetterWritten: true),
        );
      case RecoverySessionType.m5QuarterlyReview:
        updated = path.copyWith(
          module5: path.module5.copyWith(
            quarterlyReviewCount: path.module5.quarterlyReviewCount + 1,
          ),
        );
      case RecoverySessionType.lapseRecord:
        updated = path.copyWith(
          totalLapses: path.totalLapses + 1,
          lastLapseAt: session.createdAt,
          // Unlock M5 on first lapse by ensuring phase will reach 4.
        );
      case RecoverySessionType.m1MidPointReflection:
        updated = path.copyWith(midPointReflectionDone: true);
      case RecoverySessionType.m5LapseResponse:
        updated = path.copyWith(
          totalLapses: path.totalLapses + 1,
          lastLapseAt: session.createdAt,
        );
      case RecoverySessionType.m1WeeklyReview:
      case RecoverySessionType.m2ThoughtExamination:
      case RecoverySessionType.m1BehaviourLog:
      case RecoverySessionType.m1CueHierarchy:
      case RecoverySessionType.m4EnvironmentalRestructuring:
      case RecoverySessionType.m4LifestyleAudit:
      case RecoverySessionType.m5AveEducation:
        break;
    }

    _paths[habitId] = updated;
    await _maybeWriteBackPhase(updated);
    notifyListeners();
  }

  // ── Counter-response library (M2) ────────────────────────────────────────

  Future<void> addCounterResponse(String habitId, Map<String, dynamic> response) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = path.copyWith(
      counterResponses: [...path.counterResponses, response],
    );
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    notifyListeners();
  }

  // ── HRS plan (M4) ────────────────────────────────────────────────────────

  Future<void> saveHrsPlan(String habitId, List<HrsPlan> plans) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = path.copyWith(
      module4: path.module4.copyWith(hrsPlan: plans),
    );
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    notifyListeners();
  }

  Future<void> markHrsPlanDone(String habitId) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = path.copyWith(hrsPlanDone: true);
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    notifyListeners();
  }

  Future<void> markModule5IntroSeen(String habitId) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = path.copyWith(module5IntroSeen: true);
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    notifyListeners();
  }

  Future<void> markUrgeSurfingIntroSeen(String habitId) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = path.copyWith(urgeSurfingIntroSeen: true);
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    notifyListeners();
  }

  Future<void> markEnvironmentalChecklistDone(String habitId) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = path.copyWith(
      module4: path.module4.copyWith(environmentalChecklistDone: true),
    );
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    notifyListeners();
  }

  // ── Recovery letter (M5) ─────────────────────────────────────────────────

  Future<void> saveRecoveryLetterDraft(String habitId, String letter) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = path.copyWith(
      recoveryLetterDraft: letter,
      module5: path.module5.copyWith(recoveryLetterWritten: true),
    );
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    notifyListeners();
  }

  // ── Values inventory ─────────────────────────────────────────────────────

  Future<void> saveValuesInventoryDraft(
    String habitId,
    int step,
    List<Map<String, dynamic>> entries,
  ) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = path.copyWith(
      valuesInventoryDraftStep: step,
      valuesInventoryDraft: entries,
    );
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    notifyListeners();
  }

  Future<void> saveValuesInventoryEntries(
    String habitId,
    List<ValuesInventoryEntry> entries,
  ) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = path.copyWith(
      module3: path.module3.copyWith(
        valuesInventory: entries,
        valuesInventoryDone: true,
      ),
    );
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    notifyListeners();
  }

  // ── Delete all paths ─────────────────────────────────────────────────────

  Future<void> deleteAllPaths(List<String> habitIds) async {
    await Future.wait([
      for (final hId in habitIds)
        _repo.deletePath(hId).catchError((_) {}),
    ]);
    _paths.clear();
    _loading.clear();
    _errors.clear();
    _checkInDoneToday.clear();
    _compassDoneThisWeek.clear();
    _zeroLogNudgeChecked.clear();
    notifyListeners();
  }

  // ── Cue hierarchy (M1) ───────────────────────────────────────────────────

  Future<List<RecoverySession>> getSessionsByType(
    String habitId,
    RecoverySessionType type,
  ) async {
    final uid = AuthService.shared.userId!;
    return _repo.getSessions(habitId, uid: uid, type: type);
  }

  Future<List<RecoverySession>> getAllSessions(String habitId) async {
    final uid = AuthService.shared.userId!;
    return _repo.getSessions(habitId, uid: uid);
  }

  Future<int> getBehaviourLogCount(String habitId) async {
    final sessions = await getSessionsByType(
        habitId, RecoverySessionType.m1BehaviourLog);
    return sessions.length;
  }

  Future<void> saveCueHierarchy(
    String habitId,
    List<Map<String, dynamic>> cues,
  ) async {
    final path = _paths[habitId];
    if (path == null) return;
    final uid = AuthService.shared.userId!;
    final updated = path.copyWith(
      cueHierarchy: cues,
      cueHierarchyDone: true,
      cueHierarchyDraftStage: 0,
    );
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    final now = DateTime.now();
    await _repo.saveSession(
      RecoverySession(
        id: '${habitId}_m1CueHierarchy_${now.millisecondsSinceEpoch}',
        habitId: habitId,
        sessionType: RecoverySessionType.m1CueHierarchy,
        moduleNumber: 1,
        responseText: '${cues.length} pattern triggers identified.',
        createdAt: now,
      ),
      uid: uid,
    );
    await _maybeWriteBackPhase(updated);
    notifyListeners();
  }

  Future<void> markEnvironmentalChangesDone(
    String habitId,
    List<Map<String, dynamic>> changes,
  ) async {
    final path = _paths[habitId];
    if (path == null) return;
    final uid = AuthService.shared.userId!;
    final updated = path.copyWith(environmentalChangesDone: true);
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    final now = DateTime.now();
    await _repo.saveSession(
      RecoverySession(
        id: '${habitId}_m4EnvironmentalRestructuring_${now.millisecondsSinceEpoch}',
        habitId: habitId,
        sessionType: RecoverySessionType.m4EnvironmentalRestructuring,
        moduleNumber: 4,
        responseText: changes
            .map((c) => '${c['cue']}: ${c['change']}')
            .join('\n\n'),
        createdAt: now,
      ),
      uid: uid,
    );
    notifyListeners();
  }

  // ── Lifestyle audit (M4) ─────────────────────────────────────────────────

  Future<void> saveLifestyleAudit(String habitId, String responseText) async {
    final path = _paths[habitId];
    if (path == null) return;
    final uid = AuthService.shared.userId!;
    final now = DateTime.now();
    final updated = path.copyWith(lastLifestyleAuditAt: now);
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    await _repo.saveSession(
      RecoverySession(
        id: '${habitId}_m4LifestyleAudit_${now.millisecondsSinceEpoch}',
        habitId: habitId,
        sessionType: RecoverySessionType.m4LifestyleAudit,
        moduleNumber: 4,
        responseText: responseText,
        createdAt: now,
      ),
      uid: uid,
    );
    notifyListeners();
  }

  bool isLifestyleAuditDue(RecoveryPath path) {
    final last = path.lastLifestyleAuditAt;
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= 30;
  }

  bool isQuarterlyReviewDue(RecoveryPath path, int dayNumber) {
    return path.quarterlyReviewDueDays.any((d) => dayNumber >= d) &&
        path.module5.quarterlyReviewCount <
            path.quarterlyReviewDueDays
                .where((d) => dayNumber >= d)
                .length;
  }

  // ── Thought examination draft (M2) ───────────────────────────────────────

  Future<void> saveThoughtExaminationDraft(
    String habitId,
    int step,
    Map<String, dynamic> draftData,
  ) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = path.copyWith(
      thoughtExaminationDraftStep: step,
      thoughtExaminationDraft: draftData,
    );
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
  }

  Future<void> clearThoughtExaminationDraft(String habitId) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = RecoveryPath(
      id: path.id,
      userId: path.userId,
      habitId: path.habitId,
      startedAt: path.startedAt,
      currentPhase: path.currentPhase,
      module1: path.module1,
      module3: path.module3,
      module4: path.module4,
      module5: path.module5,
      totalLapses: path.totalLapses,
      lastLapseAt: path.lastLapseAt,
      recoveryLetterDraft: path.recoveryLetterDraft,
      counterResponses: path.counterResponses,
      habitType: path.habitType,
      cueHierarchyDone: path.cueHierarchyDone,
      cueHierarchy: path.cueHierarchy,
      environmentalChangesDone: path.environmentalChangesDone,
      hrsPlanDone: path.hrsPlanDone,
      urgeSurfingIntroSeen: path.urgeSurfingIntroSeen,
      module5IntroSeen: path.module5IntroSeen,
      lapseButtonAvailableFrom: path.lapseButtonAvailableFrom,
      lastLifestyleAuditAt: path.lastLifestyleAuditAt,
      quarterlyReviewDueDays: path.quarterlyReviewDueDays,
      thoughtExaminationDraftStep: 0,
      thoughtExaminationDraft: null,
      valuesInventoryDraftStep: path.valuesInventoryDraftStep,
      valuesInventoryDraft: path.valuesInventoryDraft,
      cueHierarchyDraftStage: path.cueHierarchyDraftStage,
      dailyCheckInEmotionalRating: path.dailyCheckInEmotionalRating,
      dailyCheckInOutcome: path.dailyCheckInOutcome,
      midPointReflectionDone: path.midPointReflectionDone,
    );
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
    notifyListeners();
  }

  Future<void> saveCueHierarchyDraft(String habitId, int stage) async {
    final path = _paths[habitId];
    if (path == null) return;
    final updated = path.copyWith(cueHierarchyDraftStage: stage);
    _paths[habitId] = updated;
    await _repo.updatePath(updated);
  }

  // ── Load sessions ─────────────────────────────────────────────────────────

  Future<List<RecoverySession>> getSessions(
    String habitId, {
    RecoverySessionType? type,
  }) async {
    final uid = AuthService.shared.userId!;
    return _repo.getSessions(habitId, uid: uid, type: type);
  }
}
