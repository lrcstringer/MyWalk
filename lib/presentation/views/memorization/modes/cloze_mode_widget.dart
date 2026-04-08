import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';

// Stop words excluded from blanking — function words only.
const _stopWords = {
  'a', 'an', 'the', 'and', 'or', 'but', 'nor', 'so', 'yet', 'for',
  'of', 'in', 'on', 'at', 'to', 'by', 'up', 'as', 'is', 'it', 'its',
  'be', 'am', 'are', 'was', 'were', 'been', 'being', 'do', 'does',
  'did', 'have', 'has', 'had', 'may', 'might', 'can', 'could',
  'shall', 'should', 'will', 'would', 'that', 'this', 'these', 'those',
  'i', 'me', 'my', 'we', 'our', 'you', 'your', 'he', 'him', 'his',
  'she', 'her', 'they', 'them', 'their', 'who', 'which', 'what',
  'with', 'from', 'into', 'not', 'no', 'if', 'then', 'when',
};

class ClozeModeWidget extends StatefulWidget {
  final TextChunk chunk;
  final int attemptNumber; // drives blank count
  final void Function({required bool success, List<String> missedIds}) onResult;

  const ClozeModeWidget({
    super.key,
    required this.chunk,
    required this.attemptNumber,
    required this.onResult,
  });

  @override
  State<ClozeModeWidget> createState() => _ClozeModeWidgetState();
}

class _ClozeModeWidgetState extends State<ClozeModeWidget> {
  late List<_WordToken> _tokens;
  late List<String> _options;
  int _fillIndex = 0; // which blank to fill next
  bool _submitted = false;
  bool _allCorrect = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void didUpdateWidget(ClozeModeWidget old) {
    super.didUpdateWidget(old);
    if (old.chunk.id != widget.chunk.id) {
      _build();
    }
  }

