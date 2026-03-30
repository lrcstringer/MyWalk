import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../lib/firestore';

// ── resetWeeklyFruitPortfolio (scheduled Sunday 00:00 ET) ─────────────────────
// For each user's fruit_portfolio docs:
//   - If weeklyCompletions > 0: increment currentStreak, update longestStreak
//   - Else: reset currentStreak to 0
//   - Reset weeklyCompletions to 0

export const resetWeeklyFruitPortfolio = onSchedule(
  { schedule: '0 5 * * 0', timeZone: 'UTC', region: 'us-central1' },
  // 05:00 UTC Sunday = 00:00 ET (EST, UTC-5). Adjust to 04:00 UTC for EDT (UTC-4).
  // Using 05:00 UTC as a stable approximation for midnight ET in standard time.
  async () => {
    const usersSnap = await db.collection('users').get();
    if (usersSnap.empty) return;

    // Process in batches of 500 (Firestore batch limit).
    const BATCH_SIZE = 500;
    let batch = db.batch();
    let opCount = 0;

    const flush = async () => {
      if (opCount > 0) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    };

    for (const userDoc of usersSnap.docs) {
      const portfolioSnap = await userDoc.ref.collection('fruit_portfolio').get();
      for (const fruitDoc of portfolioSnap.docs) {
        const data = fruitDoc.data() as {
          weeklyCompletions?: number;
          currentStreak?: number;
          longestStreak?: number;
        };

        const weekly = data.weeklyCompletions ?? 0;
        const current = data.currentStreak ?? 0;
        const longest = data.longestStreak ?? 0;

        const newStreak = weekly > 0 ? current + 1 : 0;
        const newLongest = Math.max(longest, newStreak);

        batch.update(fruitDoc.ref, {
          weeklyCompletions: 0,
          currentStreak: newStreak,
          longestStreak: newLongest,
          updatedAt: FieldValue.serverTimestamp(),
        });
        opCount++;

        if (opCount >= BATCH_SIZE) {
          await flush();
        }
      }
    }

    await flush();
  }
);
