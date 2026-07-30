import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/api_service.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';

class PrayerListProvider extends ChangeNotifier {
  final CircleRepository _repo;

  PrayerListProvider(this._repo) {
    AuthService.shared.addListener(_onAuthChanged);
  }

  final Map<String, List<PrayerRequest>> _activeByCircle = {};
  final Map<String, List<PrayerRequest>> _answeredByCircle = {};
  final Map<String, List<PrayerRequest>> _individualByCircle = {};
  final Map<String, bool> _loadingByCircle = {};
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
    _activeByCircle.clear();
    _answeredByCircle.clear();
    _individualByCircle.clear();
    _loadingByCircle.clear();
    error = null;
    notifyListeners();
  }

  List<PrayerRequest> activeFor(String circleId) =>
      _activeByCircle[circleId] ?? [];

  List<PrayerRequest> answeredFor(String circleId) =>
      _answeredByCircle[circleId] ?? [];

  List<PrayerRequest> individualFor(String circleId) =>
      _individualByCircle[circleId] ?? [];

  bool isLoading(String circleId) => _loadingByCircle[circleId] ?? false;

  Future<void> load(String circleId) async {
    // Guard: don't start a second concurrent load for the same circle.
    if (_loadingByCircle[circleId] == true) return;
    _loadingByCircle[circleId] = true;
    error = null;
    notifyListeners();

    try {
      final uid = AuthService.shared.userId ?? '';
      final results = await Future.wait<List<PrayerRequest>>([
        _repo.getPrayerRequests(circleId),
        uid.isNotEmpty
            ? _repo.getIndividualPrayerRequests(circleId, uid)
            : Future.value(<PrayerRequest>[]),
      ]);
      final grouped = results[0].where((r) => !r.isIndividual).toList();
      _activeByCircle[circleId] =
          grouped.where((r) => r.status == PrayerRequestStatus.active).toList();
      _answeredByCircle[circleId] =
          grouped.where((r) => r.status == PrayerRequestStatus.answered).toList();
      _individualByCircle[circleId] = results[1];
    } catch (e) {
      error = e.toString();
    } finally {
      _loadingByCircle[circleId] = false;
      notifyListeners();
    }
  }

  Future<void> createRequest({
    required String circleId,
    required String text,
    required PrayerDuration duration,
    bool anonymous = false,
  }) async {
    await _repo.createPrayerRequest(
      circleId: circleId,
      requestText: text,
      duration: duration,
      anonymous: anonymous,
    );
    // Reload to reflect server-calculated expiresAt.
    await load(circleId);
  }

  Future<void> prayFor(String circleId, String requestId, String uid) async {
    // Optimistic update: increment count + add uid locally before server confirms.
    _updateRequest(circleId, requestId, (r) {
      if (r.hasPrayed(uid)) return r;
      final newIds = [...r.prayedByUserIds, uid];
      return PrayerRequest(
        id: r.id,
        circleId: r.circleId,
        authorId: r.authorId,
        authorDisplayName: r.authorDisplayName,
        requestText: r.requestText,
        duration: r.duration,
        status: r.status,
        answeredNote: r.answeredNote,
        prayerCount: r.prayerCount + 1,
        prayedByUserIds: newIds,
        createdAt: r.createdAt,
        answeredAt: r.answeredAt,
        expiresAt: r.expiresAt,
        isIndividual: r.isIndividual,
        recipientIds: r.recipientIds,
      );
    });
    notifyListeners();

    try {
      await _repo.prayForRequest(circleId, requestId);
    } catch (_) {
      // Roll back on failure by reloading from source.
      await load(circleId);
    }
  }

  Future<void> markAnswered(String circleId, String requestId,
      {String? answeredNote}) async {
    await _repo.markPrayerAnswered(circleId, requestId,
        answeredNote: answeredNote);
    await load(circleId);
  }

  Future<void> respondToIndividualRequest(
      String circleId, String requestId, String uid, String action) async {
    _updateIndividualRequest(circleId, requestId, (r) {
      final newResponses = Map<String, String>.from(r.responses)..[uid] = action;
      return PrayerRequest(
        id: r.id,
        circleId: r.circleId,
        authorId: r.authorId,
        authorDisplayName: r.authorDisplayName,
        requestText: r.requestText,
        duration: r.duration,
        status: r.status,
        answeredNote: r.answeredNote,
        prayerCount: r.prayerCount,
        prayedByUserIds: r.prayedByUserIds,
        createdAt: r.createdAt,
        answeredAt: r.answeredAt,
        expiresAt: r.expiresAt,
        isIndividual: r.isIndividual,
        recipientIds: r.recipientIds,
        responses: newResponses,
      );
    });
    notifyListeners();

    try {
      await APIService.shared.respondToIndividualPrayerRequest(
          circleId: circleId, requestId: requestId, action: action);
    } catch (_) {
      await load(circleId);
    }
  }

  Future<void> shareGratitude({
    required String circleId,
    required String text,
    required bool isAnonymous,
  }) =>
      _repo.shareGratitude(
        circleIds: [circleId],
        gratitudeText: text,
        isAnonymous: isAnonymous,
      );

  void _updateIndividualRequest(String circleId, String requestId,
      PrayerRequest Function(PrayerRequest) updater) {
    final individual = _individualByCircle[circleId];
    if (individual == null) return;
    final idx = individual.indexWhere((r) => r.id == requestId);
    if (idx < 0) return;
    final updated = [...individual];
    updated[idx] = updater(individual[idx]);
    _individualByCircle[circleId] = updated;
  }

  void _updateRequest(String circleId, String requestId,
      PrayerRequest Function(PrayerRequest) updater) {
    final active = _activeByCircle[circleId];
    if (active == null) return;
    final idx = active.indexWhere((r) => r.id == requestId);
    if (idx < 0) return;
    final updated = [...active];
    updated[idx] = updater(active[idx]);
    _activeByCircle[circleId] = updated;
  }
}
