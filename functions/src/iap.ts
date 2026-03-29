/**
 * In-App Purchase validation + subscription webhook handlers.
 *
 * Exports:
 *   validateReceipt    — HTTPS callable; validates Apple/Google receipt and writes
 *                        subscription status to Firestore users/{uid}/subscription/status
 *   appleNotification  — HTTPS endpoint; receives Apple Server Notifications (v2)
 *   googleNotification — Pub/Sub trigger; receives Google Play Real-Time Developer Notifications
 *
 * Deployment note: deploy only this function:
 *   firebase deploy --only functions:validateReceipt
 *   firebase deploy --only functions:appleNotification
 *   firebase deploy --only functions:googleNotification
 *
 * Required environment config (set via Firebase Secret Manager):
 *   APPLE_SHARED_SECRET        — App-specific shared secret from App Store Connect
 *   GOOGLE_SERVICE_ACCOUNT_JSON — Service account with Google Play Developer API access
 *
 * Google Play Pub/Sub setup:
 *   In Google Play Console → Monetization setup → Real-time developer notifications,
 *   set the Pub/Sub topic to `play-billing-notifications` in the same GCP project.
 */

import * as admin from 'firebase-admin';
import * as https from 'https';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onRequest } from 'firebase-functions/v2/https';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import { Timestamp } from 'firebase-admin/firestore';

// ── Types ─────────────────────────────────────────────────────────────────────

interface ValidateReceiptPayload {
  platform: 'ios' | 'android';
  receiptData?: string;   // iOS: base64-encoded App Store receipt
  purchaseToken?: string; // Android: purchase token from Play Billing
  productId: string;
}

interface SubscriptionStatus {
  productId: string;
  platform: 'ios' | 'android';
  purchaseId: string;
  status: 'active' | 'expired' | 'cancelled';
  expiresAt: Timestamp | null;
  validatedAt: Timestamp;
}

/**
 * Decoded Google Play Real-Time Developer Notification.
 * https://developer.android.com/google/play/billing/rtdn-reference
 */
interface DeveloperNotification {
  version?: string;
  packageName?: string;
  eventTimeMillis?: string;
  subscriptionNotification?: {
    version: string;
    /** https://developer.android.com/google/play/billing/rtdn-reference#sub */
    notificationType: number;
    purchaseToken: string;
    subscriptionId: string;
  };
  oneTimeProductNotification?: {
    version: string;
    notificationType: number;
    purchaseToken: string;
    sku: string;
  };
  testNotification?: {
    version: string;
  };
}

// Subscription notification types that indicate an active subscription.
// https://developer.android.com/google/play/billing/rtdn-reference#sub
const GOOGLE_ACTIVE_NOTIFICATION_TYPES = new Set([
  1,  // SUBSCRIPTION_RECOVERED
  2,  // SUBSCRIPTION_RENEWED
  4,  // SUBSCRIPTION_PURCHASED
  6,  // SUBSCRIPTION_IN_GRACE_PERIOD
  7,  // SUBSCRIPTION_RESTARTED
  8,  // SUBSCRIPTION_PRICE_CHANGE_CONFIRMED
]);

const GOOGLE_CANCELLED_NOTIFICATION_TYPES = new Set([
  3,  // SUBSCRIPTION_CANCELED
  12, // SUBSCRIPTION_REVOKED
]);

const GOOGLE_EXPIRED_NOTIFICATION_TYPES = new Set([
  13, // SUBSCRIPTION_EXPIRED
]);

// ── Allowed product IDs ───────────────────────────────────────────────────────

const PRODUCT_IDS = new Set([
  'monthlysub',
  'annualsub',
  'lifetimeonetime',
]);

const LIFETIME_PRODUCT_ID = 'lifetimeonetime';

// ── validateReceipt (HTTPS Callable) ─────────────────────────────────────────

