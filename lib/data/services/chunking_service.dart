import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/entities/memorization_item.dart';
import '../../domain/utils/hint_generator.dart';

// Maximum chunks the user can have (enforced on Screen 2 UI).
const int kMaxChunks = 8;

class ChunkingService {
  static final ChunkingService instance = ChunkingService._();
  ChunkingService._();

  final _functions = FirebaseFunctions.instance;

  /// Calls the `chunkText` Cloud Function (Claude API proxy).
  /// Falls back to a local splitter if the call fails or times out.
  Future<List<TextChunk>> chunkText(String fullText) async {
    try {
      final result = await _functions
          .httpsCallable('chunkText', options: HttpsCallableOptions(timeout: const Duration(seconds: 20)))
          .call<dynamic>({'text': fullText});

      final raw = result.data;
      List<dynamic> chunks;

      if (raw is List) {
        chunks = raw;
      } else if (raw is Map && raw['chunks'] is List) {
        chunks = raw['chunks'] as List<dynamic>;
      } else {
        return _fallbackChunk(fullText);
      }

      return _parseChunks(chunks, fullText);
    } catch (_) {
      return _fallbackChunk(fullText);
    }
  }

  List<TextChunk> _parseChunks(List<dynamic> raw, String fullText) {
    final chunks = <TextChunk>[];
    for (var i = 0; i < raw.length && i < kMaxChunks; i++) {
      final item = raw[i];
      if (item is! Map) continue;
      final text = (item['text'] as String? ?? '').trim();
      if (text.isEmpty) continue;
      final hint = (item['hint'] as String?)?.trim() ?? generateHint(text);
      chunks.add(TextChunk.create(sequenceNumber: i, text: text, hint: hint));
    }
    if (chunks.isEmpty) return _fallbackChunk(fullText);
    return chunks;
  }

  /// Simple local fallback: split on sentence-ending punctuation, then on
  /// every ~8 words. Produces readable chunks without needing the network.
  List<TextChunk> _fallbackChunk(String text) {
    final sentences = text.split(RegExp(r'(?<=[.;:,])\s+'));
    final chunks = <String>[];

    for (final sentence in sentences) {
      final words = sentence.trim().split(RegExp(r'\s+'));
      if (words.length <= 10) {
        chunks.add(sentence.trim());
      } else {
        // Break long sentences every 8 words.
        for (var i = 0; i < words.length; i += 8) {
          final end = (i + 8).clamp(0, words.length);
          chunks.add(words.sublist(i, end).join(' '));
        }
      }
    }

    // Collapse very short chunks (< 3 words) into the previous one.
    final merged = <String>[];
    for (final c in chunks) {
      if (merged.isNotEmpty && c.split(' ').length < 3) {
        merged[merged.length - 1] = '${merged.last} $c';
      } else {
        merged.add(c);
      }
    }

    return merged
        .take(kMaxChunks)
        .toList()
        .asMap()
        .entries
        .map((e) => TextChunk.create(
              sequenceNumber: e.key,
              text: e.value,
              hint: generateHint(e.value),
            ))
        .toList();
  }
}
