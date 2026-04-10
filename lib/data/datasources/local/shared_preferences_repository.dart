import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/user_preferences_repository.dart';

class SharedPreferencesRepository implements UserPreferencesRepository {
  // Cache the instance to avoid the overhead of resolving the singleton on every call.
  late final Future<SharedPreferences> _instance = SharedPreferences.getInstance();

  // Local-only implementation — always in sync, nothing to pull from a remote store.
  @override
  Future<void> init() async {}

  @override
  Future<int?> getInt(String key) async => (await _instance).getInt(key);

  @override
  Future<bool?> getBool(String key) async => (await _instance).getBool(key);

  @override
  Future<void> setInt(String key, int value) async =>
      (await _instance).setInt(key, value);

  @override
  Future<void> setBool(String key, bool value) async =>
      (await _instance).setBool(key, value);

  @override
  Future<void> remove(String key) async => (await _instance).remove(key);

  @override
  Future<void> clearAll({Set<String> preserve = const {}}) async {
    final prefs = await _instance;
    final saved = <String, Object>{};
    for (final key in preserve) {
      final v = prefs.get(key);
      if (v != null) saved[key] = v;
    }
    await prefs.clear();
    for (final entry in saved.entries) {
      final v = entry.value;
      if (v is int) {
        await prefs.setInt(entry.key, v);
      } else if (v is bool) {
        await prefs.setBool(entry.key, v);
      } else if (v is String) {
        await prefs.setString(entry.key, v);
      } else if (v is double) {
        await prefs.setDouble(entry.key, v);
      }
    }
  }
}
