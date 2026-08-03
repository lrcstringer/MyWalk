import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';

class EncouragementProvider extends ChangeNotifier {
  final CircleRepository _repo;

  EncouragementProvider(this._repo) {
    AuthService.shared.addListener(_onAuthChanged);
  }

  final Map<String, List<Encouragement>> _receivedByCircle = {};
  final Map<String, List<Encouragement>> _sentByCircle = {};
  final Map<String, bool> _loadingByCircle = {};
  bool _sending = false;
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
    _receivedByCircle.clear();
    _sentByCircle.clear();
    _loadingByCircle.clear();
    _sending = false;
    error = null;
    notifyListeners();
  }

  List<Encouragement> receivedFor(String circleId) =>
      _receivedByCircle[circleId] ?? [];

  List<Encouragement> sentFor(String circleId) =>
      _sentByCircle[circleId] ?? [];

  int unreadCountFor(String circleId) =>
      (_receivedByCircle[circleId] ?? []).where((e) => !e.isRead).length;

  bool isLoading(String circleId) => _loadingByCircle[circleId] ?? false;
  bool get isSending => _sending;

  Future<void> load(String circleId) async {
    if (_loadingByCircle[circleId] == true) return;
    _loadingByCircle[circleId] = true;
    error = null;
    notifyListeners();

    try {
      _receivedByCircle[circleId] = await _repo.getReceivedEncouragements(circleId);
    } catch (e) {
      error = e.toString();
    }
    try {
      _sentByCircle[circleId] = await _repo.getSentEncouragements(circleId);
    } catch (e) {
      error ??= e.toString();
    }

    _loadingByCircle[circleId] = false;
    notifyListeners();
  }

  Future<void> send({
    required String circleId,
    required String recipientId,
    required EncouragementMessageType messageType,
    String? presetKey,
    String? customText,
    required bool isAnonymous,
    bool notifyViaInbox = true,
  }) async {
    _sending = true;
    error = null;
    notifyListeners();

    try {
      await _repo.sendEncouragement(
        circleId: circleId,
        recipientId: recipientId,
        messageType: messageType,
        presetKey: presetKey,
        customText: customText,
        isAnonymous: isAnonymous,
        notifyViaInbox: notifyViaInbox,
      );
    } catch (e) {
      error = e.toString();
      _sending = false;
      notifyListeners();
      rethrow;
    }

    _sending = false;
    notifyListeners();
    // Reload both lists. Best-effort: if queued offline, this will return
    // stale data — the screen refreshes correctly on the next load() call.
    await load(circleId);
  }

  Future<void> markRead(String circleId, String encouragementId) async {
    // Optimistic update.
    final received = _receivedByCircle[circleId];
    if (received != null) {
      final idx = received.indexWhere((e) => e.id == encouragementId);
      if (idx >= 0 && !received[idx].isRead) {
        final updated = List<Encouragement>.from(received);
        final e = updated[idx];
        updated[idx] = Encouragement(
          id: e.id,
          circleId: e.circleId,
          senderId: e.senderId,
          senderDisplayName: e.senderDisplayName,
          recipientId: e.recipientId,
          messageType: e.messageType,
          presetKey: e.presetKey,
          customText: e.customText,
          isAnonymous: e.isAnonymous,
          isRead: true,
          createdAt: e.createdAt,
        );
        _receivedByCircle[circleId] = updated;
        notifyListeners();
      }
    }

    try {
      await _repo.markEncouragementRead(circleId, encouragementId);
    } catch (_) {
      // Best-effort — don't roll back the visual state to avoid flickering.
    }
  }
}
