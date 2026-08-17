import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../domain/utils/text_similarity.dart';
import '../../../../presentation/theme/app_theme.dart';

// Step by Step: 3-sub-step flow per chunk.
//   Sub-step 0 — First-letter scaffold: show only the hint
//   Sub-step 1 — First 3 words: partial reveal to jog memory
//   Sub-step 2 — Free recall: TextField for user to type the phrase

class ProgressiveRecallWidget extends StatefulWidget {
  final MemorizationItem item;
  final int chunkIndex;
  final void Function({required bool success, List<String> missedIds}) onResult;

  const ProgressiveRecallWidget({
    super.key,
    required this.item,
    required this.chunkIndex,
    required this.onResult,
  });

  @override
  State<ProgressiveRecallWidget> createState() =>
      _ProgressiveRecallWidgetState();
}

class _ProgressiveRecallWidgetState extends State<ProgressiveRecallWidget> {
  int _subStep = 0;
  bool _revealed = false;
  final _ctrl = TextEditingController();
  final _recallFocus = FocusNode();
  bool _checked = false;
  double _checkSim = 0.0;

  @override
  void didUpdateWidget(ProgressiveRecallWidget old) {
    super.didUpdateWidget(old);
    if (old.chunkIndex != widget.chunkIndex) {
      _ctrl.clear();
      _recallFocus.unfocus();
      setState(() {
        _subStep = 0;
        _revealed = false;
        _checked = false;
        _checkSim = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _recallFocus.dispose();
    super.dispose();
  }

  String _firstThreeWords(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length <= 3) return text;
    return '${words.take(3).join(' ')}…';
  }

  @override
  Widget build(BuildContext context) {
    final chunks = widget.item.chunks;
    final current = widget.chunkIndex;
    final chunk = chunks[current];
    final remaining = chunks.length - current - 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Build the passage step by step',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Past chunks — confirmed, shown dimmed
          for (var i = 0; i < current; i++) _buildPastChunk(i, chunks),

          // Current chunk — 3-state display
          _buildCurrentChunk(chunk),

          // Remaining count hint
          if (remaining > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$remaining more phrase${remaining == 1 ? '' : 's'} ahead',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.22),
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Sub-step dots
          if (!_revealed) _buildSubStepDots(),
          if (!_revealed) const SizedBox(height: 20),

          // Action buttons
          _buildActions(chunk),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPastChunk(int i, List<TextChunk> chunks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7A9E7E),
              ),
              child: const Icon(Icons.check, size: 11, color: Colors.white),
            ),
            Expanded(
              child: Text(
                chunks[i].text,
                style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentChunk(TextChunk chunk) {
    if (_revealed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Phrase revealed',
              style: TextStyle(
                color: Colors.red.shade300.withValues(alpha: 0.8),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.3)),
            ),
            child: Text(
              chunk.text,
              style: const TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 18,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    switch (_subStep) {
      case 0:
        return _buildStepCard(
          label: 'First-letter hint',
          child: Text(
            chunk.hint,
            style: TextStyle(
              color: MyWalkColor.golden.withValues(alpha: 0.85),
              fontSize: 18,
              fontFamily: 'monospace',
              letterSpacing: 2.0,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        );
      case 1:
        return _buildStepCard(
          label: 'First words',
          child: Text(
            _firstThreeWords(chunk.text),
            style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 18,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        );
      default: // 2
        if (!_checked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Type from memory',
                  style: TextStyle(
                    color: MyWalkColor.golden.withValues(alpha: 0.6),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              TextField(
                controller: _ctrl,
                focusNode: _recallFocus,
                style: const TextStyle(
                    color: MyWalkColor.warmWhite, height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Recall the phrase…',
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
                      horizontal: 16, vertical: 14),
                ),
                maxLines: 3,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_ctrl.text.trim().isNotEmpty) _check();
                },
              ),
            ],
          );
        } else {
          final pct = (_checkSim * 100).round();
          final Color simColor = pct >= 70
              ? const Color(0xFF7A9E7E)
              : Colors.orange.shade400;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: simColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: simColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '$pct%',
                        style: TextStyle(
                          color: simColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      pct >= 70 ? 'Close enough!' : 'Keep pressing in',
                      style: TextStyle(color: simColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MyWalkColor.golden.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: MyWalkColor.golden.withValues(alpha: 0.2)),
                ),
                child: Text(
                  chunk.text,
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }
    }
  }

  Widget _buildStepCard({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: MyWalkColor.golden.withValues(alpha: 0.6),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: MyWalkColor.golden.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.3)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildSubStepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == _subStep;
        final isDone = i < _subStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDone || isActive ? MyWalkColor.golden : Colors.white24,
          ),
        );
      }),
    );
  }

  Widget _buildActions(TextChunk chunk) {
    if (_revealed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
          ),
          onPressed: () => _submit(success: false),
          child: const Text('Continue (missed)'),
        ),
      );
    }

    if (_subStep < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            style: MyWalkButtonStyle.primary(),
            onPressed: () {
              HapticFeedback.selectionClick();
              final next = _subStep + 1;
              setState(() => _subStep = next);
              if (next == 2) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _recallFocus.requestFocus();
                });
              }
            },
            child: Text(_subStep == 0 ? 'Next hint →' : 'Try from memory →'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _reveal,
            style: TextButton.styleFrom(
              foregroundColor: MyWalkColor.warmWhite.withValues(alpha: 0.4),
            ),
            child: const Text('Reveal phrase'),
          ),
        ],
      );
    }

    // subStep == 2
    if (!_checked) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: MyWalkButtonStyle.primary(),
          onPressed: _ctrl.text.trim().isNotEmpty ? _check : null,
          child: const Text('Check'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _submit(success: false),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Missed it'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade300,
              side: BorderSide(color: Colors.red.shade300),
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _submit(success: _checkSim >= 0.7),
            icon: Icon(
              _checkSim >= 0.7 ? Icons.check : Icons.close,
              size: 16,
            ),
            label: Text(_checkSim >= 0.7 ? 'Got it!' : 'Not quite'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _checkSim >= 0.7
                  ? const Color(0xFF7A9E7E)
                  : Colors.orange.shade700,
              foregroundColor: MyWalkColor.charcoal,
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
      ],
    );
  }

  void _check() {
    final chunk = widget.item.chunks[widget.chunkIndex];
    final sim = levenshteinSimilarity(_ctrl.text.trim(), chunk.text);
    if (sim >= 0.7) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(
          const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
    }
    _recallFocus.unfocus();
    setState(() {
      _checked = true;
      _checkSim = sim;
    });
  }

  void _reveal() {
    HapticFeedback.mediumImpact();
    _recallFocus.unfocus();
    setState(() => _revealed = true);
  }

  void _submit({required bool success}) {
    if (success) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(
          const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
    }
    widget.onResult(
      success: success,
      missedIds: success ? [] : [widget.item.chunks[widget.chunkIndex].id],
    );
  }
}
