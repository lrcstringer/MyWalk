import '../entities/memorization_item.dart';

abstract class MemorizationRepository {
  // ---------------------------------------------------------------------------
  // MemorizationItem — CRUD + stream
  // ---------------------------------------------------------------------------

  Stream<List<MemorizationItem>> watchItems();

  Future<List<MemorizationItem>> loadItems();

  Future<void> saveItem(MemorizationItem item);

  Future<void> updateItem(MemorizationItem item);

  Future<void> deleteItem(String itemId);

  // ---------------------------------------------------------------------------
  // ReviewAttempt — sub-collection writes
  // ---------------------------------------------------------------------------

  Future<void> saveAttempt({
    required ReviewAttempt attempt,
    required MemorizationItem updatedItem,
  });

  Stream<List<ReviewAttempt>> watchAttempts(String itemId);
}