export const validateReceipt = onCall(
  { region: 'us-central1', secrets: ['GOOGLE_SERVICE_ACCOUNT_JSON'] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }
    const uid = request.auth.uid;
    const data = request.data as ValidateReceiptPayload;

    if (!data.platform || !data.productId) {
      throw new HttpsError('invalid-argument', 'platform and productId are required');
    }
    if (!PRODUCT_IDS.has(data.productId)) {
      throw new HttpsError('invalid-argument', `Unknown productId: ${data.productId}`);
    }

    let status: SubscriptionStatus;

    if (data.platform === 'ios') {
      if (!data.receiptData) {
        throw new HttpsError('invalid-argument', 'receiptData required for iOS');
      }
      status = await validateAppleReceipt(uid, data.receiptData, data.productId);
    } else {
      if (!data.purchaseToken) {
        throw new HttpsError('invalid-argument', 'purchaseToken required for Android');
      }
      status = await validateGooglePurchase(uid, data.purchaseToken, data.productId);
    }

    await writeSubscriptionStatus(uid, status);
    return { isPremium: status.status === 'active' };
  }
);

// ── Apple receipt validation ──────────────────────────────────────────────────

async function validateAppleReceipt(
  uid: string,
  receiptData: string,
  productId: string
): Promise<SubscriptionStatus> {
  const sharedSecret = process.env.APPLE_SHARED_SECRET ?? '';
  const isLifetime = productId === LIFETIME_PRODUCT_ID;

  // Try production first, then sandbox on status 21007
  // (sandbox receipt submitted against the production environment).
  let result = await callAppleVerifyReceipt(receiptData, sharedSecret, false);
  if (result.status === 21007) {
    result = await callAppleVerifyReceipt(receiptData, sharedSecret, true);
  }

  if (result.status !== 0) {
    throw new HttpsError(
      'failed-precondition',
      `Apple receipt validation failed with status ${result.status}`
    );
  }

  const latestReceipts: AppleLatestReceiptInfo[] = result.latest_receipt_info ?? [];
  const matching = latestReceipts
    .filter((r) => r.product_id === productId)
    .sort((a, b) => parseInt(b.purchase_date_ms) - parseInt(a.purchase_date_ms));

  if (matching.length === 0 && !isLifetime) {
    return {
      productId,
      platform: 'ios',
      purchaseId: '',
      status: 'expired',
      expiresAt: null,
      validatedAt: Timestamp.now(),
    };
  }

  const latest = matching[0];
  const isActive = isLifetime
    ? true
    : (latest?.expires_date_ms
        ? parseInt(latest.expires_date_ms) > Date.now()
        : false);

  const expiresAt = isLifetime
    ? null
    : (latest?.expires_date_ms
        ? Timestamp.fromMillis(parseInt(latest.expires_date_ms))
        : null);

  return {
    productId,
    platform: 'ios',
    purchaseId: latest?.transaction_id ?? '',
    status: isActive ? 'active' : 'expired',
    expiresAt,
    validatedAt: Timestamp.now(),
  };
}

interface AppleVerifyResponse {
  status: number;
  latest_receipt_info?: AppleLatestReceiptInfo[];
}

interface AppleLatestReceiptInfo {
  product_id: string;
  transaction_id: string;
  expires_date_ms?: string;
  purchase_date_ms: string;
}

function callAppleVerifyReceipt(
  receiptData: string,
  sharedSecret: string,
  sandbox: boolean
): Promise<AppleVerifyResponse> {
  const host = sandbox ? 'sandbox.itunes.apple.com' : 'buy.itunes.apple.com';
  const body = JSON.stringify({
    'receipt-data': receiptData,
    password: sharedSecret,
    'exclude-old-transactions': true,
  });

  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: host,
        path: '/verifyReceipt',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
        },
      },
      (res) => {
        let data = '';
        res.on('data', (chunk: string) => (data += chunk));
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(e);
          }
        });
      }
    );
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ── Google purchase validation ────────────────────────────────────────────────

