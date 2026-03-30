import 'package:flutter/foundation.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';
import '../../domain/services/week_id_service.dart';

class CircleHabitsProvider extends ChangeNotifier {
  final CircleRepository _repo;

  CircleHabitsProvider(this._repo);

  final Map<String, List<CircleHabit>> _habitsByCircle = {};
  // Key: '{circleId}_{habitId}_{date}'
  final Map<String, CircleHabitDailySummary> _summaries = {};
  final Map<String, bool> _loadingByCircle = {};
  bool _creating = false;
  String? error;

  List<CircleHabit> habitsFor(String circleId) =>
      _habitsByCircle[circleId] ?? [];

  CircleHabitDailySummary? summaryFor(
      String circleId, String habitId, String date) {
    return _summaries['${circleId}_${habitId}_$date'];
  }

  bool isLoading(String circleId) => _loadingByCircle[circleId] ?? false;
  bool get isCreating => _creating;

  Future<void> load(String circleId) async {
    if (_loadingByCircle[circleId] == true) return;
    _loadingByCircle[circleId] = true;
    error = null;
    notifyListeners();

    try {
      final habits = await _repo.getCircleHabits(circleId);
      _habitsByCircle[circleId] = habits;

      final today = WeekIdService.todayStr();
      // Load today's summary for each active habit concurrently.
      final summaries = await Future.wait(
        habits.map((h) => _repo.getCircleHabitDailySummary(
            circleId, h.id, today)),
      );
      for (var i = 0; i < habits.length; i++) {
        final summary = summaries[i];
        if (summary != null) {
          _summaries['${circleId}_${habits[i].id}_$today'] = summary;
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      _loadingByCircle[circleId] = false;
      notifyListeners();
    }
  }

  Future<void> complete({
    required String circleId,
    required String habitId,
    required int value,
    required String uid,
  }) async {
    final today = WeekIdService.todayStr();
    final key = '${circleId}_${habitId}_$today';

    // Optimistic update: add uid to local summary so UI reflects instantly.
    final existing = _summaries[key];
    if (existing != null && !existing.hasCompleted(uid)) {
      _summaries[key] = CircleHabitDailySummary(
        id: existing.id,
        habitId: existing.habitId,
        totalMembers: existing.totalMembers,
        completedCount: existing.completedCount + 1,
        completedUserIds: [...existing.completedUserIds, uid],
      );
      notifyListeners();
    }

    try {
      await _repo.completeCircleHabit(
        circleId: circleId,
        habitId: habitId,
        value: value,
        date: today,
      );
    } catch (_) {
      // Roll back on failure.
      if (existing != null) {
        _summaries[key] = existing;
        notifyListeners();
      }
    }
  }

  Future<void> createHabit({
    required String circleId,
    required String name,
    required CircleHabitTrackingType trackingType,
    int? targetValue,
    required CircleHabitFrequency frequency,
    List<int>? specificDays,
    String? anchorVerse,
    String? purposeStatement,
    String? description,
  }) async {
    _creating = true;
    error = null;
    notifyListeners();

    try {
      await _repo.createCircleHabit(
        circleId: circleId,
        name: name,
        trackingType: trackingType,
        targetValue: targetValue,
        frequency: frequency,
        specificDays: specificDays,
        anchorVerse: anchorVerse,
        purposeStatement: purposeStatement,
        description: description,
      );
      // Reload to get server-assigned ID.
      await load(circleId);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _creating = false;
      notifyListeners();
    }
  }

  Future<void> deactivate(String circleId, String habitId) async {
    await _repo.deactivateCircleHabit(circleId, habitId);
    _habitsByCircle[circleId] =
        (_habitsByCircle[circleId] ?? []).where((h) => h.id != habitId).toList();
    notifyListeners();
  }
}
