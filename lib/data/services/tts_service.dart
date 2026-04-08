import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TtsService {
  static final TtsService instance = TtsService._();
  TtsService._();

  final _functions = FirebaseFunctions.instance;
  final _player = AudioPlayer();

  static const _prefPrefix = 'tts_cache_';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Plays TTS audio for [itemId]. Generates via Cloud Function on first call;
  /// subsequent calls serve from device cache. Returns the cached file path.
  ///
  /// Lazy: only called when the user explicitly taps Play.
  Future<String?> playOrGenerate({
    required String itemId,
    required String text,
  }) async {
    try {
      // Stop any currently playing audio before starting new playback.
      await _player.stop();

      final cached = await _cachedPath(itemId);
      if (cached != null && File(cached).existsSync()) {
        await _player.play(DeviceFileSource(cached));
        return cached;
      }

      // Generate via Cloud Function.
      final url = await _generateTtsUrl(text);
      if (url == null) return null;

      // Download and cache.
      final localPath = await _downloadAndCache(itemId, url);
      if (localPath != null) {
        await _player.play(DeviceFileSource(localPath));
      }
      return localPath;
    } catch (_) {
      return null;
    }
  }

  Future<void> stop() => _player.stop();

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.resume();

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  // TtsService is a singleton — do not dispose the underlying AudioPlayer.
  // Call stop() to halt playback when leaving a screen instead.
  void stopAndRelease() => _player.stop();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<String?> _generateTtsUrl(String text) async {
    try {
      final result = await _functions
          .httpsCallable(
            'generateTts',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
          )
          .call<dynamic>({'text': text});

      final data = result.data;
      if (data is Map && data['url'] is String) {
        return data['url'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _downloadAndCache(String itemId, String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/tts_$itemId.mp3');
      await file.writeAsBytes(response.bodyBytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefPrefix$itemId', file.path);

      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _cachedPath(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefPrefix$itemId');
  }

  Future<void> clearCache(String itemId) async {
    final path = await _cachedPath(itemId);
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefPrefix$itemId');
  }
}
