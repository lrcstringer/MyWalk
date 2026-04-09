import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { partnershipsCol, usersCol, userNotificationsCol, Timestamp } from '../lib/firestore';
import { sendPushToUsers } from '../lib/fcm';

// ── accountabilityCreateInvite ────────────────────────────────────────────────

export const accountabilityCreateInvite = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
    const uid = request.auth.uid;
    const { habitId, habitName, ownerDisplayName, recipientEmail } = request.data as {
      habitId: string;
      habitName: string;
      ownerDisplayName: string;
      recipientEmail?: string;
    };
    if (!habitId?.trim()) throw new HttpsError('invalid-argument', 'habitId is required');

    // Block if an active partnership already exists for this habit.
    const activeSnap = await partnershipsCol()
      .where('ownerId', '==', uid)
      .where('habitId', '==', habitId)
      .where('status', '==', 'active')
      .limit(1)
      .get();
    if (!activeSnap.empty) {
      throw new HttpsError('failed-precondition', 'An active partnership already exists for this habit');
    }

    // Cancel any existing pending partnership for this habit before creating a new one.
    const existing = await partnershipsCol()
      .where('ownerId', '==', uid)
      .where('habitId', '==', habitId)
      .where('status', '==', 'pending')
      .limit(1)
      .get();
    if (!existing.empty) {
      await existing.docs[0].ref.update({ status: 'cancelled' });
    }

    const token = crypto.randomUUID();
    const partnershipId = crypto.randomUUID();
    // Short code: first 6 chars of token (uppercased, hyphens removed) for manual entry.
    const shortCode = token.replace(/-/g, '').substring(0, 6).toUpperCase();
    const now = Timestamp.now();

    await partnershipsCol().doc(partnershipId).set({
      id: partnershipId,
      ownerId: uid,
      ownerDisplayName: ownerDisplayName ?? '',
      habitId,
      habitName: habitName ?? '',
      status: 'pending',
      inviteToken: token,
      shortCode,
      participantIds: [uid],
      createdAt: now,
    });

    // If a recipient email was provided, look up whether they have a MyWalk account
    // and write a partnership_invite notification directly to their inbox.
    let inAppSent = false;
    if (recipientEmail?.trim()) {
      try {
        const recipientRecord = await getAuth().getUserByEmail(recipientEmail.trim());
        const recipientUid = recipientRecord.uid;
        if (recipientUid !== uid) {
          const notifId = crypto.randomUUID();
          await userNotificationsCol(recipientUid).doc(notifId).set({
            id: notifId,
            type: 'partnership_invite',
            senderUid: uid,
            senderName: ownerDisplayName ?? '',
            circleId: partnershipId,
            circleName: habitName ?? '',
            message: `${ownerDisplayName ?? 'Someone'} wants you to be their support/prayer partner for "${habitName ?? 'a habit'}"`,
            partnerInviteToken: token,
            isRead: false,
            suppressActions: false,
            createdAt: now,
          });
          inAppSent = true;
          // Also send a push nudge so the notification bell lights up.
          sendPushToUsers([recipientUid], {
            title: `${ownerDisplayName ?? 'Someone'} invited you to walk with them`,
            body: `Open MyWalk to accept their support partner request.`,
            data: { type: 'partnership_invite', partnershipId, channel: 'partnerships' },
            channelId: 'partnerships',
          }).catch(() => {});
        }
      } catch (_) {
        // User not found — fall through to link-only flow.
      }
    }

    return {
      partnershipId,
      shareUrl: `https://mywalk.faith/accountability/accept/${token}`,
      shortCode,
      inAppSent,
    };
  }
);

// ── accountabilityAcceptInvite ────────────────────────────────────────────────

export const accountabilityAcceptInvite = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
    const uid = request.auth.uid;
    const { token, partnerDisplayName } = request.data as {
      token: string;
      partnerDisplayName: string;
    };
    if (!token?.trim()) throw new HttpsError('invalid-argument', 'token is required');

    const snap = await partnershipsCol()
      .where('inviteToken', '==', token)
      .where('status', '==', 'pending')
      .limit(1)
      .get();

    if (snap.empty) {
      throw new HttpsError('not-found', 'Invite not found or already used');
    }

    const doc = snap.docs[0];
    const data = doc.data();

    if (data.ownerId === uid) {
      throw new HttpsError('failed-precondition', 'You cannot accept your own invite');
    }

    const now = Timestamp.now();
    await doc.ref.update({
      status: 'active',
      partnerId: uid,
      partnerDisplayName: partnerDisplayName ?? '',
      participantIds: FieldValue.arrayUnion(uid),
      acceptedAt: now,
    });

    // Notify the owner.
    sendPushToUsers([data.ownerId], {
      title: `${partnerDisplayName ?? 'Someone'} accepted your invite`,
      body: `You're now walking together on "${data.habitName}".`,
      data: { type: 'partnership_accepted', partnershipId: doc.id, channel: 'partnerships' },
      channelId: 'partnerships',
    }).catch(() => {});

    return { partnershipId: doc.id };
  }
);

// ── accountabilityDeclineInvite ───────────────────────────────────────────────

export const accountabilityDeclineInvite = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
    const uid = request.auth.uid;
    const { token } = request.data as { token: string };

    const snap = await partnershipsCol()
      .where('inviteToken', '==', token)
      .where('status', '==', 'pending')
      .limit(1)
      .get();

    if (snap.empty) throw new HttpsError('not-found', 'Invite not found');

    const doc = snap.docs[0];
    if (doc.data().ownerId === uid) {
      throw new HttpsError('failed-precondition', 'Owner should use cancel, not decline');
    }

    await doc.ref.update({ status: 'declined' });

    // Notify the owner.
    sendPushToUsers([doc.data().ownerId], {
      title: 'Partner invite declined',
      body: 'Your support partner invite was not accepted.',
      data: { type: 'partnership_declined', partnershipId: doc.id, channel: 'partnerships' },
      channelId: 'partnerships',
    }).catch(() => {});

    return { success: true };
  }
);

// ── accountabilityNotifyParticipant ───────────────────────────────────────────

export const accountabilityNotifyParticipant = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
    const uid = request.auth.uid;
    const { partnershipId, messagePreview } = request.data as {
      partnershipId: string;
      messagePreview: string;
    };

    const doc = await partnershipsCol().doc(partnershipId).get();
    if (!doc.exists) throw new HttpsError('not-found', 'Partnership not found');

    const data = doc.data()!;
    if (!data.participantIds.includes(uid)) {
      throw new HttpsError('permission-denied', 'Not a participant');
    }

    // Send to the other participant only.
    const recipientId = data.ownerId === uid ? data.partnerId : data.ownerId;
    if (!recipientId) return { sent: false };

    const senderSnap = await usersCol().doc(uid).get();
    const senderName = (senderSnap.data()?.displayName as string | undefined) ?? 'Your partner';

    await sendPushToUsers([recipientId], {
      title: senderName,
      body: messagePreview,
      data: { type: 'partner_message', partnershipId, channel: 'partnerships' },
      channelId: 'partnerships',
    });

    return { sent: true };
  }
);
