import * as z from 'zod';
import { TRPCError } from '@trpc/server';
import { createTRPCRouter, protectedProcedure } from '../create-context';
import {
  db,
  membersCol,
  circlesCol,
  userNotificationsCol,
  Timestamp,
} from '../../lib/firestore';

const NOTIFICATION_TTL_DAYS = 30;

function expiresAt(): FirebaseFirestore.Timestamp {
  const d = new Date();
  d.setDate(d.getDate() + NOTIFICATION_TTL_DAYS);
  return Timestamp.fromDate(d);
}

// ── Helper: resolve all member UIDs of a circle ───────────────────────────────

async function getCircleMemberIds(circleId: string): Promise<string[]> {
  const snap = await membersCol(circleId).get();
  return snap.docs.map((d) => d.id);
}

// ── Helper: resolve display name for the caller ───────────────────────────────

async function getSenderName(uid: string): Promise<string> {
  const doc = await db.collection('users').doc(uid).get();
  return (doc.data()?.displayName as string | undefined) ?? 'A circle member';
}

// ── Helper: get circle name ───────────────────────────────────────────────────

async function getCircleName(circleId: string): Promise<string> {
  const doc = await circlesCol().doc(circleId).get();
  return (doc.data()?.name as string | undefined) ?? 'Your circle';
}

// ── Helper: write a notification doc to each recipient's inbox ────────────────

async function fanOutNotifications(
  recipientIds: string[],
  payload: {
    type: 'sos' | 'prayer_request' | 'announcement' | 'event' | 'group_activity' | 'encouragement';
    circleId: string;
    circleName: string;
    senderUid: string;
    senderName: string;
    message: string;
    suppressActions: boolean;
    sourceId?: string;
  }
): Promise<string> {
  const notifId = crypto.randomUUID();
  const now = Timestamp.now();
  const exp = expiresAt();

  // Use a batch for atomicity. Firestore batch limit is 500 ops;
  // the sendPrayerRequest cap of 50 and the member-count guard keep us well under it.
  const batch = db.batch();
  for (const uid of recipientIds) {
    const doc: Record<string, unknown> = {
      id: notifId,
      type: payload.type,
      circleId: payload.circleId,
      circleName: payload.circleName,
      senderUid: payload.senderUid,
      senderName: payload.senderName,
      message: payload.message,
      createdAt: now,
      expiresAt: exp,
      isRead: false,
      actionTaken: null,
      suppressActions: payload.suppressActions,
    };
    if (payload.sourceId) doc.sourceId = payload.sourceId;
    batch.set(userNotificationsCol(uid).doc(notifId), doc);
  }
  await batch.commit();
  return notifId;
}

// ── Router ────────────────────────────────────────────────────────────────────

