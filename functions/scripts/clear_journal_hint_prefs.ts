/**
 * One-time script: remove journal_intro_seen and journal_skin_hint_shown from
 * every user's Firestore prefs document.
 *
 * These are device-local UI flags that were mistakenly written to Firestore by
 * an earlier version of the app. After this script runs they will never appear
 * in Firestore again (the app now writes them to raw SharedPreferences only).
 *
 * Run from the functions/ directory:
 *   npx ts-node --project tsconfig.json scripts/clear_journal_hint_prefs.ts
 *
 * Requires Application Default Credentials:
 *   firebase login (CLI auth is sufficient for ADC in most setups)
 */

import * as admin from 'firebase-admin';

admin.initializeApp({ projectId: 'tribute-8063d' });
const db = admin.firestore();

const KEYS_TO_DELETE = ['journal_intro_seen', 'journal_skin_hint_shown'];
const BATCH_SIZE = 400;

async function run(): Promise<void> {
  const usersSnap = await db.collection('users').get();
  console.log(`Found ${usersSnap.size} user(s).`);

  const refs: admin.firestore.DocumentReference[] = [];
  for (const userDoc of usersSnap.docs) {
    const prefsRef = db
      .collection('users')
      .doc(userDoc.id)
      .collection('state')
      .doc('prefs');
    const prefsSnap = await prefsRef.get();
    if (!prefsSnap.exists) continue;
    const data = prefsSnap.data() ?? {};
    const hasAny = KEYS_TO_DELETE.some((k) => k in data);
    if (hasAny) refs.push(prefsRef);
  }

  console.log(`${refs.length} prefs document(s) contain the keys — clearing.`);

  const update: Record<string, admin.firestore.FieldValue> = {};
  for (const k of KEYS_TO_DELETE) {
    update[k] = admin.firestore.FieldValue.delete();
  }

  for (let i = 0; i < refs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    for (const ref of refs.slice(i, i + BATCH_SIZE)) {
      batch.update(ref, update);
    }
    await batch.commit();
    console.log(`Committed batch up to ${i + BATCH_SIZE}.`);
  }

  console.log('Done.');
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
