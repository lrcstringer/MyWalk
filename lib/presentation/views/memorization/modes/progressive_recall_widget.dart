import 'package:flutter/material.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';

// Step by Step: shows the full passage with all chunks listed.
// The current chunk is highlighted and expanded. Previously completed
// chunks are shown as dim hints. Future chunks are hidden.

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
  bool _revealed = false;

  @override
  void didUpdateWidget(ProgressiveRecallWidget old) {
    super.didUpdateWidget(old);
    if (old.chunkIndex != widget.chunkIndex) {
      setState(() => _revealed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chunks = widget.item.chunks;
    final current = widget.chunkIndex;

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
          ...List.generate(chunks.length, (i) => _buildChunkRow(i, current, chunks)),
          const SizedBox(height: 32),
          if (!_revealed)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _revealed = true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MyWalkColor.golden,
                  side: const BorderSide(color: MyWalkColor.golden),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Reveal phrase'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _submit(success: false),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("Missed it"),
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
            ),
        ],
      ),
    );
  }

  Widget _buildChunkRow(int i, int current, List<TextChunk> chunks) {
    final isPast = i < current;
    final isCurrent = i == current;
    final isFuture = i > current;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent
              ? MyWalkColor.golden.withValues(alpha: 0.08)
              : MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: isCurrent
              ? Border.all(color: MyWalkColor.golden.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPast
                    ? const Color(0xFF7A9E7E)
                    : isCurrent
                        ? MyWalkColor.golden
                        : Colors.white12,
              ),
              child: Center(
                child: isPast
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isCurrent
                              ? MyWalkColor.charcoal
                              : MyWalkColor.warmWhite.withValues(alpha: 0.3),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: isFuture
                  ? Text(
                      chunks[i].hint,
                      style: TextStyle(
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.2),
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    )
                  : isCurrent && !_revealed
                      ? Text(
                          chunks[i].hint,
                          style: TextStyle(
                            color: MyWalkColor.golden.withValues(alpha: 0.6),
                            fontSize: 14,
                            fontFamily: 'monospace',
                            letterSpacing: 1.2,
                          ),
                        )
                      : Text(
                          chunks[i].text,
                          style: TextStyle(
                            color: isPast
                                ? MyWalkColor.warmWhite.withValues(alpha: 0.5)
                                : MyWalkColor.warmWhite,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit({required bool success}) {
    widget.onResult(
      success: success,
      missedIds: success ? [] : [widget.item.chunks[widget.chunkIndex].id],
    );
  }
}
