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
  final int attemptNumber;
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
  late int _totalBlanks;
  int _fillIndex = 0;
  // false = still filling blanks; true = all blanks confirmed, result visible
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
      _totalBlanks = 0;
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

    _totalBlanks = blankIndices.length;
    _fillIndex = 0;
    _submitted = false;
    _allCorrect = false;
  }

  // ── "Next" while filling: confirms current blank (word stays on card, field
  //     clears for next blank). On the last blank, result appears immediately
  //     and button becomes "Continue".
  // ── "Continue" after result: proceeds to next chunk.
  void _onButtonPressed() {
    if (_submitted) {
      widget.onResult(
        success: _allCorrect,
        missedIds: _allCorrect ? [] : [widget.chunk.id],
      );
      return;
    }

    final word = _ctrl.text.trim();
    if (word.isEmpty) return;

    var blankCount = 0;
    for (var i = 0; i < _tokens.length; i++) {
      if (_tokens[i].isBlank) {
        if (blankCount == _fillIndex) {
          // Confirm this blank — word stays on card, only field clears.
          setState(() {
            _tokens[i] = _tokens[i].copyWith(userAnswer: word);
            _fillIndex++;
            _ctrl.clear();
          });
          final blanks = _tokens.where((t) => t.isBlank).toList();
          if (_fillIndex >= blanks.length) {
            // Last blank — dismiss keyboard, show result + Continue button.
            _focus.unfocus();
            _checkAnswers();
          } else {
            // More blanks — keep keyboard open for next word.
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

  @override
  Widget build(BuildContext context) {
    final buttonEnabled = _submitted || _ctrl.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Card area ──────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type the missing word for each blank',
                  style: TextStyle(
                    color: MyWalkColor.warmWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MyWalkColor.golden.withValues(alpha: 0.18),
                        MyWalkColor.golden.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: MyWalkColor.golden.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MyWalkColor.golden.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    children: _tokens.map(_buildWordWidget).toList(),
                  ),
                ),
                // Result feedback line — appears alongside the Continue button.
                if (_submitted) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        _allCorrect
                            ? Icons.check_circle_outline
                            : Icons.close_rounded,
                        size: 16,
                        color: _allCorrect
                            ? const Color(0xFF7A9E7E)
                            : Colors.red.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _allCorrect ? 'Correct!' : 'Not quite — see above',
                        style: TextStyle(
                          color: _allCorrect
                              ? const Color(0xFF7A9E7E)
                              : Colors.red.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                // Blank counter for multi-blank phrases.
                if (!_submitted && _totalBlanks > 1) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Blank ${_fillIndex + 1} of $_totalBlanks',
                    style: TextStyle(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Text field (hidden after result) ───────────────────────────────
        if (!_submitted)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              style: const TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 17,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Type the missing word…',
                hintStyle: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.35),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: MyWalkColor.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: MyWalkColor.golden, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _onButtonPressed(),
            ),
          ),

        // ── Single action button ───────────────────────────────────────────
        // "Next" while filling blanks; "Continue" once result is visible.
        Padding(
          padding: EdgeInsets.fromLTRB(
              24, 0, 24, 16 + MediaQuery.of(context).padding.bottom),
          child: ElevatedButton(
            style: MyWalkButtonStyle.primary(),
            onPressed: buttonEnabled ? _onButtonPressed : null,
            child: Text(_submitted ? 'Continue' : 'Next'),
          ),
        ),
      ],
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

    final blanks = _tokens.where((t) => t.isBlank).toList();
    final blankPos = blanks.indexOf(token);
    final isActive =
        token.userAnswer == null && blankPos == _fillIndex && !_submitted;
    final filled = token.userAnswer != null;

    // Live text in the active blank as the user types.
    final displayText = filled
        ? token.userAnswer!
        : (isActive && _ctrl.text.isNotEmpty)
            ? _ctrl.text
            : '     ';

    final isCorrect = filled &&
        token.userAnswer!.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '') ==
            token.text.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z]'), '');

    final Color borderColor;
    final Color textColor;
    if (!filled && !isActive) {
      borderColor = MyWalkColor.golden.withValues(alpha: 0.3);
      textColor = Colors.transparent;
    } else if (!filled && isActive) {
      borderColor = MyWalkColor.golden;
      textColor = MyWalkColor.warmWhite;
    } else if (_submitted) {
      borderColor = isCorrect ? const Color(0xFF7A9E7E) : Colors.red.shade400;
      textColor = MyWalkColor.warmWhite;
    } else {
      // Confirmed but not yet submitted (multi-blank — still filling others).
      borderColor = MyWalkColor.golden;
      textColor = MyWalkColor.warmWhite;
    }

    final blankBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
        color: (filled || (isActive && _ctrl.text.isNotEmpty))
            ? borderColor.withValues(alpha: 0.08)
            : null,
      ),
      child: Text(
        displayText,
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

    // After submission, show correct word below any wrong blank.
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
