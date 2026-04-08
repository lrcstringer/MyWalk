import 'dart:math';

/// Computes normalised Levenshtein similarity between two strings.
///
/// Returns a value in [0.0, 1.0] where 1.0 = identical and 0.0 = completely
/// different. Both strings are normalised (lowercase, collapsed whitespace,
/// stripped punctuation) before comparison.
///
/// Thresholds used by Typing and Recitation modes:
///   >= 0.95  → perfect
///   >= 0.80  → good
///   >= 0.60  → fair
///    < 0.60  → poor
double levenshteinSimilarity(String a, String b) {
  final na = _normalise(a);
  final nb = _normalise(b);
  if (na.isEmpty && nb.isEmpty) return 1.0;
  if (na.isEmpty || nb.isEmpty) return 0.0;
  final dist = _levenshtein(na, nb);
  final maxLen = max(na.length, nb.length);
  return 1.0 - (dist / maxLen);
}

String _normalise(String s) {
  return s
      .toLowerCase()
      .replaceAll(RegExp(r"[^\w\s]"), '') // strip punctuation
      .replaceAll(RegExp(r'\s+'), ' ')    // collapse whitespace
      .trim();
}

int _levenshtein(String a, String b) {
  final m = a.length;
  final n = b.length;
  // Use two-row rolling array to keep memory O(n).
  var prev = List<int>.generate(n + 1, (i) => i);
  var curr = List<int>.filled(n + 1, 0);

  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[j] = min(
        min(curr[j - 1] + 1, prev[j] + 1),
        prev[j - 1] + cost,
      );
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[n];
}

/// Word-level diff between [userText] and [referenceText].
///
/// Returns a list of [DiffToken]s suitable for rendering a side-by-side
/// diff in Typing and Recitation modes.
List<DiffToken> wordDiff(String userText, String referenceText) {
  final userWords =
      _normalise(userText).split(' ').where((w) => w.isNotEmpty).toList();
  final refWords =
      _normalise(referenceText).split(' ').where((w) => w.isNotEmpty).toList();
  final result = <DiffToken>[];

  // Simple LCS-based diff — sufficient for sentence-level scripture text.
  final m = userWords.length;
  final n = refWords.length;
  final lcs = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      lcs[i][j] = userWords[i - 1] == refWords[j - 1]
          ? lcs[i - 1][j - 1] + 1
          : max(lcs[i - 1][j], lcs[i][j - 1]);
    }
  }

  // Traceback
  var i = m;
  var j = n;
  final tokens = <DiffToken>[];
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && userWords[i - 1] == refWords[j - 1]) {
      tokens.add(DiffToken(word: refWords[j - 1], type: DiffType.match));
      i--;
      j--;
    } else if (j > 0 && (i == 0 || lcs[i][j - 1] >= lcs[i - 1][j])) {
      tokens.add(DiffToken(word: refWords[j - 1], type: DiffType.missing));
      j--;
    } else {
      tokens.add(DiffToken(word: userWords[i - 1], type: DiffType.extra));
      i--;
    }
  }
  result.addAll(tokens.reversed);
  return result;
}

enum DiffType { match, missing, extra }

class DiffToken {
  final String word;
  final DiffType type;
  const DiffToken({required this.word, required this.type});
}
