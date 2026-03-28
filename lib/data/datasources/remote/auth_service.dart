import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService shared = AuthService._();
  AuthService._();

  bool _isAuthenticated = false;
  String? _userId;
  String? _displayName;
  String? _givenName;
  bool _isLoading = false;
  String? _error;
  // Guards against double-registration of the Firebase auth listener.
  bool _initCalled = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get displayName => _displayName;
  /// First name only — use for personalisation ("What is God working on in your life, Lance?").
  /// Apple provides this directly on first sign-in; Google derives it from displayName.
  String? get givenName => _givenName;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// True when the device should use Apple Sign In (iOS), false for Google (Android).
  static bool get isApplePlatform => Platform.isIOS || Platform.isMacOS;

  Future<void> init() async {
    if (_initCalled) return;
    _initCalled = true;

    // Restore display name and given name from local storage
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString('tribute_display_name');
    _givenName = prefs.getString('tribute_given_name');

    // Listen for Firebase Auth state changes and keep APIService token in sync
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        _userId = user.uid;
        _isAuthenticated = true;
        final token = await user.getIdToken();
        APIService.shared.setFirebaseToken(token, userId: user.uid);
      } else {
        _userId = null;
        _isAuthenticated = false;
        APIService.shared.setFirebaseToken(null);
      }
      notifyListeners();
    });

    // Set initial state synchronously from current user
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      _userId = current.uid;
      _isAuthenticated = true;
      final token = await current.getIdToken();
      APIService.shared.setFirebaseToken(token, userId: current.uid);
      notifyListeners();
    }
  }

  // ── Platform-aware sign-in entry point ───────────────────────────────────

  /// Signs in using Apple on iOS/macOS and Google on Android.
  Future<void> signIn() async {
    if (isApplePlatform) {
      await signInWithApple();
    } else {
      await signInWithGoogle();
    }
  }

  // ── Apple Sign In ─────────────────────────────────────────────────────────

  Future<void> signInWithApple() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256OfString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
      final user = userCredential.user;
      if (user == null) throw StateError('Apple sign-in completed but Firebase returned a null user');

      // Apple only provides name on the very first sign-in
      String? name;
      if (credential.givenName != null) {
        name = [credential.givenName, credential.familyName]
            .whereType<String>()
            .join(' ')
            .trim();
        if (name.isEmpty) name = null;
      }
      _displayName = name ?? user.displayName ?? _displayName;
      // Store given name separately for personalisation
      if (credential.givenName != null && credential.givenName!.isNotEmpty) {
        _givenName = credential.givenName;
      }

      final idToken = await user.getIdToken();
      APIService.shared.setFirebaseToken(idToken, userId: user.uid);
      _userId = user.uid;
      _isAuthenticated = true;

      // Ensure Firestore user doc exists
      final response = await APIService.shared.ensureProfile(
        displayName: name,
        email: credential.email ?? user.email,
      );
      if (response.displayName != null) _displayName = response.displayName;

      final prefs = await SharedPreferences.getInstance();
      if (_displayName != null) {
        await prefs.setString('tribute_display_name', _displayName!);
      }
      if (_givenName != null) {
        await prefs.setString('tribute_given_name', _givenName!);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Google Sign In ────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow — not an error.
        _isLoading = false;
        notifyListeners();
        return;
      }

      final googleAuth = await googleUser.authentication;
      final oAuthCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
      final user = userCredential.user;
      if (user == null) throw StateError('Google sign-in completed but Firebase returned a null user');

      final name = googleUser.displayName;
      _displayName = name ?? user.displayName ?? _displayName;
      // Derive given name (first word of display name) for personalisation
      final first = name?.split(' ').firstOrNull;
      if (first != null && first.isNotEmpty) _givenName = first;

      final idToken = await user.getIdToken();
      APIService.shared.setFirebaseToken(idToken, userId: user.uid);
      _userId = user.uid;
      _isAuthenticated = true;

      // Ensure Firestore user doc exists
      final response = await APIService.shared.ensureProfile(
        displayName: name,
        email: googleUser.email,
      );
      if (response.displayName != null) _displayName = response.displayName;

      final prefs = await SharedPreferences.getInstance();
      if (_displayName != null) {
        await prefs.setString('tribute_display_name', _displayName!);
      }
      if (_givenName != null) {
        await prefs.setString('tribute_given_name', _givenName!);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!isApplePlatform) {
      await GoogleSignIn().signOut();
    }
    APIService.shared.setFirebaseToken(null);
    _userId = null;
    _isAuthenticated = false;
    _displayName = null;
    _givenName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tribute_display_name');
    await prefs.remove('tribute_given_name');
    notifyListeners();
  }

  // ── Nonce helpers for Apple Sign In ──────────────────────────────────────

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
