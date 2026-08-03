import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import {
  db,
  membersCol,
  encouragementsCol,
  userNotificationsCol,
  Timestamp,
} from '../lib/firestore';
import { sendPushToUsers } from '../lib/fcm';

const VALID_TYPES = ['PRAYING', 'THINKING', 'PROUD', 'KEEP_GOING', 'GOD_SEES', 'NOT_ALONE', 'STRENGTH', 'GRATEFUL'] as const;
type EncouragementType = typeof VALID_TYPES[number];

const TYPE_PRESET_TEXT: Record<EncouragementType, string> = {
  PRAYING: 'Praying for you today.',
  THINKING: "Just wanted you to know I'm thinking of you.",
  PROUD: 'Proud of you.',
  KEEP_GOING: "Keep going — you're doing great.",
  GOD_SEES: 'God sees your faithfulness.',
  NOT_ALONE: "You're not walking alone.",
  STRENGTH: 'Praying God gives you strength today.',
  GRATEFUL: 'Grateful to be in community with you.',
};

// ── circleSendEncouragement ────────────────────────────────────────────────────

export const circleSendEncouragement = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, recipientId, type, customMessage, isAnonymous = false, notifyViaInbox = false } =
      request.data as {
        circleId: string;
        recipientId: string;
        type: EncouragementType;
        customMessage?: string;
        isAnonymous?: boolean;
        notifyViaInbox?: boolean;
      };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!recipientId?.trim()) throw new HttpsError('invalid-argument', 'recipientId required');
    if (type && !VALID_TYPES.includes(type)) throw new HttpsError('invalid-argument', 'Invalid encouragement type');
    if (!type && !customMessage?.trim()) throw new HttpsError('invalid-argument', 'Either a preset type or a custom message is required');
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

    const senderLabel = isAnonymous ? 'Someone in your circle' : senderDisplayName;
    const body = customMessage?.trim()
      ? `${senderLabel}: ${customMessage.trim()}`
      : `${senderLabel}: ${type ? TYPE_PRESET_TEXT[type] : ''}`;

    if (notifyViaInbox) {
      const circleSnap = await db.collection('circles').doc(circleId).get();
      const circleName = (circleSnap.data()?.['name'] as string | undefined) ?? 'Your circle';
      const notifId = crypto.randomUUID();
      const now2 = Timestamp.now();
      const exp = Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000));
      await userNotificationsCol(recipientId).doc(notifId).set({
        id: notifId,
        type: 'encouragement',
        circleId,
        circleName,
        senderUid: uid,
        senderName: senderLabel,
        message: body,
        createdAt: now2,
        expiresAt: exp,
        isRead: false,
        actionTaken: null,
        suppressActions: false,
        sourceId: ref.id,
      });
    }

    await sendPushToUsers([recipientId], {
      title: 'Encouragement from your group',
      body,
      data: { type: 'encouragement', circleId },
      channelId: 'circles',
    }).catch(() => {});

    return { id: ref.id };
  }
);

// ── circleGetEncouragements ────────────────────────────────────────────────────
// Returns encouragements for the caller. type='received' (default) returns
// messages where the caller is the recipient; type='sent' returns messages
// where the caller is the sender. Anonymous sender identity is masked only
// for received messages — the sender always knows they sent it.

export const circleGetEncouragements = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, type = 'received' } = request.data as { circleId: string; type?: string };
    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');

    const uid = request.auth.uid;

    const memberSnap = await membersCol(circleId).doc(uid).get();
    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');

    const isSent = type === 'sent';
    const snap = await encouragementsCol(circleId)
      .where(isSent ? 'senderId' : 'recipientId', '==', uid)
      .orderBy('createdAt', 'desc')
      .limit(50)
      .get();

    const encouragements = snap.docs.map((doc) => {
      const d = doc.data();
      const isAnon = d['isAnonymous'] as boolean;
      // Mask sender identity only for received anonymous messages.
      const maskSender = !isSent && isAnon;
      return {
        id: d['id'],
        circleId: d['circleId'],
        senderId: maskSender ? null : d['senderId'],
        senderDisplayName: maskSender ? null : d['senderDisplayName'],
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