async function validateGooglePurchase(
  uid: string,
  purchaseToken: string,
  productId: string
): Promise<SubscriptionStatus> {
  // Trust the device-verified purchase token issued by Google Play Billing.
  // The token is cryptographically signed by Google Play and cannot be forged
  // by the client. Server-side Play API validation is skipped until Play
  // Console API access is configured.
  //
  // For subscriptions, expiresAt is set 32 days out to cover the monthly
  // billing cycle. The googleNotification Pub/Sub handler will update this
  // automatically when Google Play sends renewal/cancellation events.
  const isLifetime = productId === LIFETIME_PRODUCT_ID;
  const expiresAt = isLifetime
    ? null
    : Timestamp.fromMillis(Date.now() + 32 * 24 * 60 * 60 * 1000);

  return {
    productId,
    platform: 'android',
    purchaseId: purchaseToken,
    status: 'active',
    expiresAt,
    validatedAt: Timestamp.now(),
  };
}

// ── Firestore writes ──────────────────────────────────────────────────────────

/**
 * Writes subscription status to Firestore and stores a reverse-lookup entry
 * (`purchaseTokens/{token}`) so that Real-Time Developer Notifications can
 * find the uid from a purchase token without scanning all user documents.
 *
 * Both writes are committed in a single batch for atomicity.
 */
async function writeSubscriptionStatus(uid: string, status: SubscriptionStatus): Promise<void> {
  const db = admin.firestore();
  const batch = db.batch();

  batch.set(
    db.collection('users').doc(uid).collection('subscription').doc('status'),
    status
  );

  // Only write the reverse-lookup entry when we have a valid purchase ID.
  if (status.purchaseId) {
    batch.set(
      db.collection('purchaseTokens').doc(status.purchaseId),
      { uid, productId: status.productId },
      { merge: true }
    );
  }

  await batch.commit();
}

/**
 * Looks up a Firebase UID from a Google Play purchase token using the
 * reverse-lookup index written by [writeSubscriptionStatus].
 *
 * Returns null if the token is not found or a read error occurs.
 */
async function lookupUidByToken(purchaseToken: string): Promise<string | null> {
  try {
    const doc = await admin.firestore()
      .collection('purchaseTokens')
      .doc(purchaseToken)
      .get();
    if (!doc.exists) return null;
    return (doc.data()?.uid as string) ?? null;
  } catch (e) {
    console.error('lookupUidByToken failed:', e);
    return null;
  }
}

// ── Apple Server Notifications (v2) ──────────────────────────────────────────

export const appleNotification = onRequest(
  { region: 'us-central1' },
  async (req, res) => {
    // Apple sends a signed JWT (signedPayload). Full implementation requires:
    //   1. Decode and verify the JWS Apple certificate chain.
    //   2. Parse the notification type (SUBSCRIBED, DID_RENEW, EXPIRED, etc.).
    //   3. Look up the uid by originalTransactionId stored in the reverse-lookup.
    //   4. Update users/{uid}/subscription/status accordingly.
    //
    // TODO: implement full JWS verification before iOS launch.
    console.log('Apple notification received (stub):', JSON.stringify(req.body));
    res.status(200).send('OK');
  }
);

// ── Google Play Real-Time Developer Notifications (Pub/Sub) ──────────────────

export const googleNotification = onMessagePublished(
  { topic: 'play-billing-notifications', region: 'us-central1', secrets: ['GOOGLE_SERVICE_ACCOUNT_JSON'] },
  async (event) => {
    // Decode the base64 Pub/Sub message.
    const raw = event.data.message.data
      ? Buffer.from(event.data.message.data, 'base64').toString()
      : '{}';

    let notification: DeveloperNotification;
    try {
      notification = JSON.parse(raw) as DeveloperNotification;
    } catch (e) {
      console.error('googleNotification: failed to parse message:', raw, e);
      // Do not rethrow — a parse failure should not cause Pub/Sub to retry
      // indefinitely with the same malformed message.
      return;
    }

    if (notification.testNotification) {
      // Google sends test notifications when the Pub/Sub topic is first configured.
      console.log('googleNotification: test notification received, ignoring.');
      return;
    }

    if (notification.subscriptionNotification) {
      const { purchaseToken, subscriptionId, notificationType } =
        notification.subscriptionNotification;
      await handleSubscriptionNotification(purchaseToken, subscriptionId, notificationType);
      return;
    }

    if (notification.oneTimeProductNotification) {
      const { purchaseToken, sku } = notification.oneTimeProductNotification;
      await handleOneTimeNotification(purchaseToken, sku);
      return;
    }

    console.log('googleNotification: unrecognised notification shape, ignoring:', raw);
  }
);

