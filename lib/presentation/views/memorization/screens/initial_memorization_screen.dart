import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/services/tts_service.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../widgets/memorization_celebration.dart';

// The 4-step initial encounter with a new memorization item:
//   Step 1 — Listen     : TTS plays full text while user follows along
//   Step 2 — Read Aloud : Text shown; user reads aloud themselves
//   Step 3 — Visual     : Each chunk shown as first-letter hint
//   Step 4 — Flip       : Card per chunk; user flips to check themselves

class InitialMemorizationScreen extends StatefulWidget {
  final MemorizationItem item;

  const InitialMemorizationScreen({super.key, required this.item});

  @override
  State<InitialMemorizationScreen> createState() =>
      _InitialMemorizationScreenState();
}

class _InitialMemorizationScreenState extends State<InitialMemorizationScreen> {
  int _step = 0; // 0–3
  int _chunkIndex = 0;
  bool _flipped = false;
  bool _ttsPlaying = false;

  static const _stepTitles = [
    'Listen',
    'Read Aloud',
    'Visual Hints',
    'Quick Flip',
  ];

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: Text('Step ${_step + 1} of 4 — ${_stepTitles[_step]}'),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        automaticallyImplyLeading: _step == 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepProgress(currentStep: _step),
            Expanded(child: _buildStep()),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _ListenStep(
          item: widget.item,
          isPlaying: _ttsPlaying,
          onPlay: _onPlay,
          onNext: _nextStep,
        ),
      1 => _ReadAloudStep(
          item: widget.item,
          onNext: _nextStep,
        ),
      2 => _VisualStep(
          item: widget.item,
          chunkIndex: _chunkIndex,
          onNext: _nextChunkOrStep,
        ),
      3 => _FlipStep(
          item: widget.item,
          chunkIndex: _chunkIndex,
          flipped: _flipped,
          onFlip: _onFlip,
          onNext: _nextChunkOrComplete,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _onPlay() async {
    setState(() => _ttsPlaying = true);
    await TtsService.instance.playOrGenerate(
      itemId: widget.item.id,
      text: widget.item.fullText,
    );
    if (mounted) setState(() => _ttsPlaying = false);
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    setState(() {
      _step++;
      _chunkIndex = 0;
      _flipped = false;
    });
  }

  void _nextChunkOrStep() {
    HapticFeedback.selectionClick();
    if (_chunkIndex < widget.item.chunks.length - 1) {
      setState(() {
        _chunkIndex++;
        _flipped = false;
      });
    } else {
      _nextStep();
    }
  }

  void _nextChunkOrComplete() {
    HapticFeedback.selectionClick();
    if (_chunkIndex < widget.item.chunks.length - 1) {
      setState(() {
        _chunkIndex++;
        _flipped = false;
      });
    } else {
      _onComplete();
    }
  }

  void _onFlip() {
    HapticFeedback.selectionClick();
    setState(() => _flipped = !_flipped);
  }

  void _onComplete() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MemorizationCelebration(
          message: 'First encounter complete!',
          subtitle:
              'Your next review is in 12 hours.\nKeep coming back — repetition is how the Word takes root.',
          onContinue: () =>
              Navigator.of(context).popUntil((r) => r.isFirst || r.settings.name == '/'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step progress indicator
// ---------------------------------------------------------------------------

class _StepProgress extends StatelessWidget {
  final int currentStep;
  const _StepProgress({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(4, (i) {
          final done = i < currentStep;
          final active = i == currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: done
                    ? MyWalkColor.golden
                    : active
                        ? MyWalkColor.golden.withValues(alpha: 0.5)
                        : Colors.white12,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Listen
// ---------------------------------------------------------------------------

class _ListenStep extends StatelessWidget {
  final MemorizationItem item;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onNext;

  const _ListenStep({
    required this.item,
    required this.isPlaying,
    required this.onPlay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            item.fullText,
            style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 18,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Text(
            'Listen to the passage. Follow along with the words.',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPlaying ? null : onPlay,
                  icon: Icon(isPlaying ? Icons.volume_up : Icons.play_arrow_rounded),
                  label: Text(isPlaying ? 'Playing…' : 'Play audio'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MyWalkColor.golden,
                    side: const BorderSide(color: MyWalkColor.golden),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: MyWalkButtonStyle.primary(),
                  onPressed: onNext,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Read Aloud
// ---------------------------------------------------------------------------

class _ReadAloudStep extends StatelessWidget {
  final MemorizationItem item;
  final VoidCallback onNext;

  const _ReadAloudStep({required this.item, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            item.fullText,
            style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 18,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Text(
            'Read it aloud. Let the words settle in your heart.',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: MyWalkButtonStyle.primary(),
              onPressed: onNext,
              child: const Text("I've read it aloud"),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Visual Hints (one chunk at a time)
// ---------------------------------------------------------------------------

class _VisualStep extends StatelessWidget {
  final MemorizationItem item;
  final int chunkIndex;
  final VoidCallback onNext;

  const _VisualStep({
    required this.item,
    required this.chunkIndex,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final chunk = item.chunks[chunkIndex];
    final isLast = chunkIndex == item.chunks.length - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            '${chunkIndex + 1} / ${item.chunks.length}',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MyWalkColor.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  chunk.text,
                  style: const TextStyle(
                    color: MyWalkColor.warmWhite,
                    fontSize: 20,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  chunk.hint,
                  style: TextStyle(
                    color: MyWalkColor.golden.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Read the hint. Try to recall the phrase from the first letters.',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: MyWalkButtonStyle.primary(),
              onPressed: onNext,
              child: Text(isLast ? 'Continue' : 'Next phrase'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4 — Quick Flip (one chunk at a time)
// ---------------------------------------------------------------------------

class _FlipStep extends StatelessWidget {
  final MemorizationItem item;
  final int chunkIndex;
  final bool flipped;
  final VoidCallback onFlip;
  final VoidCallback onNext;

  const _FlipStep({
    required this.item,
    required this.chunkIndex,
    required this.flipped,
    required this.onFlip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final chunk = item.chunks[chunkIndex];
    final isLast = chunkIndex == item.chunks.length - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            '${chunkIndex + 1} / ${item.chunks.length}',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onFlip,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(flipped),
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: flipped
                      ? MyWalkColor.golden.withValues(alpha: 0.12)
                      : MyWalkColor.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: flipped
                      ? Border.all(
                          color: MyWalkColor.golden.withValues(alpha: 0.4))
                      : null,
                ),
                child: Text(
                  flipped ? chunk.text : chunk.hint,
                  style: TextStyle(
                    color: flipped
                        ? MyWalkColor.warmWhite
                        : MyWalkColor.golden.withValues(alpha: 0.7),
                    fontSize: flipped ? 20 : 16,
                    height: 1.7,
                    fontFamily: flipped ? null : 'monospace',
                    letterSpacing: flipped ? null : 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            flipped ? 'Full phrase revealed' : 'Tap to reveal',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (flipped)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: MyWalkButtonStyle.primary(),
                onPressed: onNext,
                child: Text(isLast ? 'Finish' : 'Next phrase'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onFlip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MyWalkColor.golden,
                  side: const BorderSide(color: MyWalkColor.golden),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Reveal phrase'),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
