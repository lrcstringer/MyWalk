import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/sm2_service.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../modes/cloze_mode_widget.dart';
import '../modes/flip_card_widget.dart';
import '../modes/recitation_mode_widget.dart';
import '../modes/typing_mode_widget.dart';
import '../widgets/memorization_celebration.dart';

// ---------------------------------------------------------------------------
// ReviewSessionScreen — mandatory 4-mode sequential review
// Order: Meditate & Reveal → Speak It Aloud → Fill the Word → Write It Out
// Progress is saved to Firestore so users can leave and return.
// SM2 fires only after all 4 modes are complete.
// ---------------------------------------------------------------------------

class ReviewSessionScreen extends StatefulWidget {
  final MemorizationItem item;

  const ReviewSessionScreen({super.key, required this.item});

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  ReviewSession? _session;
  bool _loading = true;

  // Per-mode accuracy and missed chunk IDs tracked in memory for SM2.
  // If the user leaves and resumes, prior-mode data is lost; quality is then
  // based solely on the confidence slider — still valid for SM2.
  final Map<ReviewMode, double> _accuracies = {};
  final Map<ReviewMode, List<String>> _missedIdsPerMode = {};
  int _totalElapsed = 0;

  // State after all 4 modes complete
  bool _showConfidence = false;
  bool _isSubmitting = false;

  static const _steps = [
    _StepInfo(
      mode: ReviewMode.flipCard,
      icon: Icons.flip,
      title: 'Meditate & Reveal',
      description: 'See the hint, flip to reveal each phrase.',
      color: Color(0xFF9B8EC8),
    ),
    _StepInfo(
      mode: ReviewMode.recitation,
      icon: Icons.mic_outlined,
      title: 'Speak It Aloud',
      description: 'Recite the full passage from memory.',
      color: Color(0xFFD4A843),
    ),
    _StepInfo(
      mode: ReviewMode.cloze,
      icon: Icons.text_fields,
      title: 'Fill the Word',
      description: 'Tap the missing words to complete each phrase.',
      color: Color(0xFF6B9FD4),
    ),
    _StepInfo(
      mode: ReviewMode.typing,
      icon: Icons.keyboard_outlined,
      title: 'Write It Out',
      description: 'Type the phrase from memory.',
      color: Color(0xFFD4836B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    ReviewSession? existing;
    try {
      existing = await context.read<MemorizationProvider>().loadTodaySession(widget.item.id);
    } catch (_) {
      // Permission denied or network error — proceed with a fresh session.
    }
    if (!mounted) return;
    setState(() {
      _session = existing ??
          ReviewSession(
            itemId: widget.item.id,
            date: MemorizationProvider.todayKey(),
            completedModes: {},
          );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: Text(
          widget.item.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: MyWalkColor.warmWhite,
              ),
        ),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: MyWalkColor.golden),
            )
          else if (_showConfidence)
            _ConfidencePanel(
              onConfirmed: _onConfidenceConfirmed,
            )
          else
            _buildStepList(),
        ],
      ),
    );
  }

  Widget _buildStepList() {
    final session = _session!;
    final nextMode = session.nextMode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _buildHeader(session),
        const SizedBox(height: 16),
        ...List.generate(_steps.length, (i) {
          final step = _steps[i];
          final isDone = session.completedModes.contains(step.mode);
          final isCurrent = step.mode == nextMode;
          return _StepCard(
            step: step,
            stepNumber: i + 1,
            isDone: isDone,
            isCurrent: isCurrent,
            onBegin: isCurrent ? () => _startMode(step.mode) : null,
          );
        }),
      ],
    );
  }

  Widget _buildHeader(ReviewSession session) {
    final done = session.completedModes.length;
    final total = _steps.length;
    final progress = done / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                session.isComplete
                    ? 'All steps complete!'
                    : '$done of $total steps complete',
                style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: MyWalkColor.golden,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(MyWalkColor.golden),
          ),
        ),
      ],
    );
  }

  Future<void> _startMode(ReviewMode mode) async {
    if (mode == ReviewMode.recitation) {
      final result = await Navigator.of(context).push<(double, List<String>)>(
        MaterialPageRoute(
          builder: (_) => RecitationModeWidget(
            item: widget.item,
            sessionMode: true,
          ),
        ),
      );
      if (!mounted || result == null) return;
      await _onModeComplete(mode, result.$1, 0, missedIds: result.$2);
    } else {
      final result = await Navigator.of(context).push<_ModeOutcome>(
        MaterialPageRoute(
          builder: (_) => _SessionModeShell(
            item: widget.item,
            mode: mode,
          ),
        ),
      );
      if (!mounted || result == null) return;
      await _onModeComplete(
          mode, result.accuracy, result.elapsedSeconds, missedIds: result.missedIds);
    }
  }

  Future<void> _onModeComplete(
    ReviewMode mode,
    double accuracy,
    int elapsedSeconds, {
    List<String> missedIds = const [],
  }) async {
    HapticFeedback.lightImpact();
    _accuracies[mode] = accuracy;
    _missedIdsPerMode[mode] = missedIds;
    _totalElapsed += elapsedSeconds;

    final provider = context.read<MemorizationProvider>();
    final updated = await provider.markModeComplete(_session!, mode);
    setState(() => _session = updated);

    if (updated.isComplete) {
      setState(() => _showConfidence = true);
    }
  }

  Future<void> _onConfidenceConfirmed(int confidence) async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    final avgAccuracy = _accuracies.isEmpty
        ? 0.7
        : _accuracies.values.reduce((a, b) => a + b) / _accuracies.length;

    final qualityScore = SM2Service.deriveQualityScore(
      objectiveAccuracy: avgAccuracy,
      confidence: confidence,
    );

    // Union missed chunk IDs across all four modes so per-phrase strength
    // reflects actual per-chunk performance, not a blanket all-success.
    final mergedMissedIds = _missedIdsPerMode.values
        .expand((ids) => ids)
        .toSet()
        .toList();

    final nextReview =
        await context.read<MemorizationProvider>().completeReview(
              item: widget.item,
              mode: ReviewMode.session,
              qualityScore: qualityScore,
              confidence: confidence,
              timeToRecallSeconds: _totalElapsed,
              missedChunkIds: mergedMissedIds,
            );

    if (!mounted) return;

    final passed = qualityScore >= 3;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => MemorizationCelebration(
          message: passed
              ? 'Session complete!'
              : 'Keep pressing in — every review matters.',
          subtitle: _subtitle(nextReview, passed),
          onContinue: () =>
              Navigator.of(ctx).popUntil((r) => r.isFirst || r.settings.name == '/'),
        ),
      ),
    );
  }

  String _subtitle(DateTime nextReview, bool passed) {
    final diff = nextReview.difference(DateTime.now());
    final String when;
    if (diff.inHours < 24) {
      final h = diff.inHours.clamp(1, 23);
      when = '$h hour${h == 1 ? '' : 's'}';
    } else {
      final d = diff.inDays;
      when = '$d day${d == 1 ? '' : 's'}';
    }
    return passed
        ? 'Your next review is in $when.\nRepetition is how the Word takes root.'
        : 'Your next review is in $when.\nConsistency is the key — keep showing up.';
  }
}

