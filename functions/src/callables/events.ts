import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import {
  db,
  membersCol,
  circlesCol,
  eventsCol,
  Timestamp,
} from '../lib/firestore';
import { sendPushToUsers } from '../lib/fcm';

const MAX_ACTIVE_EVENTS = 10;

// ── circleCreateEvent ─────────────────────────────────────────────────────────

export const circleCreateEvent = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, title, eventDateMs, description, location, meetingLink } =
      request.data as {
        circleId: string;
        title: string;
        eventDateMs: number;
        description?: string;
        location?: string;
        meetingLink?: string;
      };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!title?.trim()) throw new HttpsError('invalid-argument', 'title required');
    if (typeof eventDateMs !== 'number' || eventDateMs <= 0) {
      throw new HttpsError('invalid-argument', 'eventDateMs must be a positive number (ms since epoch)');
    }

    const eventDate = new Date(eventDateMs);
    if (eventDate <= new Date()) {
      throw new HttpsError('invalid-argument', 'Event date must be in the future');
    }

    const uid = request.auth.uid;

    // Permission check: admin always allowed; any_member if settings permit.
    const [memberSnap, circleSnap] = await Promise.all([
      membersCol(circleId).doc(uid).get(),
      circlesCol().doc(circleId).get(),
    ]);

    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');

    const settings = (circleSnap.data()?.['settings'] as Record<string, unknown>) ?? {};
    const eventPermission = (settings['eventPermission'] as string) ?? 'admin';
    const role = memberSnap.data()!['role'] as string;

    if (eventPermission === 'admin' && role !== 'admin') {
      throw new HttpsError('permission-denied', 'Only admins can create circle events');
    }

    // Enforce active-event cap to prevent spam.
    const now = Timestamp.now();
    const activeSnap = await eventsCol(circleId)
      .where('eventDate', '>', now)
      .limit(MAX_ACTIVE_EVENTS)
      .get();
    if (activeSnap.size >= MAX_ACTIVE_EVENTS) {
      throw new HttpsError(
        'resource-exhausted',
        `A circle can have at most ${MAX_ACTIVE_EVENTS} upcoming events`
      );
    }

    const ref = eventsCol(circleId).doc();
    await ref.set({
      id: ref.id,
      circleId,
      createdById: uid,
      title: title.trim(),
      description: description?.trim() ?? null,
      location: location?.trim() ?? null,
      meetingLink: meetingLink?.trim() ?? null,
      eventDate: Timestamp.fromDate(eventDate),
      createdAt: now,
    });

    // Notify all other circle members (non-fatal).
    const membersSnap = await membersCol(circleId).get();
    const otherIds = membersSnap.docs
      .map((d) => d.data()['userId'] as string)
      .filter((id) => id !== uid);

    if (otherIds.length > 0) {
      sendPushToUsers(otherIds, {
        title: 'New circle event',
        body: `${title.trim()} — ${_formatEventDate(eventDate)}`,
        data: { type: 'EVENT_CREATED', circleId, eventId: ref.id },
      }).catch(() => { /* non-fatal */ });
    }

    return { id: ref.id };
  }
);

// ── circleUpdateEvent ─────────────────────────────────────────────────────────

