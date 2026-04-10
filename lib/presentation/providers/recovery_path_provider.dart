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

  bool isModuleUnlocked(String habitId, int moduleNumber) =>
      RecoveryPhaseCalculator.isModuleUnlocked(moduleNumber, phaseFor(habitId));

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
        updated = path.copyWith(
          module1: path.module1.copyWith(
            dailyCheckInCount: path.module1.dailyCheckInCount + 1,
            lastCheckInAt: session.createdAt,
          ),
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
      case RecoverySessionType.m1WeeklyReview:
      case RecoverySessionType.m2ThoughtExamination:
        break;
    }

    _paths[habitId] = updated;
    await _maybeWriteBackPhase(updated);
    notifyListeners();
  }

  // ── Counter-response library (M2) ────────────────────────────────────────

  Future<void> addCounterResponse(String habitId, String response) async {
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
    notifyListeners();
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
