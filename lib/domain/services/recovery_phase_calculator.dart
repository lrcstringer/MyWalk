import '../entities/recovery_path.dart';

/// Pure function that computes the current phase (1–4) from path state.
///
/// Phase rules:
///   1 — Awareness     : default starting state
///   2 — Understanding : ≥ 7 M1 daily check-ins (weekly review unlocked)
///   3 — Anchoring     : ≥ 7 check-ins AND M3 values inventory done
///   4 — Resilience    : at least one lapse recorded (M5 unlocked)
///
/// Phase 4 takes priority — a lapse can happen at any phase.
class RecoveryPhaseCalculator {
  RecoveryPhaseCalculator._();

  static int calculate(RecoveryPath path) {
    if (path.totalLapses > 0) return 4;
    if (path.module1.dailyCheckInCount >= 7 && path.module3.valuesInventoryDone) {
      return 3;
    }
    if (path.module1.dailyCheckInCount >= 7) return 2;
    return 1;
  }

  /// Returns true if [moduleNumber] is unlocked at [phase].
  /// M1 and M3 are always unlocked (free). M2, M4, M5 require phase ≥ 2/3/4
  /// and are premium-gated at the UI layer.
  static bool isModuleUnlocked(int moduleNumber, int phase) {
    switch (moduleNumber) {
      case 1:
        return true;
      case 2:
        return phase >= 2;
      case 3:
        return true;
      case 4:
        return phase >= 3;
      case 5:
        return phase >= 4;
      default:
        return false;
    }
  }
}
