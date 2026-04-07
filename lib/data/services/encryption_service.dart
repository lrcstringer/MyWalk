import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// AES-256-CBC field encryption for sensitive Firestore fields.
///
/// Key derivation: SHA-256(appSecret + ':' + uid)
/// This produces a unique per-user key that is fully deterministic —
/// the same key is derived on every device and after every reinstall
/// as long as the user is authenticated with the same Firebase UID.
///
/// Storage format: `enc:<base64(iv[16] + ciphertext)>`
/// The 'enc:' prefix allows transparent migration: fields that do not carry
/// the prefix are legacy plaintext and are returned as-is on read.
///
/// ── IMPORTANT ────────────────────────────────────────────────────────────────
/// The [_appSecret] constant below must NEVER be changed.  Changing it makes
/// every user's encrypted data permanently unreadable.  Keep an offline backup
/// of this value.  Current secret was generated 2026-04-07.
/// ─────────────────────────────────────────────────────────────────────────────
class EncryptionService {
  // 256-bit secret — generated once, never rotated.
  // Backup copy: store offline in a password manager.
  static const String _appSecret =
      '83d9b6b0bce67578d7efa2182144e50dac7001e1ed06933e7bcf345278ab9c4a';

  Key _keyForUid(String uid) {
    final bytes = utf8.encode('$_appSecret:$uid');
    final hash = sha256.convert(bytes);
    return Key(Uint8List.fromList(hash.bytes));
  }

  /// Encrypts [plaintext] bound to [uid].
  /// Returns plaintext unchanged if it is null or empty.
  String? encryptField(String? plaintext, String uid) {
    if (plaintext == null || plaintext.isEmpty) return plaintext;
    final key = _keyForUid(uid);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    final combined = Uint8List(16 + encrypted.bytes.length);
    combined.setRange(0, 16, iv.bytes);
    combined.setRange(16, combined.length, encrypted.bytes);
    return 'enc:${base64Encode(combined)}';
  }

  /// Decrypts a value produced by [encryptField].
  /// If [stored] does not start with 'enc:', it is legacy plaintext and is
  /// returned as-is — no migration step required.
  /// Returns null if [stored] is null.
  String? decryptField(String? stored, String uid) {
    if (stored == null || stored.isEmpty) return stored;
    if (!stored.startsWith('enc:')) return stored; // legacy plaintext
    try {
      final combined = base64Decode(stored.substring(4));
      if (combined.length < 17) return stored; // malformed — treat as plaintext
      final iv = IV(Uint8List.fromList(combined.sublist(0, 16)));
      final cipherBytes = Encrypted(Uint8List.fromList(combined.sublist(16)));
      final key = _keyForUid(uid);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      return encrypter.decrypt(cipherBytes, iv: iv);
    } catch (_) {
      // Decryption failed — return raw value rather than crashing.
      return stored;
    }
  }
}
