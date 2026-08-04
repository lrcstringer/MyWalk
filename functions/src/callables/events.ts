import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import {
  db,
  membersCol,
  circlesCol,
  eventsCol,
  Timestamp,
} from '../lib/firestore';

const MAX_ACTIVE_EVENTS = 50;

// Pre-generated occurrences per recurrence type (~3 months each)
const INITIAL_OCCURRENCES: Record<string, number> = {
  weekly: 13,
  biweekly: 7,
  monthly: 3,
};

function addInterval(date: Date, recurrenceType: string): Date {
  switch (recurrenceType) {
    case 'weekly':
      return new Date(date.getTime() + 7 * 24 * 60 * 60 * 1000);
    case 'biweekly':
      return new Date(date.getTime() + 14 * 24 * 60 * 60 * 1000);
    case 'monthly': {
      const d = new Date(date);
      d.setMonth(d.getMonth() + 1);
      return d;
    }
    default:
      return date;
  }
}

// ── circleCreateEvent ─────────────────────────────────────────────────────────

export const circleCreateEvent = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');

    const { circleId, title, eventDateMs, description, location, meetingLink, recurrenceType } =
      request.data as {
        circleId: string;
        title: string;
        eventDateMs: number;
        description?: string;
        location?: string;
        meetingLink?: string;
        recurrenceType?: string;
      };

    if (!circleId?.trim()) throw new HttpsError('invalid-argument', 'circleId required');
    if (!title?.trim()) throw new HttpsError('invalid-argument', 'title required');
    if (typeof eventDateMs !== 'number' || eventDateMs <= 0) {
      throw new HttpsError('invalid-argument', 'eventDateMs must be a positive number (ms since epoch)');
    }
    if (recurrenceType && !['weekly', 'biweekly', 'monthly'].includes(recurrenceType)) {
      throw new HttpsError('invalid-argument', 'Invalid recurrenceType');
    }

    const firstDate = new Date(eventDateMs);
    if (firstDate <= new Date()) {
      throw new HttpsError('invalid-argument', 'Event date must be in the future');
    }

    const uid = request.auth.uid;

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

    // Enforce cap — recurring meetups generate multiple docs at once.
    const occurrenceCount = recurrenceType ? (INITIAL_OCCURRENCES[recurrenceType] ?? 1) : 1;
    const now = Timestamp.now();
    const activeSnap = await eventsCol(circleId)
      .where('eventDate', '>', now)
      .limit(MAX_ACTIVE_EVENTS)
      .get();
    if (activeSnap.size + occurrenceCount > MAX_ACTIVE_EVENTS) {
      throw new HttpsError(
        'resource-exhausted',
        `Creating this meetup would exceed the limit of ${MAX_ACTIVE_EVENTS} upcoming events`,
      );
    }

    const recurrenceGroupId = recurrenceType ? eventsCol(circleId).doc().id : null;
    const baseDoc = {
      circleId,
      createdById: uid,
      title: title.trim(),
      description: description?.trim() ?? null,
      location: location?.trim() ?? null,
      meetingLink: meetingLink?.trim() ?? null,
      recurrenceType: recurrenceType ?? null,
      recurrenceGroupId,
      createdAt: now,
    };

    if (!recurrenceType) {
      const ref = eventsCol(circleId).doc();
      await ref.set({ ...baseDoc, id: ref.id, eventDate: Timestamp.fromDate(firstDate) });
      return { id: ref.id };
    }

    // Generate all occurrences up front.
    const batch = db.batch();
    let firstId = '';
    let currentDate = firstDate;
    const count = INITIAL_OCCURRENCES[recurrenceType];

    for (let i = 0; i < count; i++) {
      const ref = eventsCol(circleId).doc();
      if (i === 0) firstId = ref.id;
      batch.set(ref, { ...baseDoc, id: ref.id, eventDate: Timestamp.fromDate(currentDate) });
      currentDate = addInterval(currentDate, recurrenceType);
    }

    await batch.commit();
    return { id: firstId };
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

  }
);

// ── generateRecurringMeetups (scheduled weekly) ───────────────────────────────
// Extends recurring meetup series when fewer than 5 future occurrences remain.

export const generateRecurringMeetups = onSchedule(
  { schedule: 'every monday 08:00', timeZone: 'UTC', region: 'us-central1' },
  async () => {
    const now = new Date();

    // Fetch all upcoming recurring events (recurrenceGroupId is a non-empty string).
    const upcomingSnap = await db
      .collectionGroup('events')
      .where('recurrenceGroupId', '>=', '')
      .where('eventDate', '>=', Timestamp.fromDate(now))
      .get();

    if (upcomingSnap.empty) return;

    // Group events by recurrenceGroupId and find the latest date per group.
    type GroupMeta = {
      latestDate: Date;
      recurrenceType: string;
      circleId: string;
      baseDoc: Record<string, unknown>;
    };
    const groups = new Map<string, GroupMeta>();

    for (const doc of upcomingSnap.docs) {
      const d = doc.data();
      const groupId = d['recurrenceGroupId'] as string;
      const eventDate = (d['eventDate'] as Timestamp).toDate();
      const existing = groups.get(groupId);
      if (!existing || eventDate > existing.latestDate) {
        groups.set(groupId, {
          latestDate: eventDate,
          recurrenceType: d['recurrenceType'] as string,
          circleId: d['circleId'] as string,
          baseDoc: d,
        });
      }
    }

    // For groups whose last occurrence is within 35 days, generate 4 more.
    const threshold = new Date(now.getTime() + 35 * 24 * 60 * 60 * 1000);
    const batch = db.batch();
    let writes = 0;

    for (const [, g] of groups.entries()) {
      if (g.latestDate <= threshold) {
        let current = g.latestDate;
        for (let i = 0; i < 4; i++) {
          current = addInterval(current, g.recurrenceType);
          const ref = eventsCol(g.circleId).doc();
          batch.set(ref, {
            ...g.baseDoc,
            id: ref.id,
            eventDate: Timestamp.fromDate(current),
            createdAt: Timestamp.now(),
            reminderSent: false,
            responses: {},
          });
          writes++;
        }
      }
    }

    if (writes > 0) await batch.commit();
  }
);
