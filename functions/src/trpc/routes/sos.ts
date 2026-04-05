import * as z from 'zod';
import { TRPCError } from '@trpc/server';
import { createTRPCRouter, protectedProcedure } from '../create-context';
import {
  db,
  sosRequestsCol,
  membersCol,
  sosContactsDoc,
  userNotificationsCol,
  circlesCol,
  Timestamp,
} from '../../lib/firestore';
import { sendPushToUsers } from '../../lib/fcm';

const MAX_SOS_RECIPIENTS = 20;

export const sosRouter = createTRPCRouter({
  send: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        message: z.string().max(500).optional().default('Please pray for me'),
        recipientIds: z.array(z.string()).max(MAX_SOS_RECIPIENTS),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const [memberSnap, circleDoc, senderDoc, allMemberIds] = await Promise.all([
        membersCol(input.circleId).doc(ctx.userId).get(),
        circlesCol().doc(input.circleId).get(),
        db.collection('users').doc(ctx.userId).get(),
        membersCol(input.circleId).get().then((s) => s.docs.map((d) => d.id)),
      ]);
      if (!memberSnap.exists) throw new TRPCError({ code: 'FORBIDDEN', message: 'Not a member' });

      const memberSet = new Set(allMemberIds);
      const invalidRecipients = input.recipientIds.filter((id) => !memberSet.has(id));
      if (invalidRecipients.length > 0) {
        throw new TRPCError({ code: 'BAD_REQUEST', message: 'One or more recipients are not members of this circle' });
      }

      const sosId = crypto.randomUUID();
      const now = Timestamp.now();
      const expiresAt = Timestamp.fromDate(
        new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
      );
      const circleName = (circleDoc.data()?.name as string | undefined) ?? 'Your circle';
      const senderName =
        (senderDoc.data()?.displayName as string | undefined) ?? 'A circle member';

      // Write the SOS request + all inbox notifications atomically.
      // Firestore batch limit is 500 ops; MAX_SOS_RECIPIENTS=20, so 1 + 20 = 21 ops max.
      const batch = db.batch();
      batch.set(sosRequestsCol(input.circleId).doc(sosId), {
        id: sosId,
        senderId: ctx.userId,
        circleId: input.circleId,
        message: input.message,
        recipientIds: input.recipientIds,
        createdAt: now,
      });
      for (const uid of input.recipientIds) {
        batch.set(userNotificationsCol(uid).doc(sosId), {
          id: sosId,
          type: 'sos',
          circleId: input.circleId,
          circleName,
          senderUid: ctx.userId,
          senderName,
          message: input.message,
          createdAt: now,
          expiresAt,
          isRead: false,
          actionTaken: null,
          suppressActions: true,
        });
      }
      await batch.commit();

      sendPushToUsers(input.recipientIds, {
        title: `🆘 SOS — ${senderName}`,
        body: input.message,
        data: { circleId: input.circleId, sosId, notifId: sosId, type: 'sos' },
        channelId: 'sos',
        sound: 'sos_alert',
      }).catch(() => undefined);

      return { id: sosId, recipientCount: input.recipientIds.length };
    }),

  getRecent: protectedProcedure
    .input(
      z.object({
        circleId: z.string().optional(),
        limit: z.number().min(1).max(50).optional().default(20),
      })
    )
    .query(async ({ ctx, input }) => {
      if (input.circleId) {
        const snap = await sosRequestsCol(input.circleId)
          .orderBy('createdAt', 'desc')
          .limit(input.limit)
          .get();

        return snap.docs
          .map((d) => d.data())
          .filter((s) => (s.recipientIds as string[]).includes(ctx.userId) || s.senderId === ctx.userId)
          .map((s) => ({
            id: s.id as string,
            senderId: s.senderId as string,
            circleId: s.circleId as string,
            message: s.message as string,
            createdAt: (s.createdAt as FirebaseFirestore.Timestamp).toDate().toISOString(),
            isMine: s.senderId === ctx.userId,
          }));
      }

      // Multi-circle: get circles via collectionGroup then fetch SOS for each
      const memberSnaps = await db.collectionGroup('members').where('userId', '==', ctx.userId).get();
      const circleIds = memberSnaps.docs.map((d) => d.ref.parent.parent!.id);

      const allSOS = (
        await Promise.all(
          circleIds.map((id) =>
            sosRequestsCol(id).orderBy('createdAt', 'desc').limit(input.limit).get()
          )
        )
      ).flatMap((snap) => snap.docs.map((d) => d.data()));

      return allSOS
        .filter((s) => (s.recipientIds as string[]).includes(ctx.userId) || s.senderId === ctx.userId)
        .sort((a, b) => {
          const ta = (a.createdAt as FirebaseFirestore.Timestamp).toMillis();
          const tb = (b.createdAt as FirebaseFirestore.Timestamp).toMillis();
          return tb - ta;
        })
        .slice(0, input.limit)
        .map((s) => ({
          id: s.id as string,
          senderId: s.senderId as string,
          circleId: s.circleId as string,
          message: s.message as string,
          createdAt: (s.createdAt as FirebaseFirestore.Timestamp).toDate().toISOString(),
          isMine: s.senderId === ctx.userId,
        }));
    }),

  setSOSContacts: protectedProcedure
    .input(
      z.object({
        circleId: z.string(),
        contactUserIds: z.array(z.string()).max(MAX_SOS_RECIPIENTS),
      })
    )
    .mutation(async ({ ctx, input }) => {
      await sosContactsDoc(input.circleId, ctx.userId).set({
        userId: ctx.userId,
        contactUserIds: input.contactUserIds,
        updatedAt: Timestamp.now(),
      });
      return { circleId: input.circleId, contactCount: input.contactUserIds.length };
    }),
});
