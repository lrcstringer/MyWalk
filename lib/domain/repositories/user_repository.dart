import '../entities/user_profile.dart';

abstract class UserRepository {
  /// Returns the current user's profile, or null if not authenticated.
  Future<UserProfile?> getProfile();

  /// Creates or merges the profile for the current user.
  /// Uses set-with-merge so partial updates don't overwrite existing fields.
  Future<void> saveProfile(UserProfile profile);

  /// Convenience helper: update individual fields without a full profile read.
  Future<void> updateFields(Map<String, Object?> fields);

  /// Returns true if the user has an active premium subscription.
  Future<bool> isPremium();
}
