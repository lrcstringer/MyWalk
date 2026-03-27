/// Domain-layer interface for key-value user preferences.
/// Keeps domain services (WeekCycleManager, EngagementService) free of
/// SharedPreferences / platform infrastructure.
abstract class UserPreferencesRepository {
  Future<int?> getInt(String key);
  Future<bool?> getBool(String key);
  Future<void> setInt(String key, int value);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}
