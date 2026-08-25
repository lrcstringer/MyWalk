/**
 * Referral system — generates and tracks user referral codes.
 *
 * Exports (callables):
 *   generateReferralCode — returns the user's existing code or mints a new unique one
 *   applyReferralCode    — links a new user to their referrer (call immediately after account creation)
 *
 * Exports (scheduled):
 *   processReferralConfirmations — runs daily; confirms referrals 30 days after purchase
 *
 * Exports (internal, used by iap.ts):
 *   recordReferralPurchase — stamps purchasedAt on the referral record when a purchase is validated
 *
 * Reward thresholds:
 *   3 confirmed referrals → tier1 (50% off next annual renewal — payout handled in a separate PR)
 *   5 confirmed referrals → tier2 (lifetime upgrade — applied immediately server-side)
 *
 * Firestore index required on referralPurchases:
 *   Composite: status ASC, purchasedAt ASC
 *   (Firebase console will show a link to create it on first scheduled run if missing)
 *
 * Deployment:
 *   firebase deploy --only functions:generateReferralCode
 *   firebase deploy --only functions:applyReferralCode
 *   firebase deploy --only functions:processReferralConfirmations
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../lib/admin';
import { referralCodesCol, referralPurchasesCol, usersCol } from '../lib/firestore';
import { sendPushToUsers } from '../lib/fcm';
import { cancelSubscription, deferSubscription, googleServiceAccount } from '../lib/google-play';

// ── Code generation ────────────────────────────────────────────────────────────

// Uppercase alphanumeric, excluding I, O, 0, 1 (visually ambiguous characters).
const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const CODE_LENGTH = 6;

function _randomCode(): string {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  }
  return code;
}

// ── generateReferralCode ───────────────────────────────────────────────────────

export const generateReferralCode = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
    const uid = request.auth.uid;

    const userRef = usersCol().doc(uid);
    const userSnap = await userRef.get();
    if (!userSnap.exists) throw new HttpsError('not-found', 'User not found');

    const existing = userSnap.data()?.referralCode as string | undefined;
    if (existing) return { code: existing };

    // Attempt up to 10 times to claim a unique code via transaction.
    for (let attempt = 0; attempt < 10; attempt++) {
      const candidate = _randomCode();
      const codeRef = referralCodesCol().doc(candidate);
      let collided = false;

      await db.runTransaction(async (tx) => {
        const snap = await tx.get(codeRef);
        if (snap.exists) { collided = true; return; }
        tx.set(codeRef, { ownerUid: uid });
        tx.update(userRef, { referralCode: candidate });
      });

      if (!collided) return { code: candidate };
    }

    throw new HttpsError('internal', 'Could not generate a unique referral code — try again');
  }
);

// ── applyReferralCode ──────────────────────────────────────────────────────────

export const applyReferralCode = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
    const uid = request.auth.uid;

    const { code } = request.data as { code?: unknown };
    if (typeof code !== 'string' || code.trim() === '') {
      throw new HttpsError('invalid-argument', 'code is required');
    }
    const normalised = code.trim().toUpperCase();

    await db.runTransaction(async (tx) => {
      const codeSnap = await tx.get(referralCodesCol().doc(normalised));
      if (!codeSnap.exists) throw new HttpsError('not-found', 'invalid-code');

      const ownerUid = codeSnap.data()!.ownerUid as string;
      if (ownerUid === uid) throw new HttpsError('invalid-argument', 'cannot-self-refer');

      const userSnap = await tx.get(usersCol().doc(uid));
      if (!userSnap.exists) throw new HttpsError('not-found', 'User not found');
      if (userSnap.data()?.referredByUid) {
        throw new HttpsError('already-exists', 'referral-already-applied');
      }

      const now = Timestamp.now();
      tx.update(usersCol().doc(uid), { referredByUid: ownerUid });
      tx.set(referralPurchasesCol().doc(uid), {
        referrerUid: ownerUid,
        referredUid: uid,
        joinedAt: now,
        purchasedAt: null,
        confirmedAt: null,
        status: 'joined',
      });
    });

    return { success: true };
  }
);

// ── processReferralConfirmations (scheduled) ───────────────────────────────────

export const processReferralConfirmations = onSchedule(
  { schedule: 'every 24 hours', region: 'us-central1', memory: '256MiB', secrets: [googleServiceAccount] },
  async () => {
    const thirtyDaysAgo = Timestamp.fromMillis(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const snap = await referralPurchasesCol()
      .where('status', '==', 'pending')
      .where('purchasedAt', '<=', thirtyDaysAgo)
      .limit(200)
      .get();

    if (snap.empty) return;

    // Group confirmed referredUids by their referrer so we can batch-increment.
    const byReferrer = new Map<string, string[]>();
    for (const doc of snap.docs) {
      const { referrerUid, referredUid } = doc.data() as {
        referrerUid: string;
        referredUid: string;
      };
      const list = byReferrer.get(referrerUid) ?? [];
      list.push(referredUid);
      byReferrer.set(referrerUid, list);
    }

    const now = Timestamp.now();

    await Promise.all(
      [...byReferrer.entries()].map(async ([referrerUid, referredUids]) => {
        const batch = db.batch();
        for (const referredUid of referredUids) {
          batch.update(referralPurchasesCol().doc(referredUid), {
            status: 'confirmed',
            confirmedAt: now,
          });
        }
        batch.update(usersCol().doc(referrerUid), {
          referralCount: FieldValue.increment(referredUids.length),
        });
        await batch.commit();

        await _checkAndGrantRewards(referrerUid);
      })
    );
  }
);

// ── recordReferralPurchase (internal, called from iap.ts) ─────────────────────
//
// Stamps purchasedAt on the referral record when a new purchase is first validated.
// Idempotent — only acts when status is 'joined' (pre-purchase).
// Renewals and re-validations are naturally ignored.

export async function recordReferralPurchase(uid: string): Promise<void> {
  const purchaseRef = referralPurchasesCol().doc(uid);
  const snap = await purchaseRef.get();
  if (!snap.exists) return; // organic user — no referral record
  if (snap.data()!.status !== 'joined') return; // already recorded

  await purchaseRef.update({
    status: 'pending',
    purchasedAt: Timestamp.now(),
  });
}

// ── _checkAndGrantRewards (internal) ──────────────────────────────────────────
//
// Reads the referrer's current count and grants any newly-hit reward tiers.
// All reward grants are idempotent via the tier1Granted / tier2Granted flags.
// Google Play store operations run after Firestore writes so a Play API failure
// never blocks the in-app reward.

async function _checkAndGrantRewards(referrerUid: string): Promise<void> {
  const userRef = usersCol().doc(referrerUid);
  const snap = await userRef.get();
  if (!snap.exists) return;

  const data = snap.data()!;
  const count = (data.referralCount as number) ?? 0;
  const rewards = (data.referralRewards as Record<string, unknown>) ?? {};

  const grantTier1 = count >= 3 && !rewards.tier1Granted;
  const grantTier2 = count >= 5 && !rewards.tier2Granted;
  if (!grantTier1 && !grantTier2) return;

  const updates: Record<string, unknown> = {};
  const now = Timestamp.now();

  if (grantTier1) {
    updates['referralRewards.tier1Granted'] = true;
    updates['referralRewards.tier1GrantedAt'] = now;
  }
  if (grantTier2) {
    updates['referralRewards.tier2Granted'] = true;
    updates['referralRewards.tier2GrantedAt'] = now;
  }

  // Read subscription doc once — needed for both tiers' store operations.
  const subRef = userRef.collection('subscription').doc('status');
  const subSnap = await subRef.get();
  const subData = subSnap.data();
  const platform = (subData?.platform as string) ?? 'unknown';
  const productId = (subData?.productId as string) ?? '';
  const purchaseId = (subData?.purchaseId as string) ?? '';
  const isAndroidSub = platform === 'android' && !!purchaseId &&
    (productId === 'annualsub' || productId === 'monthlysub');

  // Tier 2: overwrite subscription to lifetime in Firestore, then cancel the store sub.
  if (grantTier2) {
    await subRef.set({
      productId: 'lifetimeonetime',
      platform,
      purchaseId: `referral_reward_${Date.now()}`,
      status: 'active',
      expiresAt: null,
      validatedAt: now,
      source: 'referral_reward',
    });

    if (isAndroidSub) {
      await cancelSubscription(purchaseId, productId).catch((e) =>
        console.error('Play cancel failed for tier2 reward:', e)
      );
    }
  }

  // Tier 1: defer the next billing date by 183 days on Google Play (≈ 6 months free).
  // Skip if Tier 2 is also being granted in this same run — cancel supersedes.
  if (grantTier1 && !grantTier2 && isAndroidSub && productId === 'annualsub') {
    await deferSubscription(purchaseId, productId, 183).catch((e) =>
      console.error('Play defer failed for tier1 reward:', e)
    );
  }

  await userRef.update(updates);

  // Push notifications — fire after writes so partial failures don't block the reward.
  if (grantTier2) {
    const isIos = platform === 'ios';
    await sendPushToUsers([referrerUid], {
      title: "You've been upgraded to Lifetime!",
      body: isIos
        ? '5 referrals confirmed — you now have lifetime access. Please cancel your App Store subscription to avoid further billing.'
        : '5 referrals confirmed — your Google Play subscription has been cancelled. You now have lifetime access.',
      channelId: 'circles',
      ...(isIos && { data: { action: 'cancel_apple_subscription' } }),
    }).catch((e) => console.error('referral tier2 push failed:', e));
  } else if (grantTier1) {
    await sendPushToUsers([referrerUid], {
      title: "You've earned a reward!",
      body: '3 referrals confirmed — your next annual renewal is 50% off.',
      channelId: 'circles',
    }).catch((e) => console.error('referral tier1 push failed:', e));
  }
}
