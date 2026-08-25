import { GoogleAuth } from 'google-auth-library';
import { defineSecret } from 'firebase-functions/params';

export const googleServiceAccount = defineSecret('GOOGLE_SERVICE_ACCOUNT_JSON');

const PACKAGE_NAME = 'com.mywalk.faith';
const PLAY_BASE = 'https://androidpublisher.googleapis.com/androidpublisher/v3';

async function _accessToken(): Promise<string> {
  const json = googleServiceAccount.value();
  if (!json) throw new Error('GOOGLE_SERVICE_ACCOUNT_JSON secret not configured');
  const credentials = JSON.parse(json) as object;
  const auth = new GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  const client = await auth.getClient();
  const { token } = await client.getAccessToken();
  if (!token) throw new Error('Failed to obtain Google Play access token');
  return token;
}

async function _playFetch(url: string, options: RequestInit = {}): Promise<Response> {
  const token = await _accessToken();
  return fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string> | undefined ?? {}),
    },
  });
}

/**
 * Cancels a Google Play subscription immediately.
 * The subscription remains active until the current billing period ends.
 */
export async function cancelSubscription(
  purchaseToken: string,
  subscriptionId: string
): Promise<void> {
  const url = `${PLAY_BASE}/applications/${PACKAGE_NAME}/purchases/subscriptions/${subscriptionId}/tokens/${encodeURIComponent(purchaseToken)}:cancel`;
  const res = await _playFetch(url, { method: 'POST', body: '{}' });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Play cancel failed [${res.status}]: ${body}`);
  }
}

/**
 * Defers a Google Play subscription's next billing date by the given number of days.
 * Fetches the current expiry from Google first so the request body matches exactly.
 */
export async function deferSubscription(
  purchaseToken: string,
  subscriptionId: string,
  daysToDefer: number
): Promise<void> {
  const getUrl = `${PLAY_BASE}/applications/${PACKAGE_NAME}/purchases/subscriptions/${subscriptionId}/tokens/${encodeURIComponent(purchaseToken)}`;
  const getRes = await _playFetch(getUrl);
  if (!getRes.ok) {
    const body = await getRes.text();
    throw new Error(`Play get subscription failed [${getRes.status}]: ${body}`);
  }
  const sub = await getRes.json() as { expiryTimeMillis: string };

  const newExpiryMs =
    parseInt(sub.expiryTimeMillis, 10) + daysToDefer * 24 * 60 * 60 * 1000;

  const deferUrl = `${PLAY_BASE}/applications/${PACKAGE_NAME}/purchases/subscriptions/${subscriptionId}/tokens/${encodeURIComponent(purchaseToken)}:defer`;
  const deferRes = await _playFetch(deferUrl, {
    method: 'POST',
    body: JSON.stringify({
      deferralInfo: {
        expectedExpiryTimeMillis: sub.expiryTimeMillis,
        desiredExpiryTimeMillis: String(newExpiryMs),
      },
    }),
  });
  if (!deferRes.ok) {
    const body = await deferRes.text();
    throw new Error(`Play defer failed [${deferRes.status}]: ${body}`);
  }
}
