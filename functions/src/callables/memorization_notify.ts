import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, Timestamp } from '../lib/firestore';
import { sendPushToUsers } from '../lib/fcm';

// ── scheduleReviewReminder ────────────────────────────────────────────────────
// Called by the Flutter client when an item's nextReviewDate is set.
// Writes a pending notification doc to /scheduledNotifications/{itemId}_{uid}
// so the sweeper can pick it up. Also fires FCM immediately if overdue.

export const scheduleReviewReminder = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { itemId, itemTitle, dueAt } = request.data as {
      itemId: string;
      itemTitle: string;
      dueAt: string; // ISO 8601
    };

    if (!itemId?.trim()) throw new HttpsError('invalid-argument', 'itemId required');
    if (!itemTitle?.trim()) throw new HttpsError('invalid-argument', 'itemTitle required');
    if (!dueAt?.trim()) throw new HttpsError('invalid-argument', 'dueAt required');

    const uid = request.auth.uid;
    const dueDate = new Date(dueAt);

    if (isNaN(dueDate.getTime())) {
      throw new HttpsError('invalid-argument', 'dueAt must be a valid ISO 8601 date');
    }

    const docId = `${uid}_${itemId}`;

    // Upsert: overwrite any existing reminder for this item.
    await db.collection('scheduledNotifications').doc(docId).set({
      uid,
      itemId,
      itemTitle,
      dueAt: Timestamp.fromDate(dueDate),
      sent: false,
      createdAt: Timestamp.now(),
    });

    // If already due, fire FCM immediately rather than waiting for the sweeper.
    if (dueDate <= new Date()) {
      await _sendReviewPush(uid, itemTitle);
      await db.collection('scheduledNotifications').doc(docId).update({ sent: true });
    }

    return { ok: true };
  }
);

// ── cancelReviewReminder ──────────────────────────────────────────────────────
// Called when an item is archived or deleted.

export const cancelReviewReminder = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { itemId } = request.data as { itemId: string };
    if (!itemId?.trim()) throw new HttpsError('invalid-argument', 'itemId required');

    const docId = `${request.auth.uid}_${itemId}`;
    await db.collection('scheduledNotifications').doc(docId).delete();

    return { ok: true };
  }
);

// ── sweepDueReminders ─────────────────────────────────────────────────────────
// Runs every 30 minutes. Queries all unsent notifications whose dueAt has passed
// and sends FCM to each user.

export const sweepDueReminders = onSchedule(
  { schedule: 'every 30 minutes', region: 'us-central1', memory: '256MiB' },
  async () => {
    const now = Timestamp.now();

    const due = await db
      .collection('scheduledNotifications')
      .where('sent', '==', false)
      .where('dueAt', '<=', now)
      .limit(200)
      .get();

    if (due.empty) return;

    const batch = db.batch();
    const pushJobs: Promise<void>[] = [];

    for (const doc of due.docs) {
      const { uid, itemTitle } = doc.data() as { uid: string; itemTitle: string };
      pushJobs.push(_sendReviewPush(uid, itemTitle).catch(() => undefined));
      batch.update(doc.ref, { sent: true, sentAt: Timestamp.now() });
    }

    await Promise.all([...pushJobs, batch.commit()]);
  }
);

// ── helper ────────────────────────────────────────────────────────────────────

async function _sendReviewPush(uid: string, itemTitle: string): Promise<void> {
  await sendPushToUsers([uid], {
    title: `Time to review: ${itemTitle}`,
    body: '"Thy word have I hid in mine heart…" — Psalm 119:11',
    data: { screen: 'memorization' },
    channelId: 'memorization_reviews',
  });
}
