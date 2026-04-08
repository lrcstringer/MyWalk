import 'package:flutter_test/flutter_test.dart';
import 'package:mywalk/domain/utils/hint_generator.dart';

void main() {
  group('generateHint', () {
    test('replaces each word with first letter + underscores', () {
      expect(generateHint('For God'), equals('F__ G__'));
    });

    test('single-letter words are left as-is', () {
      expect(generateHint('a'), equals('a'));
    });

    test('preserves trailing punctuation', () {
      expect(generateHint('loved,'), equals('l____,'));
      expect(generateHint('world.'), equals('w____.'));
    });

    test('handles multi-word scripture phrase', () {
      final hint = generateHint('For God so loved the world');
      // Each word should start with its first letter.
      expect(hint.startsWith('F'), isTrue);
      expect(hint, contains('G__'));
      expect(hint, contains('s_'));
      expect(hint, contains('l____'));
    });

    test('empty string returns empty string', () {
      expect(generateHint(''), equals(''));
    });

    test('two-letter word gives first letter + one underscore', () {
      expect(generateHint('so'), equals('s_'));
    });

    test('word count preserved in output tokens', () {
      const text = 'For God so loved the world';
      final hint = generateHint(text);
      expect(hint.split(' ').length, equals(text.split(' ').length));
    });
  });
}
