import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

/// On-device Text-to-Speech for the memorization module.
///
/// Uses the platform's built-in TTS engine (AVSpeechSynthesizer on iOS,
/// Android TTS on Android). Works fully offline with no Cloud Function
/// or API key required.
class TtsService {
  static final TtsService instance = TtsService._();
  TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Speaks [text] aloud. Stops any current speech first.
  /// [itemId] is kept for API compatibility — not used with on-device TTS.
  Future<void> playOrGenerate({
    required String itemId,
    required String text,
  }) async {
    await _ensureInitialized();
    await _tts.stop();
    await _tts.speak(text.trim());
  }

  Future<void> stop() => _tts.stop();

  Future<void> pause() => _tts.pause();

  Future<void> resume() => _tts.speak(''); // flutter_tts has no resume

  // TtsService is a singleton — no dispose needed.
  void stopAndRelease() => _tts.stop();

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // slightly slower — easier to follow
    await _tts.setVolume(1.0);
    // iOS: pitch 1.0 — voice selection handles masculinity (Aaron etc.)
    // Android: pitch 0.88 — deepens whatever voice the device defaults to
    await _tts.setPitch(Platform.isIOS ? 1.0 : 0.88);

    await _selectMaleVoice();

    _initialized = true;
  }

  /// Picks the best available male en-US voice on iOS and Android.
  /// Silently skips if no suitable voice is found (platform default is used).
  Future<void> _selectMaleVoice() async {
    try {
      final raw = await _tts.getVoices;
      if (raw == null) return;
      final voices = (raw as List).cast<Map>();

      if (Platform.isIOS) {
        // iOS named voices — male en-US in order of quality preference.
        const preferred = ['Aaron', 'Reed', 'Eddy', 'Fred'];
        for (final name in preferred) {
          final match = voices.where(
            (v) => (v['name'] as String?)?.contains(name) == true,
          );
          if (match.isNotEmpty) {
            await _tts.setVoice({
              'name': match.first['name'] as String,
              'locale': 'en-US',
            });
            return;
          }
        }
      } else if (Platform.isAndroid) {
        // Google TTS en-US voices. Male voices typically contain 'm' as the
        // gender marker in the model segment, e.g. "en-us-x-iom-local".
        // Filter to local (offline) en-US voices first, then network.
        final enUs = voices.where((v) {
          final name = (v['name'] as String? ?? '').toLowerCase();
          final locale = (v['locale'] as String? ?? '').toLowerCase();
          return name.startsWith('en-us') || locale.startsWith('en-us') || locale == 'en_us';
        }).toList();

        // Prefer local (offline) male voices, then network male voices.
        for (final quality in ['-local', '-network', '']) {
          final male = enUs.where((v) {
            final name = (v['name'] as String? ?? '').toLowerCase();
            // Male marker: segment ending in 'm' before the quality suffix
            // e.g. en-us-x-iom-local, en-us-x-sfm-local
            return name.contains(quality) &&
                RegExp(r'x-\w+m-').hasMatch(name);
          }).toList();
          if (male.isNotEmpty) {
            await _tts.setVoice({
              'name': male.first['name'] as String,
              'locale': 'en-US',
            });
            return;
          }
        }
      }
    } catch (_) {
      // Voice selection is best-effort — never block TTS.
    }
  }
}
