import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/auth_service.dart';
import '../../domain/entities/circle_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class CircleNotificationProvider extends ChangeNotifier {
  final NotificationRepository _repo;

  List<CircleNotification> _notifications = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<CircleNotification>>? _sub;

  CircleNotificationProvider(this._repo) {
    // Subscribe now if already authenticated, then track auth changes.
    _subscribeIfAuthenticated();
    AuthService.shared.addListener(_onAuthChanged);
  }

  List<CircleNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  void _onAuthChanged() {
    if (AuthService.shared.isAuthenticated) {
      _subscribeIfAuthenticated();
    } else {
      _cancelSubscription();
      _notifications = [];
      _error = null;
      notifyListeners();
    }
  }

  void _subscribeIfAuthenticated() {
    if (!AuthService.shared.isAuthenticated) return;
    _sub?.cancel();
    _sub = _repo.watchInbox().listen(
      (list) {
        _notifications = list;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  void _cancelSubscription() {
    _sub?.cancel();
    _sub = null;
  }

  /// Re-subscribes to the inbox stream — forces Firestore to re-emit the
  /// latest snapshot. Used by pull-to-refresh.
  Future<void> refresh() async {
    _subscribeIfAuthenticated();
  }

  Future<void> markRead(String notifId) async {
    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx == -1) return;
    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    notifyListeners();
    await _repo.markRead(notifId);
  }

  Future<void> recordAction(String notifId, NotificationAction action) async {
    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx == -1) return;
    _notifications[idx] = _notifications[idx].copyWith(
      isRead: true,
      actionTaken: action,
    );
    notifyListeners();
    await _repo.recordAction(notifId, action);
  }

  Future<void> sendAnnouncement({
    required String circleId,
    required String message,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      await _repo.sendAnnouncement(circleId: circleId, message: message);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> sendPrayerRequest({
    required String circleId,
    required String message,
    required List<String> recipientIds,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      await _repo.sendPrayerRequest(
        circleId: circleId,
        message: message,
        recipientIds: recipientIds,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    AuthService.shared.removeListener(_onAuthChanged);
    _sub?.cancel();
    super.dispose();
  }
}
