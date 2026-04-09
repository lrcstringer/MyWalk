import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/sm2_service.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../widgets/memorization_celebration.dart';

// Wraps every review mode with:
//  - elapsed timer
//  - chunk progress indicator
//  - confidence slider (shown at completion)
//  - SM2 dispatch on completion
//  - celebration screen on success

class MemorizationReviewShell extends StatefulWidget {
  final MemorizationItem item;
  final ReviewMode mode;

  /// Builder receives (context, chunkIndex, onChunkResult) and returns the
  /// mode-specific widget for the current chunk.
  final Widget Function(
    BuildContext context,
    int chunkIndex,
    void Function({required bool success, List<String> missedIds}) onChunkResult,
  ) builder;

  const MemorizationReviewShell({
    super.key,
    required this.item,
    required this.mode,
    required this.builder,
  });

  @override
  State<MemorizationReviewShell> createState() => _MemorizationReviewShellState();
}

class _MemorizationReviewShellState extends State<MemorizationReviewShell> {
  int _chunkIndex = 0;
  int _elapsedSeconds = 0;
  int _successCount = 0;
  final List<String> _missedChunkIds = [];
  Timer? _timer;

  bool _showConfidence = false;
  int _confidence = 3; // 1–5
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: Text(widget.item.title),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _formatTime(_elapsedSeconds),
                style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _showConfidence
          ? _ConfidenceSlider(
              initialValue: _confidence,
              onConfirmed: _onConfidenceConfirmed,
            )
          : Column(
              children: [
                _ChunkProgress(
                  total: widget.item.chunks.length,
                  current: _chunkIndex,
                  missedIds: _missedChunkIds,
                  chunks: widget.item.chunks,
                ),
                Expanded(
                  child: widget.builder(
                    context,
                    _chunkIndex,
                    _onChunkResult,
                  ),
                ),
              ],
            ),
    );
  }

  void _onChunkResult({required bool success, List<String> missedIds = const []}) {
    HapticFeedback.selectionClick();
    if (success) {
      _successCount++;
    } else {
      _missedChunkIds.addAll(missedIds.isEmpty ? [widget.item.chunks[_chunkIndex].id] : missedIds);
    }

    if (_chunkIndex < widget.item.chunks.length - 1) {
      setState(() => _chunkIndex++);
    } else {
      // All chunks done — show confidence slider
      setState(() => _showConfidence = true);
    }
  }

  void _onConfidenceConfirmed(int confidence) {
    if (_isSubmitting) return;
    setState(() => _confidence = confidence);
    _submitReview();
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    final totalChunks = widget.item.chunks.length;
    final objectiveAccuracy =
        totalChunks > 0 ? _successCount / totalChunks : 0.0;
    final qualityScore = SM2Service.deriveQualityScore(
      objectiveAccuracy: objectiveAccuracy,
      confidence: _confidence,
    );

    await context.read<MemorizationProvider>().completeReview(
          item: widget.item,
          mode: widget.mode,
          qualityScore: qualityScore,
          confidence: _confidence,
          timeToRecallSeconds: _elapsedSeconds,
          missedChunkIds: _missedChunkIds,
        );

    if (!mounted) return;

    final passed = qualityScore >= 3;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => MemorizationCelebration(
          message: passed
              ? 'Well done!'
              : 'Keep pressing in — every review matters.',
          subtitle: passed
              ? 'God\'s Word is taking root in your heart.'
              : 'Come back tomorrow. Consistency is the key.',
          onContinue: () =>
              Navigator.of(ctx).popUntil((r) => r.isFirst || r.settings.name == '/'),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ---------------------------------------------------------------------------
// Chunk progress bar
// ---------------------------------------------------------------------------

class _ChunkProgress extends StatelessWidget {
  final int total;
  final int current;
  final List<String> missedIds;
  final List<TextChunk> chunks;

  const _ChunkProgress({
    required this.total,
    required this.current,
    required this.missedIds,
    required this.chunks,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: List.generate(total, (i) {
          Color color;
          if (i < current) {
            color = missedIds.contains(chunks[i].id)
                ? Colors.red.shade400
                : const Color(0xFF7A9E7E);
          } else if (i == current) {
            color = MyWalkColor.golden;
          } else {
            color = Colors.white12;
          }
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confidence slider
// ---------------------------------------------------------------------------

class _ConfidenceSlider extends StatefulWidget {
  final int initialValue;
  final void Function(int confidence) onConfirmed;

  const _ConfidenceSlider({
    required this.initialValue,
    required this.onConfirmed,
  });

  @override
  State<_ConfidenceSlider> createState() => _ConfidenceSliderState();
}

class _ConfidenceSliderState extends State<_ConfidenceSlider> {
  late double _value;

  static const _labels = ['Very hard', 'Hard', 'OK', 'Good', 'Perfect'];

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final index = (_value.round() - 1).clamp(0, 4);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'How did that feel?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: MyWalkColor.warmWhite,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your answer helps schedule the next review.',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            _labels[index],
            style: const TextStyle(
              color: MyWalkColor.golden,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MyWalkColor.golden,
              inactiveTrackColor: Colors.white12,
              thumbColor: MyWalkColor.golden,
              overlayColor: MyWalkColor.golden.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: _value,
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => setState(() => _value = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _labels
                .map((l) => Text(
                      l,
                      style: TextStyle(
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: MyWalkButtonStyle.primary(),
              onPressed: () => widget.onConfirmed(_value.round()),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
