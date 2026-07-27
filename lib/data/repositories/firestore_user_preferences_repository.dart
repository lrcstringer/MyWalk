import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/user_preferences_repository.dart';

/// Firestore-backed implementation of [UserPreferencesRepository].
///
/// Firestore (`users/{uid}/state/prefs`) is the authoritative store so that
/// user preferences survive reinstalls and roam across devices. A
/// SharedPreferences instance serves as a fast local read-cache so that:
///
///   • All reads are synchronous after [init] has been awaited.
///   • Platform services that read SharedPreferences directly (e.g.
///     NotificationService) continue to work without modification.
///
/// Writes are fire-and-forget to Firestore — Firestore's offline persistence
/// queues them and delivers them once the device is online.
class FirestoreUserPreferencesRepository implements UserPreferencesRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final SharedPreferences _cache;

  FirestoreUserPreferencesRepository({
    required FirebaseFirestore db,
    required FirebaseAuth auth,
    required SharedPreferences cache,
  })  : _db = db,
        _auth = auth,
        _cache = cache;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = _uid;
    if (uid == null) return null;
    return _db
        .collection('users')
        .doc(uid)
        .collection('state')
        .doc('prefs');
  }

  /// Pulls the Firestore prefs document and writes every field into the local
  /// SharedPreferences cache. Must be called:
  ///   1. On app startup (handles already-authenticated returning users).
  ///   2. After each sign-in (handles reinstalls and new-device sign-ins).
  Future<void> init() async {
    final uid = _uid;
    if (uid == null) return; // not signed in — nothing to pull
    try {
      // Force server fetch — bypasses the Firestore offline-persistence cache.
      // Without Source.server, the SDK may return stale cached data at startup
      // before the WebSocket connection is established, masking deleted documents
      // and causing tribute_onboarding_complete to remain true even after the
      // users collection was wiped.
      final userSnap = await _db
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      if (!userSnap.exists) {
        await _cache.remove('tribute_onboarding_complete');
        await _cache.remove('tribute_onboarding_date');
        return;
      }
      final snap = await _doc!.get(const GetOptions(source: Source.server));
      if (!snap.exists || snap.data() == null) {
        await _cache.remove('tribute_onboarding_complete');
        await _cache.remove('tribute_onboarding_date');
        return;
      }
      for (final entry in snap.data()!.entries) {
        final v = entry.value;
        if (v is int) {
          await _cache.setInt(entry.key, v);
        } else if (v is bool) {
          await _cache.setBool(entry.key, v);
        } else if (v is String) {
          await _cache.setString(entry.key, v);
        }
      }
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        // Genuinely offline — leave local SharedPreferences as-is.
        return;
      }
      // Any other Firebase error (permission-denied, etc.) — clear the gate
      // keys so a broken server state never permanently locks the user into
      // ContentView without having completed onboarding.
      await _cache.remove('tribute_onboarding_complete');
      await _cache.remove('tribute_onboarding_date');
    } catch (_) {
      await _cache.remove('tribute_onboarding_complete');
      await _cache.remove('tribute_onboarding_date');
    }
  }

  // ── Reads (always from local cache, populated by init()) ─────────────────

  @override
  Future<int?> getInt(String key) async => _cache.getInt(key);

  @override
  Future<bool?> getBool(String key) async => _cache.getBool(key);

  // ── Writes (cache first, then fire-and-forget to Firestore) ──────────────

  @override
  Future<void> setInt(String key, int value) async {
    await _cache.setInt(key, value);
    _doc?.set({key: value}, SetOptions(merge: true));
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _cache.setBool(key, value);
    _doc?.set({key: value}, SetOptions(merge: true));
  }

  @override
  Future<void> remove(String key) async {
    await _cache.remove(key);
    // FieldValue.delete() in set() with merge removes the field without
    // overwriting any other fields in the document.
    _doc?.set({key: FieldValue.delete()}, SetOptions(merge: true));
  }

  @override
  Future<void> clearAll({Set<String> preserve = const {}}) async {
    // Snapshot values to preserve before clearing.
    final saved = <String, Object>{};
    for (final key in preserve) {
      final v = _cache.get(key);
      if (v != null) saved[key] = v;
    }
    await _cache.clear();
    // Restore preserved values.
    for (final entry in saved.entries) {
      final v = entry.value;
      if (v is int) {
        await _cache.setInt(entry.key, v);
      } else if (v is bool) {
        await _cache.setBool(entry.key, v);
      } else if (v is String) {
        await _cache.setString(entry.key, v);
      } else if (v is double) {
        await _cache.setDouble(entry.key, v);
      }
    }
    // Delete the Firestore prefs document so the remote store is also wiped.
    await _doc?.delete();
  }
}