// ---------------------------------------------------------------------------
// Step info — static configuration for each of the 4 modes
// ---------------------------------------------------------------------------

class _StepInfo {
  final ReviewMode mode;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _StepInfo({
    required this.mode,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Step card
// ---------------------------------------------------------------------------

class _StepCard extends StatelessWidget {
  final _StepInfo step;
  final int stepNumber;
  final bool isDone;
  final bool isCurrent;
  final VoidCallback? onBegin;

  const _StepCard({
    required this.step,
    required this.stepNumber,
    required this.isDone,
    required this.isCurrent,
    required this.onBegin,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent;
    if (isDone) {
      accent = const Color(0xFF7A9E7E); // sage — completed
    } else if (isCurrent) {
      accent = step.color;
    } else {
      accent = MyWalkColor.warmWhite.withValues(alpha: 0.18); // locked
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: isCurrent
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MyWalkColor.cardBackground,
                  step.color.withValues(alpha: 0.18),
                ],
              )
            : null,
        color: isCurrent ? null : MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? const Color(0xFF7A9E7E).withValues(alpha: 0.5)
              : isCurrent
                  ? step.color.withValues(alpha: 0.55)
                  : Colors.white12,
          width: 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: step.color.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Step circle / checkmark
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: isDone || isCurrent ? 0.18 : 0.08),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      color: Color(0xFF7A9E7E), size: 22)
                  : Icon(
                      step.icon,
                      color: accent,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Step $stepNumber',
                        style: TextStyle(
                          color: accent.withValues(
                              alpha: isDone || isCurrent ? 0.65 : 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      if (isDone) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Done',
                          style: TextStyle(
                            color: const Color(0xFF7A9E7E).withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.title,
                    style: TextStyle(
                      color: isDone
                          ? MyWalkColor.warmWhite.withValues(alpha: 0.55)
                          : isCurrent
                              ? MyWalkColor.warmWhite
                              : MyWalkColor.warmWhite.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.description,
                    style: TextStyle(
                      color: isDone || !isCurrent
                          ? MyWalkColor.warmWhite.withValues(alpha: 0.25)
                          : MyWalkColor.warmWhite.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Action
            if (isDone)
              Icon(Icons.check_circle_rounded,
                  color: const Color(0xFF7A9E7E).withValues(alpha: 0.7), size: 22)
            else if (isCurrent)
              FilledButton(
                onPressed: onBegin,
                style: FilledButton.styleFrom(
                  backgroundColor: step.color,
                  foregroundColor: MyWalkColor.charcoal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(64, 36),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Begin',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              )
            else
              Icon(Icons.lock_outline,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.15), size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confidence panel — shown after all 4 modes complete
// ---------------------------------------------------------------------------

class _ConfidencePanel extends StatefulWidget {
  final void Function(int confidence) onConfirmed;
  const _ConfidencePanel({required this.onConfirmed});

  @override
  State<_ConfidencePanel> createState() => _ConfidencePanelState();
}

class _ConfidencePanelState extends State<_ConfidencePanel> {
  double _value = 3;

  static const _labels = ['Very hard', 'Hard', 'OK', 'Good', 'Perfect'];

  @override
  Widget build(BuildContext context) {
    final index = (_value.round() - 1).clamp(0, 4);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF7A9E7E), size: 52),
          const SizedBox(height: 16),
          Text(
            'All 4 steps complete!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: MyWalkColor.warmWhite,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'How did the whole session feel?',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),
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
              child: const Text('Complete review'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SessionModeShell — lightweight shell for non-recitation modes in session
// Does NOT dispatch SM2; pops with _ModeOutcome so the session screen
// aggregates results and fires SM2 once at the end.
// ---------------------------------------------------------------------------

class _ModeOutcome {
  final double accuracy; // 0.0–1.0
  final int elapsedSeconds;
  final List<String> missedIds;
  const _ModeOutcome({
    required this.accuracy,
    required this.elapsedSeconds,
    this.missedIds = const [],
  });
}

class _SessionModeShell extends StatefulWidget {
  final MemorizationItem item;
  final ReviewMode mode;

  const _SessionModeShell({
    required this.item,
    required this.mode,
  });

  @override
  State<_SessionModeShell> createState() => _SessionModeShellState();
}

class _SessionModeShellState extends State<_SessionModeShell> {
  int _chunkIndex = 0;
  int _elapsedSeconds = 0;
  int _successCount = 0;
  final List<String> _missedIds = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) {
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
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
          Column(
            children: [
              _ChunkProgress(
                total: widget.item.chunks.length,
                current: _chunkIndex,
                missedIds: _missedIds,
                chunks: widget.item.chunks,
              ),
              Expanded(
                child: _buildModeWidget(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeWidget() {
    return switch (widget.mode) {
      ReviewMode.flipCard => FlipCardWidget(
          chunk: widget.item.chunks[_chunkIndex],
          itemTitle: widget.item.title,
          onResult: _onChunkResult,
        ),
      ReviewMode.cloze => ClozeModeWidget(
          chunk: widget.item.chunks[_chunkIndex],
          attemptNumber: widget.item.repetitionCount,
          onResult: _onChunkResult,
        ),
      ReviewMode.typing => TypingModeWidget(
          chunk: widget.item.chunks[_chunkIndex],
          onResult: _onChunkResult,
        ),
      _ => throw StateError('Unsupported mode in session shell: ${widget.mode}'),
    };
  }

  void _onChunkResult({
    required bool success,
    List<String> missedIds = const [],
  }) {
    if (success) {
      HapticFeedback.lightImpact();
      _successCount++;
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(
          const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
      _missedIds.addAll(missedIds.isEmpty
          ? [widget.item.chunks[_chunkIndex].id]
          : missedIds);
    }

    if (_chunkIndex < widget.item.chunks.length - 1) {
      setState(() => _chunkIndex++);
    } else {
      final total = widget.item.chunks.length;
      final accuracy = total > 0 ? _successCount / total : 0.0;
      Navigator.of(context).pop(
        _ModeOutcome(
          accuracy: accuracy,
          elapsedSeconds: _elapsedSeconds,
          missedIds: List.from(_missedIds),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ---------------------------------------------------------------------------
// Chunk progress bar (same logic as MemorizationReviewShell)
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