export const notificationsRouter = createTRPCRouter({

  // Send a circle announcement (admin only)
  sendAnnouncement: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        message: z.string().min(1).max(500),
        notifType: z.enum(['announcement', 'event', 'group_activity']).optional(),
        sourceId: z.string().optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const memberDoc = await membersCol(input.circleId).doc(ctx.userId).get();
      if (!memberDoc.exists) throw new TRPCError({ code: 'FORBIDDEN', message: 'Not a member' });
      const role = memberDoc.data()?.role as string | undefined;
      if (role !== 'admin') throw new TRPCError({ code: 'FORBIDDEN', message: 'Admins only' });

      const [memberIds, senderName, circleName] = await Promise.all([
        getCircleMemberIds(input.circleId),
        getSenderName(ctx.userId),
        getCircleName(input.circleId),
      ]);

      const recipients = memberIds.filter((id) => id !== ctx.userId);

      const notifType = input.notifType ?? 'announcement';

      const notifId = await fanOutNotifications(recipients, {
        type: notifType,
        circleId: input.circleId,
        circleName,
        senderUid: ctx.userId,
        senderName,
        message: input.message,
        suppressActions: false,
        sourceId: input.sourceId,
      });

      return { notifId, recipientCount: recipients.length };
    }),

  // Send a help/prayer request (any member, to chosen recipients)
  sendPrayerRequest: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        message: z.string().min(1).max(500),
        recipientIds: z.array(z.string()).min(1).max(50),
        notifyViaInbox: z.boolean().optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const memberDoc = await membersCol(input.circleId).doc(ctx.userId).get();
      if (!memberDoc.exists) throw new TRPCError({ code: 'FORBIDDEN', message: 'Not a member' });

      // Verify all requested recipients are actual members of this circle.
      const actualMemberIds = await getCircleMemberIds(input.circleId);
      const memberSet = new Set(actualMemberIds);
      const invalidRecipients = input.recipientIds.filter((id) => !memberSet.has(id));
      if (invalidRecipients.length > 0) {
        throw new TRPCError({ code: 'BAD_REQUEST', message: 'One or more recipients are not members of this circle' });
      }

      const [senderName, circleName] = await Promise.all([
        getSenderName(ctx.userId),
        getCircleName(input.circleId),
      ]);

      const recipients = input.recipientIds.filter((id) => id !== ctx.userId);

      const prayerDocId = crypto.randomUUID();
      await db.collection('circles').doc(input.circleId)
        .collection('prayer_requests').doc(prayerDocId).set({
          id: prayerDocId,
          circleId: input.circleId,
          authorId: ctx.userId,
          authorDisplayName: senderName,
          requestText: input.message,
          individual: true,
          recipientIds: recipients,
          duration: 'ONGOING',
          status: 'ACTIVE',
          prayerCount: 0,
          prayedByUserIds: [],
          responses: {},
          createdAt: Timestamp.now(),
        });

      if (input.notifyViaInbox && recipients.length > 0) {
        await fanOutNotifications(recipients, {
          type: 'prayer_request',
          circleId: input.circleId,
          circleName,
          senderUid: ctx.userId,
          senderName,
          message: input.message,
          suppressActions: false,
        });
      }

      return { requestId: prayerDocId, recipientCount: recipients.length };
    }),

  // Record an action against a notification
  recordAction: protectedProcedure
    .input(
      z.object({
        notifId: z.string(),
        action: z.enum(['pray', 'im_here', 'ill_be_there', 'unable_to_make_it', 'count_me_in', 'unable_to_do', 'got_it', 'thank_you', 'accept', 'decline']),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const ref = userNotificationsCol(ctx.userId).doc(input.notifId);
      const doc = await ref.get();
      if (!doc.exists) throw new TRPCError({ code: 'NOT_FOUND' });

      const data = doc.data()!;
      await ref.update({ actionTaken: input.action, isRead: true });

      // Notify the original sender that someone responded.
      const ACTION_LABELS: Partial<Record<string, string>> = {
        pray: 'is praying for you',
        im_here: 'is here for you',
        ill_be_there: 'will be there',
        unable_to_make_it: "can't make it",
        count_me_in: 'is joining in',
        unable_to_do: "can't do it this time",
        got_it: 'got it',
        thank_you: 'says thank you!',
        // accept/decline are partnership actions — no circle response needed
      };
      const RESPONSE_TYPES = ['prayer_request', 'announcement', 'event', 'group_activity', 'encouragement'];

      const originalSenderUid = data.senderUid as string | undefined;
      const notifType = data.type as string;
      const actionLabel = ACTION_LABELS[input.action];

      let actorName: string | undefined;

      if (originalSenderUid && originalSenderUid !== ctx.userId && actionLabel && RESPONSE_TYPES.includes(notifType)) {
        actorName = await getSenderName(ctx.userId);
        await fanOutNotifications([originalSenderUid], {
          type: notifType as 'sos' | 'prayer_request' | 'announcement' | 'event' | 'group_activity' | 'encouragement',
          circleId: data.circleId as string,
          circleName: data.circleName as string,
          senderUid: ctx.userId,
          senderName: actorName,
          message: `${actorName} ${actionLabel}`,
          suppressActions: true,
        });
      }

      // Write RSVP response back to the event document.
      const sourceId = data.sourceId as string | undefined;
      if (
        (input.action === 'ill_be_there' || input.action === 'unable_to_make_it') &&
        notifType === 'event' &&
        sourceId
      ) {
        if (!actorName) actorName = await getSenderName(ctx.userId);
        await db
          .collection('circles').doc(data.circleId as string)
          .collection('events').doc(sourceId)
          .update({ [`responses.${ctx.userId}`]: { action: input.action, name: actorName } });
      }

      return { notifId: input.notifId, action: input.action };
    }),

  // Record a Pray / I'm Here response to an individual prayer request
  respondToIndividualRequest: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        requestId: z.string(),
        action: z.enum(['pray', 'im_here']),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const ref = db.collection('circles').doc(input.circleId)
        .collection('prayer_requests').doc(input.requestId);
      const doc = await ref.get();
      if (!doc.exists) throw new TRPCError({ code: 'NOT_FOUND' });

      const data = doc.data()!;
      const recipientIds = (data.recipientIds as string[]) ?? [];
      if (!recipientIds.includes(ctx.userId)) {
        throw new TRPCError({ code: 'FORBIDDEN', message: 'Not a recipient' });
      }

      await ref.update({ [`responses.${ctx.userId}`]: input.action });

      const authorId = data.authorId as string | undefined;
      if (authorId && authorId !== ctx.userId) {
        const [actorName, circleName] = await Promise.all([
          getSenderName(ctx.userId),
          getCircleName(input.circleId),
        ]);
        const actionLabel = input.action === 'im_here' ? 'is here for you' : 'is praying for you';
        await fanOutNotifications([authorId], {
          type: 'prayer_request',
          circleId: input.circleId,
          circleName,
          senderUid: ctx.userId,
          senderName: actorName,
          message: `${actorName} ${actionLabel}`,
          suppressActions: true,
        });
      }

      return { requestId: input.requestId, action: input.action };
    }),

  // Mark a single notification as read
  markRead: protectedProcedure
    .input(z.object({ notifId: z.string() }))
    .mutation(async ({ ctx, input }) => {
      await userNotificationsCol(ctx.userId).doc(input.notifId).update({ isRead: true });
      return { notifId: input.notifId };
    }),

  // Fetch the caller's full notification inbox (newest first).
  // NOTE: onlyUnread filters in-memory to avoid a composite index requirement.
  getInbox: protectedProcedure
    .input(
      z.object({
        limit: z.number().min(1).max(100).optional().default(50),
        onlyUnread: z.boolean().optional().default(false),
      })
    )
    .query(async ({ ctx, input }) => {
      // Always query by createdAt only (single-field index, no composite needed).
      // If unread-only is requested, fetch a larger set and filter in-memory so
      // we can still return up to `limit` unread items without a composite index.
      const fetchLimit = input.onlyUnread ? Math.min(input.limit * 4, 400) : input.limit;
      const snap = await userNotificationsCol(ctx.userId)
        .orderBy('createdAt', 'desc')
        .limit(fetchLimit)
        .get();
      const allDocs = snap.docs.map((d) => {
        const data = d.data();
        return {
          id: data.id as string,
          type: data.type as 'sos' | 'prayer_request' | 'announcement',
          circleId: data.circleId as string,
          circleName: data.circleName as string,
          senderUid: data.senderUid as string,
          senderName: data.senderName as string,
          message: data.message as string,
          createdAt: (data.createdAt as FirebaseFirestore.Timestamp).toDate().toISOString(),
          isRead: data.isRead as boolean,
          actionTaken: (data.actionTaken as string | null) ?? null,
          suppressActions: data.suppressActions as boolean,
        };
      });
      if (input.onlyUnread) {
        return allDocs.filter((n) => !n.isRead).slice(0, input.limit);
      }
      return allDocs;
    }),

  // Unread count (for badge)
  getUnreadCount: protectedProcedure
    .query(async ({ ctx }) => {
      const snap = await userNotificationsCol(ctx.userId)
        .where('isRead', '==', false)
        .count()
        .get();
      return { count: snap.data().count };
    }),
});
