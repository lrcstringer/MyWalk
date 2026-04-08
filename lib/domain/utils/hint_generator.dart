/// Generates a first-letter scaffold hint for a chunk of text.
///
/// Each word is replaced by its first character followed by underscores
/// matching the remaining length, e.g.:
///   "For God so loved the world" → "F__ G__ s_ l____ t__ w____"
///
/// Punctuation attached to a word is preserved at the end of the hint token.
String generateHint(String text) {
  return text.split(' ').map(_hintWord).join(' ');
}

String _hintWord(String word) {
  if (word.isEmpty) return '';

  // Separate trailing punctuation so it appears after the underscores.
  final trailingPunct = RegExp(r'[.,;:!?]+$');
  final match = trailingPunct.firstMatch(word);
  final punct = match != null ? word.substring(match.start) : '';
  final core = match != null ? word.substring(0, match.start) : word;

  if (core.isEmpty) return punct;
  if (core.length == 1) return '$core$punct';

  final underscores = '_' * (core.length - 1);
  return '${core[0]}$underscores$punct';
}
