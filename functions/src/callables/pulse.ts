import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue } from 'firebase-admin/firestore';
import {
  db,
  membersCol,
  weeklyPulseCol,
  pulseResponsesCol,
  Timestamp,
  weekId,
} from '../lib/firestore';
import { sendPushToUsers } from '../lib/fcm';

const VALID_PULSE_STATUSES = ['STRONG', 'STEADY', 'STRUGGLING', 'NEED_PRAYER'] as const;
type PulseStatus = typeof VALID_PULSE_STATUSES[number];

// ── circleSubmitPulseResponse ─────────────────────────────────────────────────

export const circleSubmitPulseResponse = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, status, isAnonymous = false } = request.data as {
      circleId: string;
      status: PulseStatus;
      isAnonymous?: boolean;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!VALID_PULSE_STATUSES.includes(status)) {
      throw new HttpsError('invalid-argument', 'Invalid pulse status');
    }

    const uid = request.auth.uid;

    const memberSnap = await membersCol(circleId).doc(uid).get();
    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');

    const displayName =
      (memberSnap.data()!['displayName'] as string | undefined) ?? 'Circle Member';

    const currentWeekId = weekId();
    const pulseRef = weeklyPulseCol(circleId).doc(currentWeekId);
    const responseRef = pulseResponsesCol(circleId, currentWeekId).doc(uid);

    await db.runTransaction(async (tx) => {
      const [pulseSnap, responseSnap] = await Promise.all([
        tx.get(pulseRef),
        tx.get(responseRef),
      ]);

      if (responseSnap.exists) {
        // Already submitted this week — idempotent, update in place.
        const prev = responseSnap.data()!['status'] as PulseStatus;
        if (prev === status) return; // No change needed.

        tx.update(responseRef, {
          status,
          isAnonymous,
          updatedAt: Timestamp.now(),
        });

        // Adjust pulse summary: decrement old status, increment new status.
        if (pulseSnap.exists) {
          const updates: Record<string, unknown> = {
            [`statusCounts.${status}`]: FieldValue.increment(1),
            [`statusCounts.${prev}`]: FieldValue.increment(-1),
          };
          if (status === 'NEED_PRAYER') {
            updates['needsPrayerCount'] = FieldValue.increment(1);
          }
          if (prev === 'NEED_PRAYER') {
            updates['needsPrayerCount'] = FieldValue.increment(-1);
          }
          tx.update(pulseRef, updates);
        }
        return;
      }

      // First submission this week.
      tx.set(responseRef, {
        id: uid,
        userId: uid,
        displayName,
        isAnonymous,
        status,
        createdAt: Timestamp.now(),
      });

      if (pulseSnap.exists) {
        const updates: Record<string, unknown> = {
          responseCount: FieldValue.increment(1),
          [`statusCounts.${status}`]: FieldValue.increment(1),
        };
        if (status === 'NEED_PRAYER') {
          updates['needsPrayerCount'] = FieldValue.increment(1);
        }
        tx.update(pulseRef, updates);
      } else {
        // Seed the pulse summary document.
        tx.set(pulseRef, {
          id: currentWeekId,
          circleId,
          weekId: currentWeekId,
          responseCount: 1,
          statusCounts: {
            STRONG: status === 'STRONG' ? 1 : 0,
            STEADY: status === 'STEADY' ? 1 : 0,
            STRUGGLING: status === 'STRUGGLING' ? 1 : 0,
            NEED_PRAYER: status === 'NEED_PRAYER' ? 1 : 0,
          },
          needsPrayerCount: status === 'NEED_PRAYER' ? 1 : 0,
          createdAt: Timestamp.now(),
        });
      }
    });

    return { weekId: currentWeekId };
  }
);

// ── circleGetPulseResponses ───────────────────────────────────────────────────
// Returns responses for the current week. Anonymous responses have userId and
// displayName masked before returning to the client.

export const circleGetPulseResponses = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, pulseWeekId } = request.data as {
      circleId: string;
      pulseWeekId?: string;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');

    const uid = request.auth.uid;

    const memberSnap = await membersCol(circleId).doc(uid).get();
    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');

    const targetWeekId = pulseWeekId?.trim() || weekId();

    const [pulseSnap, responsesSnap] = await Promise.all([
      weeklyPulseCol(circleId).doc(targetWeekId).get(),
      pulseResponsesCol(circleId, targetWeekId).get(),
    ]);

    const pulseSummary = pulseSnap.exists
      ? {
          id: pulseSnap.data()!['id'],
          weekId: pulseSnap.data()!['weekId'],
          responseCount: pulseSnap.data()!['responseCount'],
          statusCounts: pulseSnap.data()!['statusCounts'],
          needsPrayerCount: pulseSnap.data()!['needsPrayerCount'],
        }
      : null;

    const responses = responsesSnap.docs.map((doc) => {
      const d = doc.data();
      const isAnon = d['isAnonymous'] as boolean;
      return {
        id: d['id'],
        // Privacy: mask identity for anonymous responses.
        userId: isAnon ? null : d['userId'],
        displayName: isAnon ? null : d['displayName'],
        isAnonymous: isAnon,
        status: d['status'],
        createdAt: (d['createdAt'] as FirebaseFirestore.Timestamp).toMillis(),
      };
    });

    return { pulseSummary, responses };
  }
);

// ── sendPulsePrompts (scheduled Monday 08:00 UTC) ─────────────────────────────
// Sends a weekly circle check-in prompt to all circle members.

export const sendPulsePrompts = onSchedule(
  { schedule: '0 8 * * 1', timeZone: 'UTC', region: 'us-central1' },
  async () => {
    const circlesSnap = await db.collection('circles').get();
    if (circlesSnap.empty) return;

    for (const circleDoc of circlesSnap.docs) {
      const circleId = circleDoc.id;
      const circleName = (circleDoc.data()['name'] as string | undefined) ?? 'your circle';

      const membersSnap = await membersCol(circleId).get();
      const memberIds = membersSnap.docs.map((d) => d.data()['userId'] as string);

      if (memberIds.length === 0) continue;

      sendPushToUsers(memberIds, {
        title: 'How are you doing this week?',
        body: `Check in with ${circleName} — a quick pulse so they can pray for you.`,
        data: { type: 'PULSE_PROMPT', circleId },
      }).catch(() => { /* non-fatal */ });
    }
  }
);
