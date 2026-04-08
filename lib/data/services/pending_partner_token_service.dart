import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and delivers pending accountability partner invite tokens across
/// the app lifecycle — including tokens received during onboarding.
///
/// Flow:
///   1. `root_view.dart` calls `save(token)` when a deep link for
///      `/accountability/accept/:token` is received.
///   2. `content_view.dart` calls `consume()` on mount (handles tokens saved
///      while the user was in onboarding / app was cold-started).
///   3. While the app is running, `content_view.dart` listens to [stream]
///      and pushes `PartnerAcceptanceScreen` immediately on any new token.
class PendingPartnerTokenService {
  static const _key = 'pending_partner_token';

  final SharedPreferences _prefs;
  final _controller = StreamController<String>.broadcast();

  PendingPartnerTokenService(this._prefs);

  Stream<String> get stream => _controller.stream;

  void save(String token) {
    _prefs.setString(_key, token);
    _controller.add(token);
  }

  String? consume() {
    final token = _prefs.getString(_key);
    if (token != null) _prefs.remove(_key);
    return token;
  }

  void dispose() => _controller.close();
}
