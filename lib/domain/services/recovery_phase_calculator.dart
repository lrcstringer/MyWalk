import '../entities/recovery_path.dart';

/// Pure function that computes the current phase (1–4) from path state.
///
/// Phase rules (evaluated in priority order, highest first):
///   4 — Maintenance       : ≥ 90 days AND values inventory done
///   3 — Sustained Practice: ≥ 30 days OR any lapse recorded
///   2 — Going Deeper      : cue hierarchy done OR ≥ 14 days OR ≥ 14 check-ins
///   1 — Getting Started   : default
class RecoveryPhaseCalculator {
  RecoveryPhaseCalculator._();

  static int calculate(RecoveryPath path) {
    final daysSinceStart =
        DateTime.now().difference(path.startedAt).inDays;

    if (daysSinceStart >= 90 && path.module3.valuesInventoryDone) { return 4; }
    if (daysSinceStart >= 30 || path.totalLapses > 0) { return 3; }
    if (path.cueHierarchyDone ||
        daysSinceStart >= 14 ||
        path.module1.dailyCheckInCount >= 14) { return 2; }
    return 1;
  }

  /// Returns true if [moduleNumber] is unlocked for [path].
  /// M1 and M3 are always unlocked.
  /// M2 and M4 unlock when cue hierarchy is done or after 28 days.
  /// M5 unlocks after 30 days or on the first lapse.
  static bool isModuleUnlocked(RecoveryPath path, int moduleNumber) {
    final daysSinceStart =
        DateTime.now().difference(path.startedAt).inDays;
    switch (moduleNumber) {
      case 1:
        return true;
      case 2:
        return path.cueHierarchyDone || daysSinceStart >= 28;
      case 3:
        return true;
      case 4:
        return path.cueHierarchyDone || daysSinceStart >= 28;
      case 5:
        return daysSinceStart >= 30 || path.totalLapses > 0;
      default:
        return false;
    }
  }
}
