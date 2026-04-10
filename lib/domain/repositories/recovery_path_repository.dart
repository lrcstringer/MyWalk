import '../entities/recovery_path.dart';
import '../entities/recovery_session.dart';

abstract class RecoveryPathRepository {
  /// Loads the recovery path for [habitId], or null if not yet started.
  Future<RecoveryPath?> getPath(String habitId);

  /// Creates a new recovery path document for [habitId].
  /// Returns the created path.
  Future<RecoveryPath> startPath({
    required String habitId,
    required String userId,
  });

  /// Writes back the path document (e.g. after phase change or module update).
  Future<void> updatePath(RecoveryPath path);

  /// Saves a new [RecoverySession]. [responseText] is encrypted before write.
  Future<void> saveSession(RecoverySession session, {required String uid});

  /// Returns all sessions for [habitId], ordered by createdAt descending.
  Future<List<RecoverySession>> getSessions(
    String habitId, {
    required String uid,
    RecoverySessionType? type,
  });

  /// Returns true if a M1 daily check-in already exists for today.
  Future<bool> hasDailyCheckInToday(String habitId);

  /// Returns true if a M3 compass check already exists this week.
  Future<bool> hasWeeklyCompassThisWeek(String habitId);

  /// Deletes the recovery path document and all its sessions for [habitId].
  Future<void> deletePath(String habitId);
}
