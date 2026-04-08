import 'package:flutter/material.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../domain/utils/text_similarity.dart';
import '../../../../presentation/theme/app_theme.dart';

class TypingModeWidget extends StatefulWidget {
  final TextChunk chunk;
  final void Function({required bool success, List<String> missedIds}) onResult;

  const TypingModeWidget({
    super.key,
    required this.chunk,
    required this.onResult,
  });

  @override
  State<TypingModeWidget> createState() => _TypingModeWidgetState();
}

class _TypingModeWidgetState extends State<TypingModeWidget> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitted = false;
  double _similarity = 0;
  List<DiffToken>? _diff;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(TypingModeWidget old) {
    super.didUpdateWidget(old);
    if (old.chunk.id != widget.chunk.id) {
      _ctrl.clear();
      _submitted = false;
      _similarity = 0;
      _diff = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hint
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MyWalkColor.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.chunk.hint,
              style: TextStyle(
                color: MyWalkColor.golden.withValues(alpha: 0.7),
                fontSize: 14,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          if (!_submitted) ...[
            TextField(
              controller: _ctrl,
              focusNode: _focusNode,
              style: const TextStyle(color: MyWalkColor.warmWhite, height: 1.6),
              decoration: InputDecoration(
                hintText: 'Type the phrase from memory…',
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
                  borderSide:
                      const BorderSide(color: MyWalkColor.golden, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: MyWalkButtonStyle.primary(),
                onPressed: _ctrl.text.trim().isEmpty ? null : _submit,
                child: const Text('Check'),
              ),
            ),
          ] else ...[
            // Result
            _SimilarityBadge(similarity: _similarity),
            const SizedBox(height: 16),
            if (_diff != null) _DiffView(tokens: _diff!),
            const SizedBox(height: 8),
            Text(
              'Reference: ${widget.chunk.text}',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
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

  void _submit() {
    final userText = _ctrl.text.trim();
    if (userText.isEmpty) return;

    final sim = levenshteinSimilarity(userText, widget.chunk.text);
    final diff = wordDiff(userText, widget.chunk.text);

    setState(() {
      _submitted = true;
      _similarity = sim;
      _diff = diff;
    });
  }

  void _onNext() {
    widget.onResult(
      success: _similarity >= 0.7,
      missedIds: _similarity >= 0.7 ? [] : [widget.chunk.id],
    );
  }
}

class _SimilarityBadge extends StatelessWidget {
  final double similarity;
  const _SimilarityBadge({required this.similarity});

  @override
  Widget build(BuildContext context) {
    final pct = (similarity * 100).round();
    final Color color;
    final String label;
    if (pct >= 90) {
      color = const Color(0xFF7A9E7E);
      label = 'Excellent!';
    } else if (pct >= 70) {
      color = MyWalkColor.golden;
      label = 'Close!';
    } else if (pct >= 50) {
      color = Colors.orange.shade400;
      label = 'Keep practicing';
    } else {
      color = Colors.red.shade400;
      label = 'Keep pressing in';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            '$pct%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 15),
        ),
      ],
    );
  }
}

class _DiffView extends StatelessWidget {
  final List<DiffToken> tokens;
  const _DiffView({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 6,
        children: tokens.map((token) {
          Color? bg;
          Color textColor = MyWalkColor.warmWhite;
          TextDecoration? decoration;

          switch (token.type) {
            case DiffType.match:
              break;
            case DiffType.missing:
              bg = const Color(0xFF7A9E7E).withValues(alpha: 0.2);
              textColor = const Color(0xFF7A9E7E);
            case DiffType.extra:
              bg = Colors.red.shade900.withValues(alpha: 0.4);
              textColor = Colors.red.shade300;
              decoration = TextDecoration.lineThrough;
          }

          return Container(
            padding: bg != null
                ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                : EdgeInsets.zero,
            decoration: bg != null
                ? BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4))
                : null,
            child: Text(
              token.word,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                height: 1.5,
                decoration: decoration,
                decorationColor: textColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
