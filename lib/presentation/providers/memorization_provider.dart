import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../data/services/memorization_notification_service.dart';
import '../../data/services/sm2_service.dart';
import '../../domain/entities/memorization_item.dart';
import '../../domain/repositories/memorization_repository.dart';


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
  bool _notificationsRescheduled = false;

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

  bool get canAddItem => _isPremium();

  bool canUseMode(ReviewMode mode) => _isPremium();

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
    _notificationsRescheduled = false;
    notifyListeners();
    _sub = _repository.watchItems().listen(
      (items) {
        _items = items;
        _isLoading = false;
        _error = null;
        if (!_notificationsRescheduled) {
          _notificationsRescheduled = true;
          _rescheduleAllNotifications(items);
        }
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Re-schedules local notifications for all active future-due items.
  // Called once per session on first Firestore snapshot — recovers from OS
  // clearing scheduled notifications after a reboot or reinstall.
  void _rescheduleAllNotifications(List<MemorizationItem> items) {
    final now = DateTime.now();
    for (final item in items) {
      if (item.status == MemorizationStatus.active &&
          item.nextReviewDate.isAfter(now)) {
        MemorizationNotificationService.instance
            .scheduleReviewReminder(item)
            .ignore();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> createItem(MemorizationItem item) async {
    await _repository.saveItem(item);
    MemorizationNotificationService.instance.scheduleReviewReminder(item).ignore();
  }

  Future<void> updateItem(MemorizationItem item) async {
    await _repository.updateItem(item);
    MemorizationNotificationService.instance.scheduleReviewReminder(item).ignore();
  }

  Future<void> deleteItem(MemorizationItem item) async {
    await _repository.deleteItem(item.id);
    MemorizationNotificationService.instance.cancelReminder(item.id).ignore();
  }

  Future<void> deleteAllItems() async {
    final all = List<MemorizationItem>.from(_items);
    await Future.wait(all.map((item) => _repository.deleteItem(item.id)));
  }

  Future<void> archiveItem(MemorizationItem item) async {
    final archived = item.copyWith(status: MemorizationStatus.archived);
    await _repository.updateItem(archived);
    MemorizationNotificationService.instance.cancelReminder(item.id).ignore();
  }

  Future<void> restartItem(MemorizationItem item) async {
    final restarted = item.copyWith(
      status: MemorizationStatus.active,
      repetitionCount: 0,
      intervalDays: 1.0,
      nextReviewDate: DateTime.now(),
      streakCount: 0,
    );
    await _repository.updateItem(restarted);
    MemorizationNotificationService.instance.scheduleReviewReminder(restarted).ignore();
  }

  // ---------------------------------------------------------------------------
  // Review completion — computes SM2 and writes attempt atomically
  // ---------------------------------------------------------------------------

  Future<DateTime> completeReview({
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

    final sm2 = SM2Service.computeNextReview(
      qualityScore: qualityScore,
      currentEF: item.easeFactor,
      currentInterval: item.intervalDays,
      repetitionCount: item.repetitionCount,
      streakCount: item.streakCount,
      scheduledFor: item.nextReviewDate,
      reviewedAt: now,
    );

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

    final updatedChunks = item.chunks.map((chunk) {
      final missed = missedChunkIds.contains(chunk.id);
      return chunk.copyWith(
        attemptCount: chunk.attemptCount + 1,
        successCount: missed ? chunk.successCount : chunk.successCount + 1,
      );
    }).toList();

    final lastReview = item.lastReviewedAt;
    final today = DateTime(now.year, now.month, now.day);
    final int newStreakCount;
    if (lastReview == null) {
      newStreakCount = 1;
    } else {
      final lastDay = DateTime(lastReview.year, lastReview.month, lastReview.day);
      final yesterday = today.subtract(const Duration(days: 1));
      if (lastDay == today) {
        newStreakCount = item.streakCount;
      } else if (lastDay == yesterday) {
        newStreakCount = item.streakCount + 1;
      } else {
        newStreakCount = 1;
      }
    }

    final newSuccessful = qualityScore >= 3
        ? item.successfulAttempts + 1
        : item.successfulAttempts;
    final newTotal = item.totalAttempts + 1;
    final newMastery = newTotal == 0 ? 0.0 : (newSuccessful / newTotal) * 100;
    final newStatus = newMastery >= 90 && sm2.newRepetitionCount >= 3
        ? MemorizationStatus.mastered
        : item.status;

    final newBestStreak = newStreakCount > item.bestStreakCount
        ? newStreakCount
        : item.bestStreakCount;

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
      bestStreakCount: newBestStreak,
      status: newStatus,
    );

    await _repository.saveAttempt(
      attempt: attempt,
      updatedItem: updatedItem,
    );

    MemorizationNotificationService.instance
        .scheduleReviewReminder(updatedItem)
        .ignore();

    _onReviewComplete?.call(updatedItem);
    return updatedItem.nextReviewDate;
  }

  // ---------------------------------------------------------------------------
  // Attempts — stream delegated to repository
  // ---------------------------------------------------------------------------

  Stream<List<ReviewAttempt>> watchAttempts(String itemId) =>
      _repository.watchAttempts(itemId);

  // ---------------------------------------------------------------------------
  // ReviewSession — per-item per-day progress
  // ---------------------------------------------------------------------------

  Future<ReviewSession?> loadTodaySession(String itemId) =>
      _repository.loadSession(itemId, todayKey());

  Future<ReviewSession> markModeComplete(
    ReviewSession session,
    ReviewMode mode,
  ) async {
    final updated = session.withMode(mode);
    await _repository.saveSession(updated);
    return updated;
  }

  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Optional callback — set by the widget tree when wiring habit integration.
  // ---------------------------------------------------------------------------

  void Function(MemorizationItem)? _onReviewComplete;
  void setReviewCompleteCallback(void Function(MemorizationItem) cb) {
    _onReviewComplete = cb;
  }
}
