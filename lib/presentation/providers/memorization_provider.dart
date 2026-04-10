import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../data/services/memorization_notification_service.dart';
import '../../data/services/sm2_service.dart';
import '../../domain/entities/memorization_circle.dart';
import '../../domain/entities/memorization_item.dart';
import '../../domain/repositories/memorization_repository.dart';

// Free-tier limits
const _freeItemLimit = 3;
const _freeModes = {ReviewMode.flipCard, ReviewMode.cloze};

class MemorizationProvider extends ChangeNotifier {
  final MemorizationRepository _repository;
  final bool Function() _isPremium;

  MemorizationProvider(this._repository, this._isPremium) {
    AuthService.shared.addListener(_onAuthChanged);
    if (AuthService.shared.isAuthenticated) _subscribe();
  }

  List<MemorizationItem> _items = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<MemorizationItem>>? _sub;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MemorizationItem> get items => _items;

  List<MemorizationItem> get dueItems =>
      _items.where((i) => i.isDueNow && i.status == MemorizationStatus.active).toList();

  List<MemorizationItem> get activeItems =>
      _items.where((i) => i.status == MemorizationStatus.active).toList();

  List<MemorizationItem> get masteredItems =>
      _items.where((i) => i.status == MemorizationStatus.mastered).toList();

  bool get canAddItem =>
      _isPremium() || activeItems.length < _freeItemLimit;

  bool canUseMode(ReviewMode mode) =>
      _isPremium() || _freeModes.contains(mode);