export const circleUpdateEvent = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, eventId, title, eventDateMs, description, location, meetingLink } =
      request.data as {
        circleId: string;
        eventId: string;
        title: string;
        eventDateMs: number;
        description?: string | null;
        location?: string | null;
        meetingLink?: string | null;
      };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!eventId?.trim()) throw new HttpsError('invalid-argument', 'eventId required');
    if (!title?.trim()) throw new HttpsError('invalid-argument', 'title required');
    if (typeof eventDateMs !== 'number' || eventDateMs <= 0) {
      throw new HttpsError('invalid-argument', 'eventDateMs must be a positive number (ms since epoch)');
    }

    const eventDate = new Date(eventDateMs);
    if (eventDate <= new Date()) {
      throw new HttpsError('invalid-argument', 'Event date must be in the future');
    }

    const uid = request.auth.uid;

    const [memberSnap, eventSnap] = await Promise.all([
      membersCol(circleId).doc(uid).get(),
      eventsCol(circleId).doc(eventId).get(),
    ]);

    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');
    if (!eventSnap.exists) throw new HttpsError('not-found', 'Event not found');

    const role = memberSnap.data()!['role'] as string;
    const createdById = eventSnap.data()!['createdById'] as string;

    // Admins or the event creator can edit.
    if (role !== 'admin' && createdById !== uid) {
      throw new HttpsError('permission-denied', 'Only admins or the event creator can edit events');
    }

    await eventsCol(circleId).doc(eventId).update({
      title: title.trim(),
      description: description?.trim() ?? null,
      location: location?.trim() ?? null,
      meetingLink: meetingLink?.trim() ?? null,
      eventDate: Timestamp.fromDate(eventDate),
    });

    return { success: true };
  }
);

// ── circleDeleteEvent ─────────────────────────────────────────────────────────

export const circleDeleteEvent = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, eventId } = request.data as {
      circleId: string;
      eventId: string;
    };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!eventId?.trim()) throw new HttpsError('invalid-argument', 'eventId required');

    const uid = request.auth.uid;

    const [memberSnap, eventSnap] = await Promise.all([
      membersCol(circleId).doc(uid).get(),
      eventsCol(circleId).doc(eventId).get(),
    ]);

    if (!memberSnap.exists) throw new HttpsError('permission-denied', 'Not a member of this circle');
    if (!eventSnap.exists) throw new HttpsError('not-found', 'Event not found');

    const role = memberSnap.data()!['role'] as string;
    const createdById = eventSnap.data()!['createdById'] as string;

    // Admins or the event creator can delete.
    if (role !== 'admin' && createdById !== uid) {
      throw new HttpsError('permission-denied', 'Only admins or the event creator can delete events');
    }

    await eventsCol(circleId).doc(eventId).delete();

    return { success: true };
  }
);

// ── sendEventReminders (scheduled hourly) ─────────────────────────────────────
// Notifies circle members 24 hours before an event starts (±30 min window).

export const sendEventReminders = onSchedule(
  { schedule: '0 * * * *', timeZone: 'UTC', region: 'us-central1' },
  async () => {
    const now = new Date();
    // Window: events starting in 23.5–24.5 hours from now.
    const windowStart = new Date(now.getTime() + 23.5 * 60 * 60 * 1000);
    const windowEnd = new Date(now.getTime() + 24.5 * 60 * 60 * 1000);

    const eventsSnap = await db
      .collectionGroup('events')
      .where('eventDate', '>=', Timestamp.fromDate(windowStart))
      .where('eventDate', '<=', Timestamp.fromDate(windowEnd))
      .get();

    if (eventsSnap.empty) return;

    for (const eventDoc of eventsSnap.docs) {
      const event = eventDoc.data();
      const circleId = event['circleId'] as string;
      const title = event['title'] as string;
      const eventDate = (event['eventDate'] as FirebaseFirestore.Timestamp).toDate();

      const membersSnap = await membersCol(circleId).get();
      const memberIds = membersSnap.docs.map((d) => d.data()['userId'] as string);

      if (memberIds.length === 0) continue;

      sendPushToUsers(memberIds, {
        title: 'Event reminder',
        body: `${title} is tomorrow at ${_formatEventTime(eventDate)}.`,
        data: { type: 'EVENT_REMINDER', circleId, eventId: eventDoc.id },
      }).catch(() => { /* non-fatal */ });
    }
  }
);

// ── Internal helpers ──────────────────────────────────────────────────────────

function _formatEventDate(date: Date): string {
  return date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
}

function _formatEventTime(date: Date): string {
  return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
}
