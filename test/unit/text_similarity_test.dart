import 'package:flutter_test/flutter_test.dart';
import 'package:mywalk/domain/utils/text_similarity.dart';

void main() {
  group('levenshteinSimilarity', () {
    test('identical strings → 1.0', () {
      expect(levenshteinSimilarity('hello world', 'hello world'), equals(1.0));
    });

    test('empty strings → 1.0', () {
      expect(levenshteinSimilarity('', ''), equals(1.0));
    });

    test('one empty string → 0.0', () {
      expect(levenshteinSimilarity('hello', ''), equals(0.0));
      expect(levenshteinSimilarity('', 'world'), equals(0.0));
    });

    test('case insensitive comparison', () {
      expect(levenshteinSimilarity('Hello World', 'hello world'), equals(1.0));
    });

    test('punctuation stripped before comparison', () {
      expect(
          levenshteinSimilarity('For God so loved the world.',
              'For God so loved the world'),
          equals(1.0));
    });

    test('completely different strings → low score', () {
      expect(levenshteinSimilarity('abc', 'xyz'), lessThan(0.5));
    });

    test('one character off → high score', () {
      final score = levenshteinSimilarity('helo', 'hello');
      expect(score, greaterThan(0.75));
    });

    test('scripture: near-perfect recall → >= 0.95', () {
      const ref = 'For God so loved the world that he gave his only son';
      const user = 'For God so loved the world that he gave his only Son';
      expect(levenshteinSimilarity(user, ref), greaterThanOrEqualTo(0.95));
    });

    test('scripture: missing a few words → 0.80–0.94 range', () {
      const ref = 'For God so loved the world that he gave his only son';
      const user = 'For God so loved the world that he gave his son';
      final score = levenshteinSimilarity(user, ref);
      expect(score, greaterThan(0.80));
      expect(score, lessThan(0.95));
    });
  });

  group('wordDiff', () {
    test('identical texts → all match tokens', () {
      final tokens = wordDiff('hello world', 'hello world');
      expect(tokens.every((t) => t.type == DiffType.match), isTrue);
    });

    test('extra word in user text → extra token', () {
      final tokens = wordDiff('hello beautiful world', 'hello world');
      expect(tokens.any((t) => t.type == DiffType.extra), isTrue);
    });

    test('missing word in user text → missing token', () {
      final tokens = wordDiff('hello world', 'hello big world');
      expect(tokens.any((t) => t.type == DiffType.missing), isTrue);
    });

    test('empty reference → all extra', () {
      final tokens = wordDiff('hello', '');
      expect(tokens.every((t) => t.type == DiffType.extra), isTrue);
    });
  });
}
