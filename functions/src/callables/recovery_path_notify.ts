import { onSchedule } from 'firebase-functions/v2/scheduler';
import { Timestamp, recoveryPathsCol } from '../lib/firestore';
import { sendPushToUsers } from '../lib/fcm';

// ── rpWeeklyCompassReminder ───────────────────────────────────────────────────
// Runs every Monday at 8:00 AM UTC. Reminds users who have completed their
// values inventory but not yet done this week's compass.

export const rpWeeklyCompassReminder = onSchedule(
  { schedule: '0 8 * * 1', timeZone: 'UTC', region: 'us-central1' },
  async () => {
    const snap = await recoveryPathsCol()
      .where('module3.valuesInventoryDone', '==', true)
      .limit(500)
      .get();

    if (snap.empty) return;

    const uids = snap.docs.map((d) => d.data()['userId'] as string).filter(Boolean);
    if (uids.length === 0) return;

    await sendPushToUsers(uids, {
      title: 'Time for your weekly values compass',
      body: 'A few minutes to check where your values compass is pointing — and choose one step forward.',
      data: { type: 'RP_WEEKLY_COMPASS', channel: 'partnerships' },
    }).catch(() => { /* non-fatal */ });
  }
);

// ── rpQuarterlyReviewReminder ─────────────────────────────────────────────────
// Runs daily. Finds paths where startedAt was exactly 90 days ago (within a
// 24-hour window) and sends a quarterly review prompt.

export const rpQuarterlyReviewReminder = onSchedule(
  { schedule: '0 11 * * *', timeZone: 'UTC', region: 'us-central1' },
  async () => {
    const now = new Date();
    const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
    const ninetyOneDaysAgo = new Date(now.getTime() - 91 * 24 * 60 * 60 * 1000);

    // Find paths started in the 90-91 day window.
    const snap = await recoveryPathsCol()
      .where('startedAt', '>=', Timestamp.fromDate(ninetyOneDaysAgo))
      .where('startedAt', '<', Timestamp.fromDate(ninetyDaysAgo))
      .limit(200)
      .get();

    if (snap.empty) return;

    const uids = snap.docs.map((d) => d.data()['userId'] as string).filter(Boolean);
    if (uids.length === 0) return;

    await sendPushToUsers(uids, {
      title: '90 days on your Recovery Path',
      body: 'Time for your quarterly review — reflect on how far you\'ve come.',
      data: { type: 'RP_QUARTERLY_REVIEW', channel: 'partnerships' },
    }).catch(() => { /* non-fatal */ });
  }
);

