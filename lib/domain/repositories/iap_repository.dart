/// Domain interface for In-App Purchase status and server validation.
///
/// Clean Architecture: this interface lives in the domain layer.
/// The presentation layer (StoreProvider) depends only on this abstraction;
/// the data layer (FirestoreIAPRepository) provides the implementation.
abstract class IAPRepository {
  /// Returns the current premium status from the source of truth (Firestore).
  ///
  /// Returns:
  ///   `true`  — user has an active, non-expired subscription or lifetime purchase.
  ///   `false` — no active subscription found, or user is not authenticated.
  ///   `null`  — a transient network error occurred; caller should leave the
  ///             current [isPremium] value unchanged (optimistic for existing users).
  Future<bool?> getPremiumStatus();

  /// Sends a purchase receipt or token to the server-side validation function,
  /// which writes the authoritative [SubscriptionStatus] to Firestore and
  /// returns whether the purchase grants premium access.
  ///
  /// Exactly one of [purchaseToken] (Android) or [receiptData] (iOS) must be
  /// non-null, matching [platform].
  ///
  /// Throws if the user is not authenticated or if the callable function fails.
  Future<bool> validateReceipt({
    required String platform,
    required String productId,
    String? purchaseToken,
    String? receiptData,
  });
}
