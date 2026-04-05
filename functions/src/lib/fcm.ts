import { messaging } from './admin';
import { usersCol } from './firestore';

export async function sendPushToUsers(
  userIds: string[],
  notification: {
    title: string;
    body: string;
    data?: Record<string, string>;
    channelId?: string;   // Android notification channel (e.g. 'sos', 'circles')
    sound?: string;        // iOS/Android custom sound file (without extension)
  }
): Promise<void> {
  if (userIds.length === 0) return;

  const userDocs = await Promise.all(userIds.map((id) => usersCol().doc(id).get()));
  const tokens = userDocs
    .map((d) => d.data()?.fcmToken as string | undefined)
    .filter((t): t is string => !!t && t.length > 0);

  if (tokens.length === 0) return;

  const channelId = notification.channelId ?? 'circles';
  const sound = notification.sound ?? 'default';

  await messaging.sendEachForMulticast({
    tokens,
    notification: { title: notification.title, body: notification.body },
    data: notification.data,
    apns: {
      payload: { aps: { sound } },
      headers: { 'apns-priority': channelId === 'sos' ? '10' : '5' },
    },
    android: {
      priority: 'high',
      notification: { channelId, sound },
    },
  });
}
