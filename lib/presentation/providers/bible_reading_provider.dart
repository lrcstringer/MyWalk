import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../data/services/bible_reading_plan_data.dart';
import '../../domain/entities/bible_reading_plan.dart';
import '../../domain/repositories/bible_reading_repository.dart';

class BibleReadingProvider extends ChangeNotifier {
  final BibleReadingRepository _repository;

  BibleReadingProvider(this._repository) {
    AuthService.shared.addListener(_onAuthChanged);
    if (AuthService.shared.isAuthenticated) _subscribe();
  }

  BibleReadingPlanState? _state;
  bool _isLoading = false;
  StreamSubscription<BibleReadingPlanState?>? _sub;

  // ── Getters ──────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  BibleReadingPlanState? get state => _state;
  BibleReadingPlanStatus get status =>
      _state?.status ?? BibleReadingPlanStatus.notStarted;

  bool get isActive => status == BibleReadingPlanStatus.active;
  bool get isPending => status == BibleReadingPlanStatus.pending;
  bool get isNotStarted => status == BibleReadingPlanStatus.notStarted;

  /// Total distinct days where every section is complete.
  int get totalDaysRead {
    final s = _state;
    if (s == null) return 0;
    int count = 0;
    for (int w = 0; w < BibleReadingPlanData.weeks.length; w++) {
      final weekDays = BibleReadingPlanData.weeks[w];
      for (int d = 0; d < weekDays.length; d++) {
        if (s.isDayDone(w, d, weekDays[d])) count++;
      }
    }
    return count;
  }

  /// Returns null if not active.
  int? get currentWeekIndex => _state?.currentWeekIndex;

  /// Returns null if not active.
  int? get currentDayIndex => _state?.currentDayIndex;

  /// Days-until-live when pending.
  int? get daysUntilLive => _state?.daysUntilLive;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _sub?.cancel();
    AuthService.shared.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (AuthService.shared.isAuthenticated) {
      _subscribe();
    } else {
      _sub?.cancel();
      _sub = null;
      _state = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribe() {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _repository.watchPlanState().listen(
      (s) async {
        // Bug 2 fix: auto-upgrade pending → active when liveDate has passed.
        s = _resolvePendingToActive(s);
        _state = s;
        _isLoading = false;
        notifyListeners();
        // Bug 8 fix: recompute streak directly from the freshly-emitted state
        // rather than via a fragile fixed-duration delay.
        await _recomputeStreak(s);
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Transitions status from pending to active once liveDate has arrived.
  /// Writes the updated status to Firestore (fire-and-forget) so the change
  /// is durable and the stream won't flip back on next app start.
  BibleReadingPlanState? _resolvePendingToActive(BibleReadingPlanState? s) {
    if (s == null) return null;
    if (s.status != BibleReadingPlanStatus.pending || s.liveDate == null) {
      return s;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final live =
        DateTime(s.liveDate!.year, s.liveDate!.month, s.liveDate!.day);
    if (today.isBefore(live)) return s; // still pending
    final upgraded = s.copyWith(status: BibleReadingPlanStatus.active);
    // Use updatePlanStatus (field-level update) instead of savePlanState
    // (full overwrite) to avoid racing with concurrent setSectionDone calls.
    _repository.updatePlanStatus(BibleReadingPlanStatus.active).ignore();
    return upgraded;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Called when user taps "Start Plan".
  Future<void> startPlan() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final liveDate = _nextSunday(today);
    final status = today.isAtSameMomentAs(liveDate)
        ? BibleReadingPlanStatus.active
        : BibleReadingPlanStatus.pending;
    final newState = BibleReadingPlanState(
      startDate: today,
      liveDate: liveDate,
      status: status,
    );
    await _repository.savePlanState(newState);
  }

  /// Mark a section done/undone. The streak is recomputed in the stream
  /// listener once Firestore confirms the write via the real-time snapshot.
  Future<void> setSectionDone(
    int weekIndex,
    int dayIndex,
    BibleReadingSection section,
    bool done,
  ) async {
    await _repository.setSectionDone(weekIndex, dayIndex, section, done);
    // No delay needed — the Firestore stream listener handles streak recompute
    // when the updated snapshot arrives.
  }

  Future<void> markMilestoneShown(int weekIndex) async {
    await _repository.addMilestoneShown(weekIndex);
  }

  Future<void> resetPlan() async {
    await _repository.resetPlan();
  }

  // ── Streak logic ──────────────────────────────────────────────────────────

  /// Recomputes and persists the streak based on [s].
  /// Called from the stream listener so it always operates on the latest state.
  Future<void> _recomputeStreak(BibleReadingPlanState? s) async {
    if (s == null || s.status != BibleReadingPlanStatus.active) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final liveDate =
        DateTime(s.liveDate!.year, s.liveDate!.month, s.liveDate!.day);
    final elapsed = today.difference(liveDate).inDays.clamp(0, 363);

    // Walk backwards from the most recent anchor:
    // - If today's reading is already complete, the streak can include today.
    // - If today's reading is not yet complete, the streak runs up to yesterday
    //   (so the displayed streak doesn't collapse to 0 mid-day).
    final todayPlan = BibleReadingPlanData.weeks[elapsed ~/ 7][elapsed % 7];
    final todayDone = s.isDayDone(elapsed ~/ 7, elapsed % 7, todayPlan);
    final anchor = todayDone ? elapsed : elapsed - 1;

    int streak = 0;
    for (int i = anchor; i >= 0; i--) {
      final w = i ~/ 7;
      final d = i % 7;
      final dayPlan = BibleReadingPlanData.weeks[w][d];
      if (s.isDayDone(w, d, dayPlan)) {
        streak++;
      } else {
        break;
      }
    }

    // lastStreakDate is the calendar date of the most recently completed day.
    DateTime? lastStreakDate;
    if (streak > 0) {
      final lastDayIndex = todayDone ? elapsed : elapsed - 1;
      lastStreakDate = liveDate.add(Duration(days: lastDayIndex));
      // Normalise to midnight.
      lastStreakDate = DateTime(
          lastStreakDate.year, lastStreakDate.month, lastStreakDate.day);
    }

    if (streak != s.streakDays ||
        lastStreakDate?.millisecondsSinceEpoch !=
            s.lastStreakDate?.millisecondsSinceEpoch) {
      await _repository.updateStreak(streak, lastStreakDate);
    }
  }

  // ── Milestone check ───────────────────────────────────────────────────────

  /// Returns the week index of a pending milestone celebration, or null.
  int? pendingMilestone() {
    final s = _state;
    if (s == null || !isActive) return null;
    for (final w in BibleReadingPlanData.milestoneWeeks) {
      if (s.milestonesShown.contains(w)) continue;
      if (_isWeekComplete(s, w)) return w;
    }
    return null;
  }

  bool _isWeekComplete(BibleReadingPlanState s, int weekIndex) {
    if (weekIndex >= BibleReadingPlanData.weeks.length) return false;
    return s.isWeekDone(weekIndex, BibleReadingPlanData.weeks[weekIndex]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static DateTime _nextSunday(DateTime date) {
    // weekday: Mon=1 … Sun=7. If today is Sunday, (7-7)%7=0 → starts today.
    final daysUntilSunday = (7 - date.weekday) % 7;
    return date.add(Duration(days: daysUntilSunday));
  }
}
