import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _fillIndex = 0;
  bool _submitted = false;
  bool _allCorrect = false;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _build();
    _autoFocus();
  }

  @override
  void didUpdateWidget(ClozeModeWidget old) {
    super.didUpdateWidget(old);
    if (old.chunk.id != widget.chunk.id) {
      _ctrl.clear();
      _build();
      _autoFocus();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _autoFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_submitted) _focus.requestFocus();
    });
  }

  void _build() {
    final blankCount = widget.attemptNumber <= 1
        ? 1
        : widget.attemptNumber <= 4
            ? 2
            : 3;

    final words = widget.chunk.text.split(RegExp(r'\s+'));
    final candidates = <int>[];
    for (var i = 0; i < words.length; i++) {
      final clean = words[i].replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
      if (clean.isNotEmpty && !_stopWords.contains(clean) && clean.length > 2) {
        candidates.add(i);
      }
    }

    if (candidates.isEmpty) {
      _tokens = words.asMap().entries
          .map((e) => _WordToken(text: e.value, isBlank: false))
          .toList();
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

    _fillIndex = 0;
    _submitted = false;
    _allCorrect = false;
  }

  @override
  Widget build(BuildContext context) {
    final blankCount = _tokens.where((t) => t.isBlank).length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Type the missing word for each blank',
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
            if (_fillIndex < blankCount)
              Text(
                'Blank ${_fillIndex + 1} of $blankCount',
                style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    style: const TextStyle(
                        color: MyWalkColor.warmWhite, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Type the word…',
                      hintStyle: TextStyle(
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: MyWalkColor.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: MyWalkColor.golden, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submitWord(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: MyWalkButtonStyle.primary(),
                    onPressed:
                        _ctrl.text.trim().isNotEmpty ? _submitWord : null,
                    child: const Text('Fill'),
                  ),
                ),
              ],
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
    final isActive = !filled && _tokens
            .where((t) => t.isBlank)
            .toList()
            .indexOf(token) ==
        _fillIndex;
    final isCorrect = filled &&
        token.userAnswer!.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '') ==
            token.text.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '');

    Color borderColor;
    Color textColor;
    if (!filled) {
      borderColor = isActive
          ? MyWalkColor.golden
          : MyWalkColor.golden.withValues(alpha: 0.3);
      textColor = Colors.transparent;
    } else if (_submitted) {
      borderColor =
          isCorrect ? const Color(0xFF7A9E7E) : Colors.red.shade400;
      textColor = MyWalkColor.warmWhite;
    } else {
      borderColor = MyWalkColor.golden;
      textColor = MyWalkColor.warmWhite;
    }

    final blankBox = Container(
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
          decoration:
              (_submitted && !isCorrect) ? TextDecoration.lineThrough : null,
          decorationColor: Colors.red.shade400,
        ),
      ),
    );

    // After submission show correct word below incorrect blanks
    if (_submitted && !isCorrect) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          blankBox,
          Text(
            token.text,
            style: const TextStyle(
              color: Color(0xFF7A9E7E),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return blankBox;
  }

  void _submitWord() {
    final word = _ctrl.text.trim();
    if (word.isEmpty) return;

    final blanks = _tokens.where((t) => t.isBlank).toList();
    if (_fillIndex >= blanks.length) return;

    var blankCount = 0;
    for (var i = 0; i < _tokens.length; i++) {
      if (_tokens[i].isBlank) {
        if (blankCount == _fillIndex) {
          setState(() {
            _tokens[i] = _tokens[i].copyWith(userAnswer: word);
            _fillIndex++;
            _ctrl.clear();
          });
          if (_fillIndex >= blanks.length) {
            _focus.unfocus();
            _checkAnswers();
          } else {
            _focus.requestFocus();
          }
          return;
        }
        blankCount++;
      }
    }
  }

  void _checkAnswers() {
    final allCorrect = _tokens.every((t) {
      if (!t.isBlank) return true;
      return t.userAnswer?.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '') ==
          t.text.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '');
    });
    if (allCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(
          const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
    }
    setState(() {
      _submitted = true;
      _allCorrect = allCorrect;
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
