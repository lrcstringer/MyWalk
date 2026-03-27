import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/user_preferences_repository.dart';

class SharedPreferencesRepository implements UserPreferencesRepository {
  @override
  Future<int?> getInt(String key) async =>
      (await SharedPreferences.getInstance()).getInt(key);

  @override
  Future<bool?> getBool(String key) async =>
      (await SharedPreferences.getInstance()).getBool(key);

  @override
  Future<void> setInt(String key, int value) async =>
      (await SharedPreferences.getInstance()).setInt(key, value);

  @override
  Future<void> setBool(String key, bool value) async =>
      (await SharedPreferences.getInstance()).setBool(key, value);

  @override
  Future<void> remove(String key) async =>
      (await SharedPreferences.getInstance()).remove(key);
}