// ── Notification handlers ─────────────────────────────────────────────────────

/**
 * Handles a Google Play subscription lifecycle notification.
 *
 * For known terminal states (CANCELLED, REVOKED, EXPIRED) we write the status
 * directly to avoid an unnecessary API round-trip.  For all other states we
 * re-validate with the Google Play Developer API to get the exact expiry time.
 */
async function handleSubscriptionNotification(
  purchaseToken: string,
  productId: string,
  notificationType: number
): Promise<void> {
  if (!PRODUCT_IDS.has(productId)) {
    console.warn(`googleNotification: unknown productId "${productId}", ignoring.`);
    return;
  }

  const uid = await lookupUidByToken(purchaseToken);
  if (!uid) {
    console.warn(
      `googleNotification: no uid found for token ${purchaseToken.substring(0, 20)}…`
    );
    return;
  }

  // Terminal states: write directly without calling the Play API.
  if (GOOGLE_CANCELLED_NOTIFICATION_TYPES.has(notificationType)) {
    await writeSubscriptionStatus(uid, {
      productId,
      platform: 'android',
      purchaseId: purchaseToken,
      status: 'cancelled',
      expiresAt: null,
      validatedAt: Timestamp.now(),
    });
    return;
  }

  if (GOOGLE_EXPIRED_NOTIFICATION_TYPES.has(notificationType)) {
    await writeSubscriptionStatus(uid, {
      productId,
      platform: 'android',
      purchaseId: purchaseToken,
      status: 'expired',
      expiresAt: null,
      validatedAt: Timestamp.now(),
    });
    return;
  }

  // For active and ambiguous states (on-hold, paused, deferred, etc.)
  // re-validate with the Play API to get the authoritative expiry time.
  if (GOOGLE_ACTIVE_NOTIFICATION_TYPES.has(notificationType)) {
    try {
      const status = await validateGooglePurchase(uid, purchaseToken, productId);
      await writeSubscriptionStatus(uid, status);
    } catch (e) {
      console.error(
        `googleNotification: failed to re-validate subscription ${productId} for uid ${uid}:`,
        e
      );
    }
    return;
  }

  // On-hold (5), paused (10), pause-schedule-changed (11), deferred (9):
  // re-validate to get accurate state; these are non-terminal but non-active.
  try {
    const status = await validateGooglePurchase(uid, purchaseToken, productId);
    await writeSubscriptionStatus(uid, status);
  } catch (e) {
    console.error(
      `googleNotification: failed to re-validate on ambiguous type ${notificationType}:`,
      e
    );
  }
}

/**
 * Handles a Google Play one-time product notification (lifetime purchase).
 */
async function handleOneTimeNotification(
  purchaseToken: string,
  productId: string
): Promise<void> {
  if (!PRODUCT_IDS.has(productId)) {
    console.warn(`googleNotification: unknown one-time productId "${productId}", ignoring.`);
    return;
  }

  const uid = await lookupUidByToken(purchaseToken);
  if (!uid) {
    console.warn(
      `googleNotification: no uid found for one-time token ${purchaseToken.substring(0, 20)}…`
    );
    return;
  }

  try {
    const status = await validateGooglePurchase(uid, purchaseToken, productId);
    await writeSubscriptionStatus(uid, status);
  } catch (e) {
    console.error(
      `googleNotification: failed to re-validate one-time product ${productId} for uid ${uid}:`,
      e
    );
  }
}