  void _build() {
    final blankCount = widget.attemptNumber <= 1
        ? 1
        : widget.attemptNumber <= 4
            ? 2
            : 3;

    final words = widget.chunk.text.split(RegExp(r'\s+'));
    // Candidate indices: content words only
    final candidates = <int>[];
    for (var i = 0; i < words.length; i++) {
      final clean = words[i].replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
      if (clean.isNotEmpty && !_stopWords.contains(clean) && clean.length > 2) {
        candidates.add(i);
      }
    }

    if (candidates.isEmpty) {
      // All words are stop words or too short — no blanks possible.
      // Treat as instant success so the user can advance.
      _tokens = words.asMap().entries
          .map((e) => _WordToken(text: e.value, isBlank: false))
          .toList();
      _options = const [];
      _fillIndex = 0;
      _submitted = true;
      _allCorrect = true;
      return;
    }

    candidates.shuffle(Random());
    final blankIndices = candidates.take(blankCount).toSet();

    _tokens = words.asMap().entries.map((e) {
      return _WordToken(
        text: e.value,
        isBlank: blankIndices.contains(e.key),
        userAnswer: null,
      );
    }).toList();

    // Options = blanked words + up to 3 distractors from other words in chunk
    final blankWords = _tokens
        .where((t) => t.isBlank)
        .map((t) => t.text.replaceAll(RegExp(r'[^a-zA-Z]'), ''))
        .toList();

    final nonBlankWords = words
        .where((w) {
          final clean = w.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
          return clean.isNotEmpty && !blankWords.map((b) => b.toLowerCase()).contains(clean);
        })
        .toList()
      ..shuffle(Random());

    final distractors = nonBlankWords.take(max(0, 6 - blankWords.length)).toList();
    _options = [...blankWords, ...distractors]..shuffle(Random());
    _fillIndex = 0;
    _submitted = false;
    _allCorrect = false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Tap the correct word to fill each blank',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          // Phrase with blanks
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MyWalkColor.cardBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 8,
              children: _tokens.map(_buildWordWidget).toList(),
            ),
          ),
          const SizedBox(height: 24),
          if (!_submitted) ...[
            Text(
              'Word bank',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _options.map(_buildOptionChip).toList(),
            ),
          ] else ...[
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: MyWalkButtonStyle.primary(),
                onPressed: _onNext,
                child: const Text('Next'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWordWidget(_WordToken token) {
    if (!token.isBlank) {
      return Text(
        token.text,
        style: const TextStyle(
          color: MyWalkColor.warmWhite,
          fontSize: 17,
          height: 1.4,
        ),
      );
    }

    final filled = token.userAnswer != null;
    final isCorrect = filled &&
        token.userAnswer!.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '') ==
            token.text.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '');

    Color borderColor;
    Color textColor;
    if (!filled) {
      borderColor = MyWalkColor.golden.withValues(alpha: 0.5);
      textColor = Colors.transparent;
    } else if (_submitted) {
      borderColor = isCorrect ? const Color(0xFF7A9E7E) : Colors.red.shade400;
      textColor = MyWalkColor.warmWhite;
    } else {
      borderColor = MyWalkColor.golden;
      textColor = MyWalkColor.warmWhite;
    }

    return GestureDetector(
      onTap: filled && !_submitted ? _clearAnswer : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
          color: filled ? borderColor.withValues(alpha: 0.08) : null,
        ),
        child: Text(
          filled ? token.userAnswer! : '     ',
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionChip(String word) {
    final used = _tokens.any((t) =>
        t.isBlank &&
        t.userAnswer?.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '') ==
            word.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), ''));
    return GestureDetector(
      onTap: used ? null : () => _selectWord(word),
      child: AnimatedOpacity(
        opacity: used ? 0.3 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: used ? Colors.white10 : MyWalkColor.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: used
                  ? Colors.transparent
                  : MyWalkColor.warmWhite.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            word,
            style: TextStyle(
              color: used
                  ? MyWalkColor.warmWhite.withValues(alpha: 0.3)
                  : MyWalkColor.warmWhite,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _selectWord(String word) {
    final blanks = _tokens.where((t) => t.isBlank).toList();
    if (_fillIndex >= blanks.length) return;

    // Find the actual token index
    var blankCount = 0;
    for (var i = 0; i < _tokens.length; i++) {
      if (_tokens[i].isBlank) {
        if (blankCount == _fillIndex) {
          setState(() {
            _tokens[i] = _tokens[i].copyWith(userAnswer: word);
            _fillIndex++;
          });
          // Auto-submit when all blanks filled
          if (_fillIndex >= blanks.length) {
            _checkAnswers();
          }
          return;
        }
        blankCount++;
      }
    }
  }

  void _clearAnswer() {
    // Find the last filled blank and clear it
    for (var i = _tokens.length - 1; i >= 0; i--) {
      if (_tokens[i].isBlank && _tokens[i].userAnswer != null) {
        setState(() {
          _tokens[i] = _tokens[i].copyWith(clearAnswer: true);
          _fillIndex--;
        });
        return;
      }
    }
  }

  void _checkAnswers() {
    setState(() {
      _submitted = true;
      _allCorrect = _tokens.every((t) {
        if (!t.isBlank) return true;
        return t.userAnswer?.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '') ==
            t.text.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '');
      });
    });
  }

  void _onNext() {
    widget.onResult(
      success: _allCorrect,
      missedIds: _allCorrect ? [] : [widget.chunk.id],
    );
  }
}

class _WordToken {
  final String text;
  final bool isBlank;
  final String? userAnswer;

  const _WordToken({
    required this.text,
    required this.isBlank,
    this.userAnswer,
  });

  _WordToken copyWith({String? userAnswer, bool clearAnswer = false}) {
    return _WordToken(
      text: text,
      isBlank: isBlank,
      userAnswer: clearAnswer ? null : (userAnswer ?? this.userAnswer),
    );
  }
}
