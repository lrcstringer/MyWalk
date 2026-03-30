import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import {
  db,
  membersCol,
  encouragementsCol,
  Timestamp,
} from '../lib/firestore';
import { sendPushToUsers } from '../lib/fcm';

const VALID_TYPES = ['PRAYING', 'THINKING_OF_YOU', 'PROUD_OF_YOU', 'KEEP_GOING', 'GOD_SEES_YOU'] as const;
type EncouragementType = typeof VALID_TYPES[number];

const TYPE_PRESET_TEXT: Record<EncouragementType, string> = {
  PRAYING: 'Praying for you today.',
  THINKING_OF_YOU: 'Thinking of you today.',
  PROUD_OF_YOU: 'Proud of you.',
  KEEP_GOING: 'Keep going.',
  GOD_SEES_YOU: 'God sees every one.',
};

// ── circleSendEncouragement ────────────────────────────────────────────────────

export const circleSendEncouragement = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, recipientId, type, customMessage, isAnonymous = false } =
      request.data as {
        circleId: string;
        recipientId: string;
        type: EncouragementType;
        customMessage?: string;
        isAnonymous?: boolean;
      };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!recipientId?.trim()) throw new HttpsError('invalid-argument', 'recipientId required');
    if (!VALID_TYPES.includes(type)) throw new HttpsError('invalid-argument', 'Invalid encouragement type');
    if (customMessage && customMessage.length > 200) {
      throw new HttpsError('invalid-argument', 'customMessage exceeds 200 characters');
    }

    const uid = request.auth.uid;

    if (uid === recipientId) {
      throw new HttpsError('invalid-argument', 'Cannot send encouragement to yourself');
    }

    // Verify sender is a member.
    const [senderSnap, recipientSnap] = await Promise.all([
      membersCol(circleId).doc(uid).get(),
      membersCol(circleId).doc(recipientId).get(),
    ]);
    if (!senderSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');
    if (!recipientSnap.exists) throw new HttpsError('not-found', 'Recipient is not a member of this circle');

    const senderDisplayName =
      (senderSnap.data()!['displayName'] as string | undefined) ?? 'Circle Member';
    const recipientDisplayName =
      (recipientSnap.data()!['displayName'] as string | undefined) ?? 'Circle Member';

    const ref = encouragementsCol(circleId).doc();
    await ref.set({
      id: ref.id,
      circleId,
      senderId: uid,
      senderDisplayName,
      isAnonymous,
      type,
      customMessage: customMessage?.trim() ?? null,
      recipientId,
      recipientDisplayName,
      isRead: false,
      createdAt: Timestamp.now(),
    });

    // Notify recipient (non-fatal).
    const senderLabel = isAnonymous ? 'Someone in your circle' : senderDisplayName;
    const body = customMessage?.trim()
      ? `${senderLabel}: ${customMessage.trim()}`
      : `${senderLabel}: ${TYPE_PRESET_TEXT[type]}`;
    sendPushToUsers([recipientId], {
      title: 'Encouragement from your circle',
      body,
      data: { type: 'ENCOURAGEMENT', circleId, encouragementId: ref.id },
    }).catch(() => { /* non-fatal */ });

    return { id: ref.id };
  }
);

// ── circleGetEncouragements ────────────────────────────────────────────────────
// Returns encouragements received by the caller. Anonymous messages have
// senderId and senderDisplayName masked before returning to the client.

export const circleGetEncouragements = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId } = request.data as { circleId: string };
    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');

    const uid = request.auth.uid;

    const memberSnap = await membersCol(circleId).doc(uid).get();
    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');

    const snap = await encouragementsCol(circleId)
      .where('recipientId', '==', uid)
      .orderBy('createdAt', 'desc')
      .limit(50)
      .get();

    const encouragements = snap.docs.map((doc) => {
      const d = doc.data();
      const isAnon = d['isAnonymous'] as boolean;
      return {
        id: d['id'],
        circleId: d['circleId'],
        // Privacy: mask identity for anonymous senders.
        senderId: isAnon ? null : d['senderId'],
        senderDisplayName: isAnon ? null : d['senderDisplayName'],
        isAnonymous: isAnon,
        type: d['type'],
        customMessage: d['customMessage'],
        recipientId: d['recipientId'],
        recipientDisplayName: d['recipientDisplayName'],
        isRead: d['isRead'],
        createdAt: (d['createdAt'] as FirebaseFirestore.Timestamp).toMillis(),
      };
    });

    return { encouragements };
  }
);

// ── circleMarkEncouragementRead ───────────────────────────────────────────────

export const circleMarkEncouragementRead = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, encouragementId } = request.data as {
      circleId: string;
      encouragementId: string;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!encouragementId?.trim()) throw new HttpsError('invalid-argument', 'encouragementId required');

    const uid = request.auth.uid;

    const ref = encouragementsCol(circleId).doc(encouragementId);
    const snap = await ref.get();

    if (!snap.exists) throw new HttpsError('not-found', 'Encouragement not found');
    if (snap.data()!['recipientId'] !== uid) {
      throw new HttpsError('permission-denied', 'Not the recipient of this encouragement');
    }
    if (snap.data()!['isRead'] === true) {
      return { success: true }; // Idempotent.
    }

    await ref.update({ isRead: true });
    return { success: true };
  }
);

// ── sendEncouragementPrompts (scheduled Sunday 18:00 UTC) ─────────────────────
// Nudges active circle members who haven't sent an encouragement this week.

export const sendEncouragementPrompts = onSchedule(
  { schedule: '0 18 * * 0', timeZone: 'UTC', region: 'us-central1' },
  async () => {
    // Find all circles with at least one member.
    const circlesSnap = await db.collection('circles').get();
    if (circlesSnap.empty) return;

    // For each circle, find members who haven't sent anything this week.
    // A lightweight proxy: we just notify all members (personalised prompts
    // would require per-circle sent-this-week tracking which doesn't exist).
    // Future enhancement: filter by sent_this_week flag.
    for (const circleDoc of circlesSnap.docs) {
      const circleId = circleDoc.id;
      const circleName = (circleDoc.data()['name'] as string | undefined) ?? 'your circle';

      const membersSnap = await membersCol(circleId).get();
      const memberIds = membersSnap.docs.map((d) => d.data()['userId'] as string);

      if (memberIds.length < 2) continue; // No one to encourage if only 1 member.

      sendPushToUsers(memberIds, {
        title: 'Encourage someone today',
        body: `Someone in ${circleName} could use a word of encouragement this Sunday.`,
        data: { type: 'ENCOURAGEMENT_PROMPT', circleId },
      }).catch(() => { /* non-fatal */ });
    }
  }
);
