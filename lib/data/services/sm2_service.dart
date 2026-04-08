// SM2 Spaced Repetition Service
//
// Implements the SuperMemo 2 algorithm (Wozniak, 1987) with two MyWalk
// extensions:
//   1. Grace period forgiveness — reviews completed 1–3 days late are
//      treated as on-time. Beyond 3 days late the interval is reduced by
//      20% but never reset to 0.
//   2. Streak bonus — if streakCount >= 7, one extra day is added to the
//      computed interval as a gentle encouragement reward.
//
// NOTE: The grace-period multiplier is only applied in the exponential
// growth phase (repetitionCount >= 2). For n=0 (→1 day) and n=1 (→6 days)
// the fixed bootstrap intervals are used as-is — this is correct SM2
// behaviour because those first two intervals are too short to penalise.

class SM2Service {
  static const double minEaseFactor = 1.3;
  static const double maxEaseFactor = 5.0;
  static const double initialEaseFactor = 2.5;

  /// Compute the next review state after a single review session.
  ///
  /// [qualityScore]     SM2 quality 0–5 (see QualityScore.derive()).
  /// [currentEF]        Current ease factor (starts at 2.5).
  /// [currentInterval]  Days since last review (starts at 1).
  /// [repetitionCount]  Consecutive successful reviews before this session.
  /// [streakCount]      Consecutive days reviewed successfully (for bonus).
  /// [scheduledFor]     When the review was originally due.
  /// [reviewedAt]       When the user actually completed the review.
  static SM2Result computeNextReview({
    required int qualityScore,
    required double currentEF,
    required double currentInterval,
    required int repetitionCount,
    required int streakCount,
    required DateTime scheduledFor,
    required DateTime reviewedAt,
  }) {
    assert(qualityScore >= 0 && qualityScore <= 5,
        'qualityScore must be 0–5, got $qualityScore');

    // ------------------------------------------------------------------
    // Step 1: Grace period adjustment (exponential phase only)
    // ------------------------------------------------------------------
    final daysLate = reviewedAt.difference(scheduledFor).inDays;
    // Multiplier only applied when repetitionCount >= 2.
    double intervalMultiplier = 1.0;
    if (daysLate > 3 && repetitionCount >= 2) intervalMultiplier = 0.8;

    // ------------------------------------------------------------------
    // Step 2: Update ease factor
    //   EF' = EF - 0.8 + 0.28q - 0.02q²  (simplified SM2 formula)
    //   Clamped to [minEaseFactor, maxEaseFactor].
    // ------------------------------------------------------------------
    final q = qualityScore;
    double newEF = currentEF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    newEF = newEF.clamp(minEaseFactor, maxEaseFactor);

    // ------------------------------------------------------------------
    // Step 3: Compute new interval and repetition count
    // ------------------------------------------------------------------
    double newInterval;
    int newRepetitionCount;

    if (qualityScore < 3) {
      // Failed review — reset learning sequence.
      newInterval = 1;
      newRepetitionCount = 0;
    } else {
      // Successful review.
      if (repetitionCount == 0) {
        newInterval = 1; // First success: review again tomorrow.
      } else if (repetitionCount == 1) {
        newInterval = 6; // Second success: ~one week.
      } else {
        // Exponential growth phase.
        newInterval =
            (currentInterval * newEF * intervalMultiplier).roundToDouble();
        if (newInterval < 1) newInterval = 1;
      }

      // Streak bonus: reward consistent practice with a slightly longer gap.
      if (streakCount >= 7) newInterval += 1;

      newRepetitionCount = repetitionCount + 1;
    }

    final nextReviewDate =
        reviewedAt.add(Duration(days: newInterval.round()));

    return SM2Result(
      newEaseFactor: newEF,
      newInterval: newInterval,
      newRepetitionCount: newRepetitionCount,
      nextReviewDate: nextReviewDate,
    );
  }

  // ---------------------------------------------------------------------------
  // Quality score derivation
  // ---------------------------------------------------------------------------

  /// Maps objective accuracy (0.0–1.0) and user confidence (1–5) to an SM2
  /// quality score (0–5).
  ///
  /// Objective accuracy is computed differently per mode:
  ///   Cloze / Typing: correctBlanks / totalBlanks  (or levenshteinScore)
  ///   Flip card:      1.0 if "Knew it", 0.0 if "Didn't know"
  ///   Progressive:    1.0 if completed without Reveal, else 0.0
  ///   Recitation:     levenshteinScore from STT transcript
  static int deriveQualityScore({
    required double objectiveAccuracy,
    required int confidence,
  }) {
    assert(confidence >= 1 && confidence <= 5);

    if (objectiveAccuracy < 0.50) {
      return objectiveAccuracy < 0.25 ? 0 : 1;
    } else if (objectiveAccuracy < 0.80) {
      return confidence <= 2 ? 2 : 3;
    } else if (objectiveAccuracy < 0.95) {
      return confidence <= 3 ? 3 : 4;
    } else {
      return confidence <= 3 ? 4 : 5;
    }
  }

  /// Quality score for Flip Card mode.
  ///   "Knew it":    min(5, confidence + 1)
  ///   "Didn't know": always 1
  static int flipCardQuality({
    required bool knewIt,
    required int confidence,
  }) {
    if (!knewIt) return 1;
    return (confidence + 1).clamp(2, 5);
  }
}

// ---------------------------------------------------------------------------
// SM2Result — value object returned by computeNextReview
// ---------------------------------------------------------------------------

class SM2Result {
  final double newEaseFactor;
  final double newInterval;
  final int newRepetitionCount;
  final DateTime nextReviewDate;

  const SM2Result({
    required this.newEaseFactor,
    required this.newInterval,
    required this.newRepetitionCount,
    required this.nextReviewDate,
  });

  @override
  String toString() => 'SM2Result('
      'EF=${newEaseFactor.toStringAsFixed(2)}, '
      'I=${newInterval}d, '
      'n=$newRepetitionCount, '
      'next=$nextReviewDate)';
}
