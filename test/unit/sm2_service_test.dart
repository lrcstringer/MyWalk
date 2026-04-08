import 'package:flutter_test/flutter_test.dart';
import 'package:mywalk/data/services/sm2_service.dart';

void main() {
  // Shared baseline inputs
  final baseScheduled = DateTime(2026, 1, 1);
  final baseReviewedOnTime = DateTime(2026, 1, 1);

  SM2Result compute({
    required int q,
    double ef = 2.5,
    double interval = 1.0,
    int n = 0,
    int streak = 0,
    DateTime? scheduledFor,
    DateTime? reviewedAt,
  }) {
    return SM2Service.computeNextReview(
      qualityScore: q,
      currentEF: ef,
      currentInterval: interval,
      repetitionCount: n,
      streakCount: streak,
      scheduledFor: scheduledFor ?? baseScheduled,
      reviewedAt: reviewedAt ?? baseReviewedOnTime,
    );
  }

  // ---------------------------------------------------------------------------
  group('SM2 — ease factor update', () {
    test('q=5 increases EF by 0.10', () {
      final r = compute(q: 5, ef: 2.5);
      expect(r.newEaseFactor, closeTo(2.60, 0.001));
    });

    test('q=4 leaves EF unchanged', () {
      final r = compute(q: 4, ef: 2.5);
      expect(r.newEaseFactor, closeTo(2.50, 0.001));
    });

    test('q=3 decreases EF by 0.14', () {
      final r = compute(q: 3, ef: 2.5);
      expect(r.newEaseFactor, closeTo(2.36, 0.001));
    });

    test('q=2 decreases EF by 0.32', () {
      final r = compute(q: 2, ef: 2.5);
      expect(r.newEaseFactor, closeTo(2.18, 0.001));
    });

    test('q=1 decreases EF by 0.54', () {
      final r = compute(q: 1, ef: 2.5);
      expect(r.newEaseFactor, closeTo(1.96, 0.001));
    });

    test('q=0 decreases EF by 0.80', () {
      final r = compute(q: 0, ef: 2.5);
      expect(r.newEaseFactor, closeTo(1.70, 0.001));
    });

    test('EF is clamped at minimum 1.3', () {
      final r = compute(q: 0, ef: 1.4);
      expect(r.newEaseFactor, equals(SM2Service.minEaseFactor));
    });

    test('EF cannot go below 1.3 even after many failures', () {
      var ef = 2.5;
      for (var i = 0; i < 10; i++) {
        final r = compute(q: 0, ef: ef);
        ef = r.newEaseFactor;
      }
      expect(ef, greaterThanOrEqualTo(SM2Service.minEaseFactor));
    });
  });

  // ---------------------------------------------------------------------------
  group('SM2 — interval progression (success path)', () {
    test('n=0 → interval 1 day', () {
      final r = compute(q: 3, n: 0);
      expect(r.newInterval, equals(1.0));
      expect(r.newRepetitionCount, equals(1));
    });

    test('n=1 → interval 6 days', () {
      final r = compute(q: 3, n: 1, interval: 1.0);
      expect(r.newInterval, equals(6.0));
      expect(r.newRepetitionCount, equals(2));
    });

    test('n=2, EF=2.5, I=6 → interval ~15 days', () {
      final r = compute(q: 4, n: 2, ef: 2.5, interval: 6.0);
      expect(r.newInterval, equals(15.0)); // round(6 × 2.5)
    });

    test('n=3 continues exponential growth', () {
      final r = compute(q: 4, n: 3, ef: 2.5, interval: 15.0);
      expect(r.newInterval, equals(38.0)); // round(15 × 2.5)
    });
  });

  // ---------------------------------------------------------------------------
  group('SM2 — failure path (q < 3)', () {
    test('q=2 resets interval to 1 and repetitionCount to 0', () {
      final r = compute(q: 2, n: 5, ef: 2.5, interval: 30.0);
      expect(r.newInterval, equals(1.0));
      expect(r.newRepetitionCount, equals(0));
    });

    test('q=0 resets both and lowers EF', () {
      final r = compute(q: 0, n: 10, ef: 2.5, interval: 60.0);
      expect(r.newInterval, equals(1.0));
      expect(r.newRepetitionCount, equals(0));
      expect(r.newEaseFactor, lessThan(2.5));
    });
  });

  // ---------------------------------------------------------------------------
  group('SM2 — grace period extension', () {
    test('1–3 days late in exponential phase: no penalty (multiplier = 1.0)',
        () {
      final scheduled = DateTime(2026, 1, 1);
      final reviewedLate = DateTime(2026, 1, 3); // 2 days late
      final rLate = compute(
        q: 4,
        n: 2,
        ef: 2.5,
        interval: 6.0,
        scheduledFor: scheduled,
        reviewedAt: reviewedLate,
      );
      final rOnTime = compute(
        q: 4,
        n: 2,
        ef: 2.5,
        interval: 6.0,
        scheduledFor: scheduled,
        reviewedAt: scheduled,
      );
      expect(rLate.newInterval, equals(rOnTime.newInterval));
    });

    test('>3 days late in exponential phase: 20% interval reduction', () {
      final scheduled = DateTime(2026, 1, 1);
      final reviewedVeryLate = DateTime(2026, 1, 6); // 5 days late
      final r = compute(
        q: 4,
        n: 2,
        ef: 2.5,
        interval: 6.0,
        scheduledFor: scheduled,
        reviewedAt: reviewedVeryLate,
      );
      // Expected: round(6 × 2.5 × 0.8) = round(12) = 12
      expect(r.newInterval, equals(12.0));
    });

    test('late penalty NOT applied to bootstrap phase (n=0)', () {
      final scheduled = DateTime(2026, 1, 1);
      final reviewedVeryLate = DateTime(2026, 1, 10); // 9 days late
      final r = compute(
        q: 4,
        n: 0,
        scheduledFor: scheduled,
        reviewedAt: reviewedVeryLate,
      );
      expect(r.newInterval, equals(1.0)); // bootstrap fixed value
    });

    test('late penalty NOT applied to bootstrap phase (n=1)', () {
      final scheduled = DateTime(2026, 1, 1);
      final reviewedVeryLate = DateTime(2026, 1, 10);
      final r = compute(
        q: 4,
        n: 1,
        interval: 1.0,
        scheduledFor: scheduled,
        reviewedAt: reviewedVeryLate,
      );
      expect(r.newInterval, equals(6.0)); // bootstrap fixed value
    });
  });

  // ---------------------------------------------------------------------------
  group('SM2 — streak bonus', () {
    test('streak < 7: no bonus', () {
      final rNoBonus = compute(q: 4, n: 2, ef: 2.5, interval: 6.0, streak: 6);
      final rBaseline = compute(q: 4, n: 2, ef: 2.5, interval: 6.0, streak: 0);
      expect(rNoBonus.newInterval, equals(rBaseline.newInterval));
    });

    test('streak >= 7 adds +1 day to interval', () {
      final rBonus =
          compute(q: 4, n: 2, ef: 2.5, interval: 6.0, streak: 7);
      final rBaseline =
          compute(q: 4, n: 2, ef: 2.5, interval: 6.0, streak: 0);
      expect(rBonus.newInterval, equals(rBaseline.newInterval + 1));
    });

    test('streak bonus NOT applied on failure', () {
      final r = compute(q: 1, n: 5, interval: 30.0, streak: 10);
      expect(r.newInterval, equals(1.0)); // failure always → 1
    });
  });

  // ---------------------------------------------------------------------------
  group('SM2 — nextReviewDate', () {
    test('is set to reviewedAt + newInterval days', () {
      final reviewedAt = DateTime(2026, 4, 8);
      final r = compute(
        q: 4,
        n: 1,
        interval: 1.0,
        reviewedAt: reviewedAt,
        scheduledFor: DateTime(2026, 4, 8),
      );
      // n=1 → interval=6
      final expected = DateTime(2026, 4, 14); // 8 + 6 days
      expect(r.nextReviewDate.year, equals(expected.year));
      expect(r.nextReviewDate.month, equals(expected.month));
      expect(r.nextReviewDate.day, equals(expected.day));
    });
  });

  // ---------------------------------------------------------------------------
  group('SM2 — quality score derivation', () {
    test('accuracy < 25% → q=0', () {
      expect(SM2Service.deriveQualityScore(objectiveAccuracy: 0.20, confidence: 3), equals(0));
    });

    test('accuracy 25–50% → q=1', () {
      expect(SM2Service.deriveQualityScore(objectiveAccuracy: 0.40, confidence: 3), equals(1));
    });

    test('accuracy 50–79%, low confidence → q=2', () {
      expect(SM2Service.deriveQualityScore(objectiveAccuracy: 0.65, confidence: 2), equals(2));
    });

    test('accuracy 50–79%, high confidence → q=3', () {
      expect(SM2Service.deriveQualityScore(objectiveAccuracy: 0.65, confidence: 4), equals(3));
    });

    test('accuracy 80–94%, low confidence → q=3', () {
      expect(SM2Service.deriveQualityScore(objectiveAccuracy: 0.85, confidence: 2), equals(3));
    });

    test('accuracy 80–94%, high confidence → q=4', () {
      expect(SM2Service.deriveQualityScore(objectiveAccuracy: 0.85, confidence: 5), equals(4));
    });

    test('accuracy 95%+, low confidence → q=4', () {
      expect(SM2Service.deriveQualityScore(objectiveAccuracy: 0.97, confidence: 3), equals(4));
    });

    test('accuracy 95%+, high confidence → q=5', () {
      expect(SM2Service.deriveQualityScore(objectiveAccuracy: 1.0, confidence: 5), equals(5));
    });
  });

  // ---------------------------------------------------------------------------
  group('SM2 — flip card quality', () {
    test('"Knew it" maps confidence to q (min 2, max 5)', () {
      expect(SM2Service.flipCardQuality(knewIt: true, confidence: 1), equals(2));
      expect(SM2Service.flipCardQuality(knewIt: true, confidence: 2), equals(3));
      expect(SM2Service.flipCardQuality(knewIt: true, confidence: 3), equals(4));
      expect(SM2Service.flipCardQuality(knewIt: true, confidence: 4), equals(5));
      expect(SM2Service.flipCardQuality(knewIt: true, confidence: 5), equals(5));
    });

    test('"Didn\'t know" always → q=1', () {
      for (final c in [1, 2, 3, 4, 5]) {
        expect(SM2Service.flipCardQuality(knewIt: false, confidence: c), equals(1));
      }
    });
  });
}
