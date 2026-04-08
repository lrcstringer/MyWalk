import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { Timestamp, recoveryPathsCol, usersCol } from '../lib/firestore';
import { sendPushToUsers } from '../lib/fcm';

// ── rpDailyCheckInReminder ────────────────────────────────────────────────────
// Runs daily at 9:00 AM UTC. Finds all active recovery paths where the user
// has not done a check-in today and sends a gentle reminder.

export const rpDailyCheckInReminder = onSchedule(
  { schedule: '0 9 * * *', timeZone: 'UTC', region: 'us-central1' },
  async () => {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // Paths where lastCheckInAt is before today (or null).
    const snap = await recoveryPathsCol()
      .where('module1.lastCheckInAt', '<', Timestamp.fromDate(startOfToday))
      .limit(500)
      .get();

    if (snap.empty) return;

    const uids = snap.docs.map((d) => d.data()['userId'] as string).filter(Boolean);
    if (uids.length === 0) return;

    await sendPushToUsers(uids, {
      title: 'Your daily check-in is waiting',
      body: 'A few minutes of reflection keeps your streak going — tap to continue.',
      data: { type: 'RP_DAILY_REMINDER', channel: 'partnerships' },
    }).catch(() => { /* non-fatal */ });
  }
);

// ── rpMissed3DaysReminder ─────────────────────────────────────────────────────
// Runs daily. Finds paths where the last check-in was more than 3 days ago
// and sends a compassionate re-engagement nudge.

export const rpMissed3DaysReminder = onSchedule(
  { schedule: '0 10 * * *', timeZone: 'UTC', region: 'us-central1' },
  async () => {
    const now = new Date();
    const threeDaysAgo = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);

    const snap = await recoveryPathsCol()
      .where('module1.lastCheckInAt', '<', Timestamp.fromDate(threeDaysAgo))
      .limit(500)
      .get();

    if (snap.empty) return;

    // Exclude paths started within the last 3 days: their lastCheckInAt is the
    // epoch sentinel (set on creation) so they pass the < filter above, but the
    // user has simply never had a chance to check in yet.
    const uids = snap.docs
      .filter((d) => {
        const startedAt = (d.data()['startedAt'] as Timestamp | undefined)?.toDate();
        return startedAt != null && startedAt < threeDaysAgo;
      })
      .map((d) => d.data()['userId'] as string)
      .filter(Boolean);
    if (uids.length === 0) return;

    await sendPushToUsers(uids, {
      title: 'It\'s been a few days',
      body: 'Recovery isn\'t about a streak — it\'s about coming back. A check-in takes 2 minutes.',
      data: { type: 'RP_MISSED_3_DAYS', channel: 'partnerships' },
    }).catch(() => { /* non-fatal */ });
  }
);

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
      body: 'A quick 3-question check-in to keep your values front and centre.',
      data: { type: 'RP_WEEKLY_COMPASS', channel: 'partnerships' },
    }).catch(() => { /* non-fatal */ });
  }
);

// ── rpLapseUnlocksM5 ──────────────────────────────────────────────────────────
// Firestore trigger: fires when a new recovery session is created with
// sessionType == 'lapseRecord'. Notifies the user that Module 5 is now unlocked.

export const rpLapseUnlocksM5 = onDocumentCreated(
  {
    document: 'recovery_paths/{habitId}/recovery_sessions/{sessionId}',
    region: 'us-central1',
  },
  async (event) => {
    const session = event.data?.data();
    if (!session) return;
    if (session['sessionType'] !== 'lapseRecord') return;

    const habitId = event.params['habitId'];
    const pathDoc = await recoveryPathsCol().doc(habitId).get();
    if (!pathDoc.exists) return;

    const uid = pathDoc.data()!['userId'] as string | undefined;
    if (!uid) return;

    // Only notify on the first lapse. The CF fires when the session doc is
    // created; at that point updatePath() may not yet have incremented
    // totalLapses. So on the first lapse totalLapses reads 0; on any
    // subsequent lapse it reads >= 1. Guard with >= 1 to avoid re-notifying.
    const totalLapses = (pathDoc.data()!['totalLapses'] as number | undefined) ?? 0;
    if (totalLapses >= 1) return; // already notified on first lapse

    // Fetch user's FCM token via the users collection.
    const userDoc = await usersCol().doc(uid).get();
    const fcmToken = userDoc.data()?.['fcmToken'] as string | undefined;
    if (!fcmToken) return;

    await sendPushToUsers([uid], {
      title: 'Module 5 is unlocked',
      body: 'Navigate Lapses is now available on your Recovery Path. You\'re not alone.',
      data: { type: 'RP_M5_UNLOCKED', channel: 'partnerships' },
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

// ── rpM2UnlockReminder ────────────────────────────────────────────────────────
// Runs daily. Finds paths where phase >= 2 (module1.dailyCheckInCount >= 7)
// and sends a one-time notification that M2 is available.
// Uses a sentinel field 'm2NotifSent' on the path doc to avoid repeat sends.

export const rpM2UnlockReminder = onSchedule(
  { schedule: '30 9 * * *', timeZone: 'UTC', region: 'us-central1' },
  async () => {
    const snap = await recoveryPathsCol()
      .where('module1.dailyCheckInCount', '>=', 7)
      .where('m2NotifSent', '==', false)
      .limit(200)
      .get();

    if (snap.empty) return;

    const batch = recoveryPathsCol().firestore.batch();
    const uids: string[] = [];

    for (const doc of snap.docs) {
      const uid = doc.data()['userId'] as string | undefined;
      if (uid) uids.push(uid);
      batch.update(doc.ref, { m2NotifSent: true });
    }

    if (uids.length > 0) {
      await sendPushToUsers(uids, {
        title: 'Module 2 is unlocked',
        body: 'Challenge Your Thinking is now available — a powerful next step.',
        data: { type: 'RP_M2_UNLOCKED', channel: 'partnerships' },
      }).catch(() => { /* non-fatal */ });
    }

    await batch.commit();
  }
);
