import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Maps journal entry IDs to ordered lists of local image file paths.
///
/// Index in each list matches the corresponding index in
/// [JournalEntry.imageUrls], so the caller can zip the two lists.
///
/// After an image uploads to Firebase Storage the staged local file is
/// retained and registered here. Display widgets then prefer the local
/// file over the network URL, enabling offline access and saving egress cost.
class LocalImageCacheService {
  LocalImageCacheService._();
  static final instance = LocalImageCacheService._();

  static const _key = 'local_image_cache';

  SharedPreferences? _prefs;
  Map<String, List<String>> _map = {};

  void init(SharedPreferences prefs) {
    _prefs = prefs;
    _map = _decode(prefs.getString(_key));
  }

  /// Returns a list of length [count] of nullable local paths for [entryId].
  ///
  /// An element is null when no path is registered for that index, or when
  /// the registered file no longer exists on disk (device restore, OS eviction).
  List<String?> getPaths(String entryId, int count) {
    final paths = _map[entryId] ?? [];
    return List.generate(count, (i) {
      if (i >= paths.length || paths[i].isEmpty) return null;
      final path = paths[i];
      if (!File(path).existsSync()) return null;
      return path;
    });
  }

  Future<void> setPath(String entryId, int index, String localPath) async {
    final paths = List<String>.from(_map[entryId] ?? []);
    while (paths.length <= index) { paths.add(''); }
    paths[index] = localPath;
    _map[entryId] = paths;
    await _prefs?.setString(_key, jsonEncode(_map));
  }

  /// Removes the cache entry for [entryId]. Call this when an entry is deleted.
  Future<void> removePaths(String entryId) async {
    if (_map.remove(entryId) != null) {
      await _prefs?.setString(_key, jsonEncode(_map));
    }
  }

  static Map<String, List<String>> _decode(String? raw) {
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map;
      return decoded.map((key, value) => MapEntry(
            key as String,
            (value as List).map((e) => e as String).toList(),
          ));
    } catch (_) {
      return {};
    }
  }
}
