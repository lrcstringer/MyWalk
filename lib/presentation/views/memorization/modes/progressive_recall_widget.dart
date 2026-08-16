import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';

// Step by Step: 3-sub-step flow per chunk.
//   Sub-step 0 — First-letter scaffold: show only the hint
//   Sub-step 1 — First 3 words: partial reveal to jog memory
//   Sub-step 2 — Blank recall: empty prompt, user judges from memory

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
  int _subStep = 0; // 0: hint, 1: first-3-words, 2: blank

  @override
  void didUpdateWidget(ProgressiveRecallWidget old) {
    super.didUpdateWidget(old);
    if (old.chunkIndex != widget.chunkIndex) {
      setState(() => _subStep = 0);
    }
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
          _buildSubStepDots(),

          const SizedBox(height: 20),

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
    final String content;
    final TextStyle style;
    final String label;

    switch (_subStep) {
      case 0:
        content = chunk.hint;
        label = 'First-letter hint';
        style = TextStyle(
          color: MyWalkColor.golden.withValues(alpha: 0.85),
          fontSize: 18,
          fontFamily: 'monospace',
          letterSpacing: 2.0,
          height: 1.7,
        );
      case 1:
        content = _firstThreeWords(chunk.text);
        label = 'First words';
        style = const TextStyle(
          color: MyWalkColor.warmWhite,
          fontSize: 18,
          height: 1.6,
        );
      default: // 2
        content = '—';
        label = 'Recall from memory';
        style = TextStyle(
          color: MyWalkColor.warmWhite.withValues(alpha: 0.2),
          fontSize: 28,
          height: 1.6,
        );
    }

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
          child: Text(
            content,
            style: style,
            textAlign: TextAlign.center,
          ),
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
    if (_subStep < 2) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: MyWalkButtonStyle.primary(),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _subStep++);
          },
          child: Text(_subStep == 0 ? 'Next hint →' : 'Try from memory →'),
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
            onPressed: () => _submit(success: true),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Got it'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A9E7E),
              foregroundColor: MyWalkColor.charcoal,
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
      ],
    );
  }

  void _submit({required bool success}) {
    if (success) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
    }
    widget.onResult(
      success: success,
      missedIds: success ? [] : [widget.item.chunks[widget.chunkIndex].id],
    );
  }
}
