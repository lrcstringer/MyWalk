import '../entities/memorization_circle.dart';
import '../entities/memorization_item.dart';

abstract class MemorizationRepository {
  // ---------------------------------------------------------------------------
  // MemorizationItem — CRUD + stream
  // ---------------------------------------------------------------------------

  /// Real-time stream of all active/mastered items for the current user,
  /// sorted by nextReviewDate ascending (most overdue first).
  Stream<List<MemorizationItem>> watchItems();

  /// One-shot fetch of all items.
  Future<List<MemorizationItem>> loadItems();

  /// Persist a newly created item.
  Future<void> saveItem(MemorizationItem item);

  /// Merge-update an existing item document.
  Future<void> updateItem(MemorizationItem item);

  /// Hard-delete an item and its sub-collections.
  Future<void> deleteItem(String itemId);

  // ---------------------------------------------------------------------------
  // ReviewAttempt — sub-collection writes
  // ---------------------------------------------------------------------------

  /// Record a completed review attempt and update the parent item's SM2 state
  /// atomically (Firestore batch write).
  Future<void> saveAttempt({
    required ReviewAttempt attempt,
    required MemorizationItem updatedItem,
  });

  /// Stream of attempts for a single item, newest first.
  Stream<List<ReviewAttempt>> watchAttempts(String itemId);

  // ---------------------------------------------------------------------------
  // Sharing — /users/{uid}/memorizations/{itemId}/shares/
  // ---------------------------------------------------------------------------

  /// Grant a friend read access to this item's progress.
  Future<void> shareItem({
    required String itemId,
    required String friendUid,
  });

  /// Revoke a friend's read access.
  Future<void> unshareItem({
    required String itemId,
    required String friendUid,
  });

  /// Stream of items shared WITH the current user by others.
  Stream<List<MemorizationItem>> watchSharedWithMe();

  // ---------------------------------------------------------------------------
  // MemorizationCircles — /memorizationCircles/
  // ---------------------------------------------------------------------------

  Stream<List<MemorizationCircle>> watchCircles();

  Future<void> saveCircle(MemorizationCircle circle);

  Future<void> updateCircle(MemorizationCircle circle);

  /// Update a single member's mastery % in the circle leaderboard.
  Future<void> updateMemberMastery({
    required String circleId,
    required String uid,
    required double masteryPercent,
  });

  // ---------------------------------------------------------------------------
  // Circle comments — /memorizationCircles/{circleId}/comments/
  // ---------------------------------------------------------------------------

  /// Real-time stream of comments for a circle, newest first (limit 50).
  Stream<List<CircleComment>> watchCircleComments(String circleId);

  /// Post a comment to a circle.
  Future<void> addCircleComment({
    required String circleId,
    required String text,
  });
}
