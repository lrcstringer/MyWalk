import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';
import '../../domain/services/week_id_service.dart';

class WeeklyPulseProvider extends ChangeNotifier {
  final CircleRepository _repo;

  WeeklyPulseProvider(this._repo) {
    AuthService.shared.addListener(_onAuthChanged);
  }

  final Map<String, WeeklyPulse?> _pulseByCircle = {};
  final Map<String, PulseResponse?> _myResponseByCircle = {};
  final Map<String, bool> _loadingByCircle = {};
  bool _submitting = false;
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
    _pulseByCircle.clear();
    _myResponseByCircle.clear();
    _loadingByCircle.clear();
    _submitting = false;
    error = null;
    notifyListeners();
  }

  WeeklyPulse? pulseFor(String circleId) => _pulseByCircle[circleId];

  PulseResponse? myResponseFor(String circleId) =>
      _myResponseByCircle[circleId];

  bool hasResponded(String circleId) =>
      _myResponseByCircle[circleId] != null;

  bool isLoading(String circleId) => _loadingByCircle[circleId] ?? false;
  bool get isSubmitting => _submitting;

  Future<void> load(String circleId, String uid) async {
    if (_loadingByCircle[circleId] == true) return;
    _loadingByCircle[circleId] = true;
    error = null;
    notifyListeners();

    try {
      final pulse = await _repo.getCurrentWeeklyPulse(circleId);
      _pulseByCircle[circleId] = pulse;

      if (pulse != null) {
        final myResponse =
            await _repo.getMyPulseResponse(circleId, pulse.id);
        _myResponseByCircle[circleId] = myResponse;
      } else {
        _myResponseByCircle[circleId] = null;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      _loadingByCircle[circleId] = false;
      notifyListeners();
    }
  }

  Future<void> submit({
    required String circleId,
    required PulseStatus status,
    String? note,
    required bool isAnonymous,
    required String uid,
  }) async {
    _submitting = true;
    error = null;
    notifyListeners();

    try {
      await _repo.submitPulseResponse(
        circleId: circleId,
        status: status,
        note: note,
        isAnonymous: isAnonymous,
      );

      // Optimistic local update.
      final weekId = WeekIdService.currentWeekId();
      final response = PulseResponse(
        id: uid,
        userId: isAnonymous ? null : uid,
        userDisplayName: null,
        status: status,
        note: note,
        isAnonymous: isAnonymous,
        createdAt: DateTime.now().toIso8601String(),
      );
      _myResponseByCircle[circleId] = response;

      // Update the summary counts locally.
      final existing = _pulseByCircle[circleId];
      if (existing != null) {
        final updatedSummary = Map<PulseStatus, int>.from(existing.pulseSummary);
        updatedSummary[status] = (updatedSummary[status] ?? 0) + 1;
        _pulseByCircle[circleId] = WeeklyPulse(
          id: existing.id,
          circleId: existing.circleId,
          weekStartDate: existing.weekStartDate,
          responseCount: existing.responseCount + 1,
          pulseSummary: updatedSummary,
          needsPrayerCount: status == PulseStatus.needsPrayer
              ? existing.needsPrayerCount + 1
              : existing.needsPrayerCount,
          responses: existing.responses,
        );
      } else {
        // No pulse doc existed yet — create a local stub.
        _pulseByCircle[circleId] = WeeklyPulse(
          id: weekId,
          circleId: circleId,
          weekStartDate:
              WeekIdService.weekStart(DateTime.now()).toIso8601String(),
          responseCount: 1,
          pulseSummary: {status: 1},
          needsPrayerCount: status == PulseStatus.needsPrayer ? 1 : 0,
        );
      }
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
