import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { db, auth } from '../lib/admin';

// ── deleteAccount ─────────────────────────────────────────────────────────────
//
// Permanently deletes all data belonging to the authenticated user:
//   • Removes them from every circle (members sub-doc + memberIds array)
//   • Deletes authored circle content (gratitudes, prayer requests, encouragements,
//     milestone shares, pulse responses, habit completions) and uid-keyed docs
//     (heatmapEntries, userSeenGratitude, sosContacts)
//   • Deletes circles where user was the sole admin (+ their inviteCode)
//   • Deletes all accountability partnerships they own or participate in
//   • Deletes all recovery paths keyed to their habits
//   • Removes them from memorizationCircles (memberIds array)
//   • Recursively deletes users/{uid} and every subcollection
//   • Deletes all Firebase Storage files under journal/{uid}/
//   • Deletes the Firebase Auth account (admin SDK, no re-auth required)
//
// The client should call signOut() and clearPersistence() locally after this returns.

export const deleteAccount = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
    const uid = request.auth.uid;

    // 1. Remove user from all circles they belong to.
    //    collectionGroup('members') finds all circles/{id}/members/{uid} docs.
    const memberSnap = await db.collectionGroup('members')
      .where('userId', '==', uid)
      .get();

    if (!memberSnap.empty) {
      // Determine which circles the user is sole admin of — those will be
      // fully deleted, so we skip per-document content cleanup for them.
      const adminMemberDocs = memberSnap.docs.filter(d => d.data()['role'] === 'admin');
      const soleAdminCircleIds = new Set<string>();

      await Promise.all(adminMemberDocs.map(async (adminDoc) => {
        const circleId = adminDoc.ref.parent.parent!.id;
        const allAdminsSnap = await db.collection(`circles/${circleId}/members`)
          .where('role', '==', 'admin')
          .get();
        if (allAdminsSnap.docs.filter(d => d.id !== uid).length === 0) {
          soleAdminCircleIds.add(circleId);
        }
      }));

      // Remove membership from all circles (2 writes per circle).
      const batchSize = 200;
      for (let i = 0; i < memberSnap.docs.length; i += batchSize) {
        const batch = db.batch();
        for (const memberDoc of memberSnap.docs.slice(i, i + batchSize)) {
          const circleRef = memberDoc.ref.parent.parent!;
          batch.delete(memberDoc.ref);
          batch.update(circleRef, {
            memberCount: FieldValue.increment(-1),
            memberIds: FieldValue.arrayRemove(uid),
          });
        }
        await batch.commit();
      }

      // Collect circle IDs where user was a non-sole-admin member.
      // Sole-admin circles are deleted entirely below — no need to clean content.
      const partialCircleIds = [...new Set(
        memberSnap.docs
          .map(d => d.ref.parent.parent!.id)
          .filter(id => !soleAdminCircleIds.has(id))
      )];

      // 1b. Clean up authored content and uid-keyed docs in circles that persist.
      await Promise.all(partialCircleIds.map(async (circleId) => {
        // uid-keyed docs — safe no-op if they don't exist
        const uidBatch = db.batch();
        uidBatch.delete(db.doc(`circles/${circleId}/heatmapEntries/${uid}`));
        uidBatch.delete(db.doc(`circles/${circleId}/userSeenGratitude/${uid}`));
        uidBatch.delete(db.doc(`circles/${circleId}/sosContacts/${uid}`));
        await uidBatch.commit();

        // Authored content — query per collection (no collectionGroup index needed)
        const [gratSnap, prayerSnap, mileSnap, encoSnap] = await Promise.all([
          db.collection(`circles/${circleId}/gratitudes`).where('userId', '==', uid).get(),
          db.collection(`circles/${circleId}/prayer_requests`).where('userId', '==', uid).get(),
          db.collection(`circles/${circleId}/milestone_shares`).where('userId', '==', uid).get(),
          db.collection(`circles/${circleId}/encouragements`).where('senderId', '==', uid).get(),
        ]);

        const contentDocs = [
          ...gratSnap.docs,
          ...prayerSnap.docs,
          ...mileSnap.docs,
          ...encoSnap.docs,
        ];
        if (contentDocs.length > 0) {
          const contentBatch = db.batch();
          contentDocs.forEach(doc => contentBatch.delete(doc.ref));
          await contentBatch.commit();
        }

        // Pulse responses — keyed by uid inside each weekly_pulse doc
        const pulseWeeksSnap = await db.collection(`circles/${circleId}/weekly_pulse`).get();
        for (const weekDoc of pulseWeeksSnap.docs) {
          await db
            .doc(`circles/${circleId}/weekly_pulse/${weekDoc.id}/responses/${uid}`)
            .delete();
        }

        // Circle-habit completions
        const habitsSnap = await db.collection(`circles/${circleId}/circle_habits`).get();
        for (const habitDoc of habitsSnap.docs) {
          const completionsSnap = await habitDoc.ref
            .collection('completions')
            .where('userId', '==', uid)
            .get();
          if (!completionsSnap.empty) {
            const cBatch = db.batch();
            completionsSnap.docs.forEach(d => cBatch.delete(d.ref));
            await cBatch.commit();
          }
        }
      }));

      // 1c. Delete circles where user was sole admin (+ their invite code).
      await Promise.all([...soleAdminCircleIds].map(async (circleId) => {
        const circleRef = db.collection('circles').doc(circleId);
        const circleSnap = await circleRef.get();
        const inviteCode = circleSnap.data()?.['inviteCode'] as string | undefined;
        if (inviteCode) {
          await db.collection('inviteCodes').doc(inviteCode).delete();
        }
        await db.recursiveDelete(circleRef);
      }));
    }

    // 2. Delete all accountability partnerships where this user is owner or partner.
    const [ownerSnap, partnerSnap] = await Promise.all([
      db.collection('accountability_partnerships').where('ownerId', '==', uid).get(),
      db.collection('accountability_partnerships').where('partnerId', '==', uid).get(),
    ]);
    await Promise.all([
      ...ownerSnap.docs.map((doc) => db.recursiveDelete(doc.ref)),
      ...partnerSnap.docs.map((doc) => db.recursiveDelete(doc.ref)),
    ]);

    // 3. Delete recovery paths keyed to the user's habits.
    const recoverySnap = await db.collection('recovery_paths')
      .where('userId', '==', uid)
      .get();
    await Promise.all(
      recoverySnap.docs.map((doc) => db.recursiveDelete(doc.ref))
    );

    // 4. Remove user from any memorization circles (memberIds array field).
    const memCirclesSnap = await db.collection('memorizationCircles')
      .where('memberIds', 'array-contains', uid)
      .get();
    if (!memCirclesSnap.empty) {
      const memBatch = db.batch();
      for (const circleDoc of memCirclesSnap.docs) {
        memBatch.update(circleDoc.ref, { memberIds: FieldValue.arrayRemove(uid) });
      }
      await memBatch.commit();
    }

    // 5. Recursively delete users/{uid} and every subcollection
    //    (habits, entries, journal, memorizations, bookmarks, notifications, state, etc.).
    await db.recursiveDelete(db.collection('users').doc(uid));

    // 6. Delete all journal media from Storage.
    try {
      await getStorage().bucket().deleteFiles({ prefix: `journal/${uid}/` });
    } catch (_) {
      // No files exist or bucket not configured — safe to ignore.
    }

    // 7. Delete the Firebase Auth account.
    //    Admin SDK does not require recent re-authentication.
    await auth.deleteUser(uid);
  }
);
