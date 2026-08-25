/**
 * Apple Promotional Offer signing for the Tier 1 referral reward.
 *
 * Returns ECDSA-signed parameters that Flutter passes to StoreKit when
 * initiating a purchase with the promotional offer applied.
 *
 * Required secret: APPLE_SUBSCRIPTION_KEY_P8
 *   Contents of the .p8 subscription key file from App Store Connect.
 *
 * Offer must be created in App Store Connect -> Subscriptions -> annualsub
 * with offer ID "annual_ref_50pct", type "Pay up front", 1 year, $19.99.
 *
 * Deployment:
 *   firebase deploy --only functions:getApplePromoOffer
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { createSign, randomUUID } from 'crypto';
import { defineSecret } from 'firebase-functions/params';
import { usersCol } from '../lib/firestore';

const appleSubscriptionKeyP8 = defineSecret('APPLE_SUBSCRIPTION_KEY_P8');

const APP_BUNDLE_ID = 'com.mywalk.faith';
const KEY_IDENTIFIER = 'C6LX739CNU';
const OFFER_ID = 'annual_ref_50pct';

// U+2003 EM SPACE — Apple's required field separator in the signature payload.
const SEP = ' ';

export const getApplePromoOffer = onCall(
  { region: 'us-central1', secrets: [appleSubscriptionKeyP8] },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
    const uid = request.auth.uid;

    const userSnap = await usersCol().doc(uid).get();
    const rewards = (userSnap.data()?.referralRewards as Record<string, unknown>) ?? {};
    if (!rewards.tier1Granted) {
      throw new HttpsError('permission-denied', 'Tier 1 reward not yet earned');
    }

    const { productId } = request.data as { productId?: string };
    if (productId !== 'annualsub') {
      throw new HttpsError('invalid-argument', 'Promo offer only applies to annualsub');
    }

    const nonce = randomUUID().toLowerCase();
    const timestamp = Date.now();

    const payload =
      APP_BUNDLE_ID + SEP +
      KEY_IDENTIFIER + SEP +
      productId + SEP +
      OFFER_ID + SEP +
      uid + SEP +
      nonce + SEP +
      String(timestamp);

    // ECDSA SHA-256 — DER-encoded then base64-encoded per Apple spec.
    const privateKey = appleSubscriptionKeyP8.value();
    const signature = createSign('SHA256')
      .update(payload, 'utf8')
      .sign(privateKey, 'base64');

    return {
      keyIdentifier: KEY_IDENTIFIER,
      offerId: OFFER_ID,
      productId,
      applicationUsername: uid,
      nonce,
      timestamp,
      signature,
    };
  }
);
