import '../entities/habit.dart';
import '../entities/habit_entry.dart';

/// Abstract repository interface for habit persistence.
/// The domain layer depends on this contract; data layer implements it.
abstract class HabitRepository {
  Future<List<Habit>> loadHabits();
  Future<void> insertHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(String habitId);
  Future<void> upsertEntry(HabitEntry entry);
  Future<void> updateHabitSortOrders(List<Habit> habits);
  Future<void> setArchived(String habitId, {required bool archived});
  Future<List<Habit>> loadArchivedHabits();
  /// Deletes all entries for [habitId] and resets its lifetime aggregates to zero.
  /// The habit document itself is preserved.
  Future<void> clearHabitEntries(String habitId);
  /// Atomically writes category fields for multiple habits in a single batch.
  /// [updates] maps habitId → field map (categoryId, subcategoryId, etc.).
  Future<void> batchUpdateCategoryFields(Map<String, Map<String, String?>> updates);
}
