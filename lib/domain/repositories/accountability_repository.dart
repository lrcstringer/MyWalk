import '../entities/accountability_partnership.dart';
import '../entities/partner_message.dart';

abstract class AccountabilityRepository {
  /// Creates a new partnership doc and returns the share URL.
  Future<String> createInvite({
    required String habitId,
    required String habitName,
    required String ownerDisplayName,
  });

  /// Accepts a pending partnership via its invite token.
  /// Returns the accepted [AccountabilityPartnership].
  Future<AccountabilityPartnership> acceptViaToken({
    required String token,
    required String partnerDisplayName,
  });

  /// Declines a pending partnership via its invite token.
  Future<void> declineViaToken(String token);

  /// Owner cancels a pending or active partnership.
  Future<void> cancelPartnership(String partnershipId);

  /// Either participant ends an active partnership.
  Future<void> endPartnership(String partnershipId);

  /// Sends a message within a partnership. Batch-writes: message doc +
  /// updates lastMessagePreview/lastMessageAt on the partnership.
  Future<void> sendMessage({
    required String partnershipId,
    required String body,
    required String senderDisplayName,
  });

  /// Marks all unread messages in a partnership as read by the current user.
  Future<void> markMessagesRead(String partnershipId);

  /// Stream of all partnerships where the current user is a participant.
  Stream<List<AccountabilityPartnership>> watchPartnershipsForUser();

  /// Stream of messages for a given partnership, ordered oldest-first.
  Stream<List<PartnerMessage>> watchMessages(String partnershipId);

  /// Looks up a partnership by invite token (for the acceptance screen).
  /// Returns null if not found or already used.
  Future<AccountabilityPartnership?> findByToken(String token);
}