  bool get showAnalyticsDashboard => _isPremium();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _sub?.cancel();
    AuthService.shared.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (AuthService.shared.isAuthenticated) {
      _subscribe();
    } else {
      _sub?.cancel();
      _sub = null;
      _items = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribe() {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _repository.watchItems().listen(
      (items) {
        _items = items;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> createItem(MemorizationItem item) async {
    _repository.saveItem(item).ignore();
    MemorizationNotificationService.instance.scheduleReviewReminder(item).ignore();
  }

  Future<void> updateItem(MemorizationItem item) async {
    _repository.updateItem(item).ignore();
    MemorizationNotificationService.instance.scheduleReviewReminder(item).ignore();
  }

  Future<void> deleteAllItems() async {
    final all = List<MemorizationItem>.from(_items);
    await Future.wait(all.map((item) => _repository.deleteItem(item.id)));
  }

  Future<void> archiveItem(MemorizationItem item) async {
    final archived = item.copyWith(status: MemorizationStatus.archived);
    _repository.updateItem(archived).ignore();
    MemorizationNotificationService.instance.cancelReminder(item.id).ignore();
  }

  // ---------------------------------------------------------------------------
  // Review completion — computes SM2 and writes attempt atomically
  // ---------------------------------------------------------------------------

  Future<void> completeReview({
    required MemorizationItem item,
    required ReviewMode mode,
    required int qualityScore,
    required int confidence,
    required int timeToRecallSeconds,
    required List<String> missedChunkIds,
    String? userResponse,
    double? levenshteinScore,
    bool isInitialReview = false,
  }) async {
    final now = DateTime.now();

    // Compute SM2 result.
    final sm2 = SM2Service.computeNextReview(
      qualityScore: qualityScore,
      currentEF: item.easeFactor,
      currentInterval: item.intervalDays,
      repetitionCount: item.repetitionCount,
      streakCount: item.streakCount,
      scheduledFor: item.nextReviewDate,
      reviewedAt: now,
    );

    // Build the attempt record.
    final attempt = ReviewAttempt.create(
      mode: mode,
      qualityScore: qualityScore,
      confidence: confidence,
      timeToRecallSeconds: timeToRecallSeconds,
      missedChunkIds: missedChunkIds,
      userResponse: userResponse,
      levenshteinScore: levenshteinScore,
      isInitialReview: isInitialReview,
      nextReviewScheduledFor: sm2.nextReviewDate,
      intervalDaysApplied: sm2.newInterval,
      easeFactorAfter: sm2.newEaseFactor,
    );

    // Update chunk strength scores.
    final updatedChunks = item.chunks.map((chunk) {
      final missed = missedChunkIds.contains(chunk.id);
      return chunk.copyWith(
        attemptCount: chunk.attemptCount + 1,
        successCount: missed ? chunk.successCount : chunk.successCount + 1,
      );
    }).toList();

    // Compute streak based on consecutive review days.
    final lastReview = item.lastReviewedAt;
    final today = DateTime(now.year, now.month, now.day);
    final int newStreakCount;
    if (lastReview == null) {
      newStreakCount = 1;
    } else {
      final lastDay = DateTime(lastReview.year, lastReview.month, lastReview.day);
      final yesterday = today.subtract(const Duration(days: 1));
      if (lastDay == today) {
        newStreakCount = item.streakCount; // already reviewed today, no change
      } else if (lastDay == yesterday) {
        newStreakCount = item.streakCount + 1; // consecutive day
      } else {
        newStreakCount = 1; // streak broken — reset
      }
    }

    // Determine if item has crossed mastery threshold (masteryPercent >= 90%).
    final newSuccessful = qualityScore >= 3
        ? item.successfulAttempts + 1
        : item.successfulAttempts;
    final newTotal = item.totalAttempts + 1;
    final newMastery = newTotal == 0 ? 0.0 : (newSuccessful / newTotal) * 100;
    // Use sm2.newRepetitionCount (post-update value), not item.repetitionCount (pre-update).
    final newStatus = newMastery >= 90 && sm2.newRepetitionCount >= 3
        ? MemorizationStatus.mastered
        : item.status;

    final updatedItem = item.copyWith(
      chunks: updatedChunks,
      lastReviewedAt: now,
      nextReviewDate: sm2.nextReviewDate,
      intervalDays: sm2.newInterval,
      easeFactor: sm2.newEaseFactor,
      repetitionCount: sm2.newRepetitionCount,
      totalAttempts: newTotal,
      successfulAttempts: newSuccessful,
      streakCount: newStreakCount,
      status: newStatus,
    );

    // Atomic Firestore batch: attempt + updated item.
    // Firestore queues writes offline and syncs when connectivity returns.
    await _repository.saveAttempt(
      attempt: attempt,
      updatedItem: updatedItem,
    );

    // Schedule the next review reminder (local + FCM).
    MemorizationNotificationService.instance
        .scheduleReviewReminder(updatedItem)
        .ignore();

    // If linked to a habit sub-category, trigger a habit check-in.
    // (Habit integration wired via callback to avoid a circular provider dependency.)
    _onReviewComplete?.call(updatedItem);
  }

  // ---------------------------------------------------------------------------
  // Attempts — stream delegated to repository
  // ---------------------------------------------------------------------------

  Stream<List<ReviewAttempt>> watchAttempts(String itemId) =>
      _repository.watchAttempts(itemId);

  // ---------------------------------------------------------------------------
  // Circles — delegated to repository
  // ---------------------------------------------------------------------------

  Stream<List<MemorizationCircle>> watchCircles() =>
      _repository.watchCircles();

  Future<void> saveCircle(MemorizationCircle circle) =>
      _repository.saveCircle(circle);

  Future<void> updateCircle(MemorizationCircle circle) =>
      _repository.updateCircle(circle);

  Future<void> updateMemberMastery({
    required String circleId,
    required String uid,
    required double masteryPercent,
  }) =>
      _repository.updateMemberMastery(
        circleId: circleId,
        uid: uid,
        masteryPercent: masteryPercent,
      );

  Stream<List<CircleComment>> watchCircleComments(String circleId) =>
      _repository.watchCircleComments(circleId);

  Future<void> addCircleComment({
    required String circleId,
    required String text,
  }) =>
      _repository.addCircleComment(circleId: circleId, text: text);

  // ---------------------------------------------------------------------------
  // Optional callback — set by the widget tree when wiring habit integration.
  // ---------------------------------------------------------------------------

  void Function(MemorizationItem)? _onReviewComplete;
  void setReviewCompleteCallback(void Function(MemorizationItem) cb) {
    _onReviewComplete = cb;
  }
}
