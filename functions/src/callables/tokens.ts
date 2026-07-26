import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../lib/admin';

// ── redeemToken ───────────────────────────────────────────────────────────────
//
// Validates a promo token and grants 12 months of premium from redemption date.
//
// Token document shape (tokens/{code}):
//   startDate:  Timestamp   — first date the code is usable
//   endDate:    Timestamp   — last date the code is usable
//   maxUses:    number      — total redemptions allowed
//   useCount:   number      — redemptions so far (incremented atomically here)
//   note:       string      — admin label, e.g. "Diocese July 2026"
//
// Writes users/{uid}/subscription/status atomically with the useCount increment
// so two simultaneous redemptions of the same last slot cannot both succeed.

export const redeemToken = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
    const uid = request.auth.uid;

    const { tokenCode } = request.data as { tokenCode?: unknown };
    if (typeof tokenCode !== 'string' || tokenCode.trim() === '') {
      throw new HttpsError('invalid-argument', 'tokenCode is required');
    }

    const code = tokenCode.trim().toUpperCase();
    const tokenRef = db.collection('tokens').doc(code);
    const subRef = db
      .collection('users')
      .doc(uid)
      .collection('subscription')
      .doc('status');

    await db.runTransaction(async (tx) => {
      const tokenSnap = await tx.get(tokenRef);

      if (!tokenSnap.exists) {
        throw new HttpsError('not-found', 'invalid-token');
      }

      const data = tokenSnap.data()!;
      const now = Timestamp.now();
      const startDate = data.startDate as Timestamp;
      const endDate = data.endDate as Timestamp;
      const maxUses = data.maxUses as number;
      const useCount = (data.useCount as number) ?? 0;

      if (now.toMillis() < startDate.toMillis()) {
        throw new HttpsError('failed-precondition', 'not-yet-active');
      }
      if (now.toMillis() > endDate.toMillis()) {
        throw new HttpsError('failed-precondition', 'expired');
      }
      if (useCount >= maxUses) {
        throw new HttpsError('resource-exhausted', 'fully-redeemed');
      }

      // Grant 12 months from redemption date regardless of endDate.
      const expiresDate = now.toDate();
      expiresDate.setFullYear(expiresDate.getFullYear() + 1);

      tx.update(tokenRef, { useCount: FieldValue.increment(1) });
      tx.set(subRef, {
        status: 'active',
        expiresAt: Timestamp.fromDate(expiresDate),
        source: 'token',
        tokenCode: code,
        grantedAt: FieldValue.serverTimestamp(),
      });
    });

    return { success: true };
  }
);
