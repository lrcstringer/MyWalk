import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Maps journal entry IDs to local voice file paths for offline playback.
///
/// After a voice note uploads to Firebase Storage, the local staged file is
/// retained and registered here. Playback then prefers the local file over
/// the network URL, enabling offline playback even after the upload completes.
///
/// [_map] is the single source of truth and is mutated synchronously before
/// any async persist, eliminating the read-modify-write race that a
/// SharedPreferences-only approach would have.
class LocalVoiceCacheService {
  LocalVoiceCacheService._();
  static final instance = LocalVoiceCacheService._();

  static const _key = 'local_voice_cache';

  SharedPreferences? _prefs;
  Map<String, String> _map = {};

  /// Must be called once (e.g. from [MediaUploadService.init]) before writes
  /// are persisted. Reads are always safe; they return null until init is called.
  void init(SharedPreferences prefs) {
    _prefs = prefs;
    _map = _decode(prefs.getString(_key));
  }

  /// Returns the local path for [entryId], or null if:
  ///   • no path is registered, or
  ///   • the file no longer exists on disk (device restore, OS eviction).
  String? getPath(String entryId) {
    final path = _map[entryId];
    if (path == null) return null;
    if (!File(path).existsSync()) return null;
    return path;
  }

  Future<void> setPath(String entryId, String localPath) async {
    _map[entryId] = localPath;                                     // synchronous
    await _prefs?.setString(_key, jsonEncode(_map));
  }

  Future<void> removePath(String entryId) async {
    if (_map.remove(entryId) != null) {                            // synchronous
      await _prefs?.setString(_key, jsonEncode(_map));
    }
  }

  static Map<String, String> _decode(String? raw) {
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }
}
