import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import {
  membersCol,
  milestoneSharesCol,
  Timestamp,
} from '../lib/firestore';
import { sendPushToUsers } from '../lib/fcm';

// ── circleShareMilestone ───────────────────────────────────────────────────────

export const circleShareMilestone = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, milestoneType, value, unit, habitName } = request.data as {
      circleId: string;
      milestoneType: 'TIME' | 'COUNT' | 'DAYS' | 'CONSECUTIVE';
      value: number;
      unit: string;
      habitName: string;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!['TIME', 'COUNT', 'DAYS', 'CONSECUTIVE'].includes(milestoneType)) {
      throw new HttpsError('invalid-argument', 'Invalid milestoneType');
    }
    if (typeof value !== 'number' || value <= 0) {
      throw new HttpsError('invalid-argument', 'value must be a positive number');
    }
    if (!unit?.trim()) throw new HttpsError('invalid-argument', 'unit required');
    if (!habitName?.trim()) throw new HttpsError('invalid-argument', 'habitName required');

    const uid = request.auth.uid;

    const memberSnap = await membersCol(circleId).doc(uid).get();
    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');

    const displayName =
      (memberSnap.data()!['displayName'] as string | undefined) ?? 'Circle Member';

    const ref = milestoneSharesCol(circleId).doc();
    await ref.set({
      id: ref.id,
      circleId,
      userId: uid,
      displayName,
      milestoneType,
      value,
      unit: unit.trim(),
      habitName: habitName.trim(),
      celebratedByUserIds: [],
      celebrationCount: 0,
      createdAt: Timestamp.now(),
    });

    // Notify all other circle members (non-fatal).
    const membersSnap = await membersCol(circleId).get();
    const otherIds = membersSnap.docs
      .map((d) => d.data()['userId'] as string)
      .filter((id) => id !== uid);

    if (otherIds.length > 0) {
      const label = _milestoneLabel(milestoneType, value, unit, habitName);
      sendPushToUsers(otherIds, {
        title: `${displayName} hit a milestone!`,
        body: label,
        data: { type: 'MILESTONE_SHARED', circleId, shareId: ref.id },
      }).catch(() => { /* non-fatal */ });
    }

    return { id: ref.id };
  }
);

// ── circleCelebrateMilestone ───────────────────────────────────────────────────

export const circleCelebrateMilestone = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, shareId } = request.data as {
      circleId: string;
      shareId: string;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!shareId?.trim()) throw new HttpsError('invalid-argument', 'shareId required');

    const uid = request.auth.uid;

    const memberSnap = await membersCol(circleId).doc(uid).get();
    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');

    const ref = milestoneSharesCol(circleId).doc(shareId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError('not-found', 'Milestone share not found');

    const data = snap.data()!;

    // Cannot celebrate your own milestone.
    if (data['userId'] === uid) {
      throw new HttpsError('invalid-argument', 'Cannot celebrate your own milestone');
    }

    // Idempotent: do nothing if already celebrated.
    if ((data['celebratedByUserIds'] as string[]).includes(uid)) {
      return { success: true };
    }

    await ref.update({
      celebratedByUserIds: FieldValue.arrayUnion(uid),
      celebrationCount: FieldValue.increment(1),
    });

    return { success: true };
  }
);

// ── batchCelebrationNotifications (Firestore trigger) ─────────────────────────
// Fires when celebrationCount increases. Notifies the milestone owner.

export const batchCelebrationNotifications = onDocumentUpdated(
  {
    document: 'circles/{circleId}/milestone_shares/{shareId}',
    region: 'us-central1',
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const prevCount = before['celebrationCount'] as number;
    const newCount = after['celebrationCount'] as number;

    // Only notify on meaningful milestones (1st, 5th, 10th celebration).
    const NOTIFY_AT = [1, 5, 10];
    if (!NOTIFY_AT.includes(newCount) || newCount <= prevCount) return;

    const ownerId = after['userId'] as string;
    const celebratedCount = newCount;
    const habitName = after['habitName'] as string;
    const circleId = event.params['circleId'];

    const body =
      celebratedCount === 1
        ? `Someone in your circle celebrated your ${habitName} milestone!`
        : `${celebratedCount} people in your circle celebrated your ${habitName} milestone!`;

    sendPushToUsers([ownerId], {
      title: 'Your circle is celebrating you!',
      body,
      data: { type: 'MILESTONE_CELEBRATED', circleId, shareId: event.params['shareId'] },
    }).catch(() => { /* non-fatal */ });
  }
);

// ── Internal helpers ──────────────────────────────────────────────────────────

function _milestoneLabel(
  type: string,
  value: number,
  unit: string,
  habitName: string
): string {
  switch (type) {
    case 'CONSECUTIVE':
      return `${value} ${unit} in a row with ${habitName}`;
    case 'DAYS':
      return `${value} ${unit} of ${habitName}`;
    case 'TIME':
      return `${value} ${unit} given to ${habitName}`;
    case 'COUNT':
      return `${value} ${unit} reached for ${habitName}`;
    default:
      return `${value} ${unit} milestone for ${habitName}`;
  }
}
