import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';

class MilestoneShareProvider extends ChangeNotifier {
  final CircleRepository _repo;

  MilestoneShareProvider(this._repo) {
    AuthService.shared.addListener(_onAuthChanged);
  }

  final Map<String, List<MilestoneShare>> _sharesByCircle = {};
  final Map<String, bool> _loadingByCircle = {};
  bool _sharing = false;
  String? error;

  @override
  void dispose() {
    AuthService.shared.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!AuthService.shared.isAuthenticated) _clearAll();
  }

  void _clearAll() {
    _sharesByCircle.clear();
    _loadingByCircle.clear();
    _sharing = false;
    error = null;
    notifyListeners();
  }

  List<MilestoneShare> sharesFor(String circleId) =>
      _sharesByCircle[circleId] ?? [];

  bool isLoading(String circleId) => _loadingByCircle[circleId] ?? false;
  bool get isSharing => _sharing;

  Future<void> load(String circleId) async {
    if (_loadingByCircle[circleId] == true) return;
    _loadingByCircle[circleId] = true;
    error = null;
    notifyListeners();

    try {
      final shares = await _repo.getMilestoneShares(circleId);
      _sharesByCircle[circleId] = shares;
    } catch (e) {
      error = e.toString();
    } finally {
      _loadingByCircle[circleId] = false;
      notifyListeners();
    }
  }

  Future<void> share({
    required List<String> circleIds,
    required MilestoneShareType milestoneType,
    required int milestoneValue,
    required String habitName,
    required String userDisplayName,
  }) async {
    _sharing = true;
    error = null;
    notifyListeners();

    try {
      await _repo.shareMilestone(
        circleIds: circleIds,
        milestoneType: milestoneType,
        milestoneValue: milestoneValue,
        habitName: habitName,
        userDisplayName: userDisplayName,
      );
      // Reload each circle that was shared to.
      for (final circleId in circleIds) {
        if (_sharesByCircle.containsKey(circleId)) {
          final shares = await _repo.getMilestoneShares(circleId);
          _sharesByCircle[circleId] = shares;
        }
      }
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _sharing = false;
      notifyListeners();
    }
  }

  Future<void> celebrate(String circleId, String shareId, String uid) async {
    // Optimistic update.
    final shares = _sharesByCircle[circleId];
    if (shares != null) {
      final idx = shares.indexWhere((s) => s.id == shareId);
      if (idx >= 0 && !shares[idx].hasCelebrated(uid)) {
        final s = shares[idx];
        final updated = List<MilestoneShare>.from(shares);
        updated[idx] = MilestoneShare(
          id: s.id,
          circleId: s.circleId,
          userId: s.userId,
          userDisplayName: s.userDisplayName,
          milestoneType: s.milestoneType,
          milestoneValue: s.milestoneValue,
          habitName: s.habitName,
          celebrationCount: s.celebrationCount + 1,
          celebratedByUserIds: [...s.celebratedByUserIds, uid],
          createdAt: s.createdAt,
        );
        _sharesByCircle[circleId] = updated;
        notifyListeners();
      }
    }

    try {
      await _repo.celebrateMilestone(circleId, shareId);
    } catch (_) {
      // Roll back.
      final refreshed = await _repo.getMilestoneShares(circleId);
      _sharesByCircle[circleId] = refreshed;
      notifyListeners();
    }
  }
}
