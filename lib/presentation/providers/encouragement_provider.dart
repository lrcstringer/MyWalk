import 'package:flutter/foundation.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';

class EncouragementProvider extends ChangeNotifier {
  final CircleRepository _repo;

  EncouragementProvider(this._repo);

  final Map<String, List<Encouragement>> _receivedByCircle = {};
  final Map<String, List<Encouragement>> _sentByCircle = {};
  final Map<String, bool> _loadingByCircle = {};
  bool _sending = false;
  String? error;

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
      final results = await Future.wait([
        _repo.getReceivedEncouragements(circleId),
        _repo.getSentEncouragements(circleId),
      ]);
      _receivedByCircle[circleId] = results[0];
      _sentByCircle[circleId] = results[1];
    } catch (e) {
      error = e.toString();
    } finally {
      _loadingByCircle[circleId] = false;
      notifyListeners();
    }
  }

  Future<void> send({
    required String circleId,
    required String recipientId,
    required EncouragementMessageType messageType,
    String? presetKey,
    String? customText,
    required bool isAnonymous,
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
      );
      // Reload sent list so the new item appears.
      final sent = await _repo.getSentEncouragements(circleId);
      _sentByCircle[circleId] = sent;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _sending = false;
      notifyListeners();
    }
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
