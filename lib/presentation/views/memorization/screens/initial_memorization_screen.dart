import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../data/services/tts_service.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../domain/utils/text_similarity.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../widgets/memorization_celebration.dart';

// 3-step initial encounter:
//   Step 1 — Listen    : Per-chunk TTS; Next locked until Play tapped at least once
//   Step 2 — Read Aloud: Preview verse → recite from memory (STT) → scored diff
//   Step 3 — Quick Flip: Exercise A (3D flip card) then Exercise B (letter fill-in) per chunk

class InitialMemorizationScreen extends StatefulWidget {
  final MemorizationItem item;
  final int startStep;

  const InitialMemorizationScreen({
    super.key,
    required this.item,
    this.startStep = 0,
  });

  @override
  State<InitialMemorizationScreen> createState() =>
      _InitialMemorizationScreenState();
}

class _InitialMemorizationScreenState
    extends State<InitialMemorizationScreen> {
  int _step = 0; // 0–2
  int _chunkIndex = 0;
  bool _hasPlayed = false;
  bool _ttsPlaying = false;

  static const _stepTitles = ['Listen', 'Read Aloud', 'Quick Flip'];

  @override
  void initState() {
    super.initState();
    _step = widget.startStep.clamp(0, 2);
  }

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
        title: Text(
          'Step ${_step + 1} of 3 — ${_stepTitles[_step]}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: MyWalkColor.warmWhite,
              ),
        ),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        automaticallyImplyLeading: _step == 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
          SafeArea(
            child: Column(
              children: [
                _StepProgress(currentStep: _step),
                Expanded(child: _buildStep()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _ListenStep(
          chunk: widget.item.chunks[_chunkIndex],
          chunkIndex: _chunkIndex,
          totalChunks: widget.item.chunks.length,
          isPlaying: _ttsPlaying,
          hasPlayed: _hasPlayed,
          onPlay: _onPlay,
          onNext: _nextChunkOrStep,
        ),
      1 => _ReadAloudStep(
          chunk: widget.item.chunks[_chunkIndex],
          chunkIndex: _chunkIndex,
          totalChunks: widget.item.chunks.length,
          onNext: _nextChunkOrStep,
        ),
      2 => _FlipFillStep(
          item: widget.item,
          chunkIndex: _chunkIndex,
          onChunkComplete: _nextChunkOrComplete,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _onPlay() async {
    setState(() => _ttsPlaying = true);
    await TtsService.instance.playOrGenerate(
      itemId: widget.item.id,
      text: widget.item.chunks[_chunkIndex].text,
    );
    if (mounted) {
      setState(() {
        _ttsPlaying = false;
        _hasPlayed = true;
      });
    }
  }

  void _nextStep() {
    TtsService.instance.stop();
    HapticFeedback.selectionClick();
    final newStep = _step + 1;
    setState(() {
      _step = newStep;
      _chunkIndex = 0;
      _hasPlayed = false;
      _ttsPlaying = false;
    });
    if (newStep < 3) {
      context.read<MemorizationProvider>().updateItem(
            widget.item.copyWith(currentInitialStep: newStep),
          );
    }
  }

  void _nextChunkOrStep() {
    TtsService.instance.stop();
    HapticFeedback.selectionClick();
    if (_chunkIndex < widget.item.chunks.length - 1) {
      setState(() {
        _chunkIndex++;
        _hasPlayed = false;
        _ttsPlaying = false;
      });
    } else {
      _nextStep();
    }
  }

  void _nextChunkOrComplete() {
    HapticFeedback.selectionClick();
    if (_chunkIndex < widget.item.chunks.length - 1) {
      setState(() => _chunkIndex++);
    } else {
      _onComplete();
    }
  }

  void _onComplete() {
    context.read<MemorizationProvider>().updateItem(
          widget.item.copyWith(
            initialEncounterComplete: true,
            currentInitialStep: 0,
            nextReviewDate: DateTime.now().add(const Duration(hours: 12)),
          ),
        );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => MemorizationCelebration(
          message: 'First encounter complete!',
          subtitle:
              'Your next review is in 12 hours.\nKeep coming back — repetition is how the Word takes root.',
          onContinue: () =>
              Navigator.of(ctx).popUntil((r) => r.isFirst || r.settings.name == '/'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step progress indicator — 3 segments
// ---------------------------------------------------------------------------

class _StepProgress extends StatelessWidget {
  final int currentStep;
  const _StepProgress({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(3, (i) {
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
// Step 1 — Listen (per-chunk TTS; Next locked until Play tapped)
// ---------------------------------------------------------------------------

class _ListenStep extends StatelessWidget {
  final TextChunk chunk;
  final int chunkIndex;
  final int totalChunks;
  final bool isPlaying;
  final bool hasPlayed;
  final VoidCallback onPlay;
  final VoidCallback onNext;

  const _ListenStep({
    required this.chunk,
    required this.chunkIndex,
    required this.totalChunks,
    required this.isPlaying,
    required this.hasPlayed,
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
            '${chunkIndex + 1} / $totalChunks',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MyWalkColor.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              chunk.text,
              style: const TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 20,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Text(
            hasPlayed
                ? 'Tap Next to continue, or play again.'
                : 'Listen to the phrase before continuing.',
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
                  onPressed: hasPlayed ? onNext : null,
                  child: Text(
                    chunkIndex < totalChunks - 1 ? 'Next phrase →' : 'Continue →',
                  ),
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
// Step 2 — Read Aloud (preview → listening → scored)
// ---------------------------------------------------------------------------

enum _ReadState { initializing, preview, listening, scored }

class _ReadAloudStep extends StatefulWidget {
  final TextChunk chunk;
  final int chunkIndex;
  final int totalChunks;
  final VoidCallback onNext;

  const _ReadAloudStep({
    required this.chunk,
    required this.chunkIndex,
    required this.totalChunks,
    required this.onNext,
  });

  @override
  State<_ReadAloudStep> createState() => _ReadAloudStepState();
}

class _ReadAloudStepState extends State<_ReadAloudStep> {
  final _stt = SpeechToText();
  _ReadState _state = _ReadState.initializing;
  bool _sttAvailable = false;
  bool _scored = false;
  String _transcript = '';
  double _similarity = 0;
  List<DiffToken>? _diff;

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  @override
  void didUpdateWidget(_ReadAloudStep old) {
    super.didUpdateWidget(old);
    if (old.chunk.id != widget.chunk.id) {
      _stt.stop();
      if (mounted) {
        setState(() {
          _state = _sttAvailable ? _ReadState.preview : _ReadState.initializing;
          _scored = false;
          _transcript = '';
          _similarity = 0;
          _diff = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }

  Future<void> _initStt() async {
    final available = await _stt.initialize(
      onError: (_) {
        if (mounted) setState(() => _state = _ReadState.preview);
      },
    );
    if (mounted) {
      setState(() {
        _sttAvailable = available;
        _state = _ReadState.preview;
      });
    }
  }

  Future<void> _startListening() async {
    _scored = false;
    setState(() {
      _state = _ReadState.listening;
      _transcript = '';
    });
    await _stt.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _transcript = result.recognizedWords);
        // No auto-score on finalResult — only Done button triggers scoring
      },
      listenFor: const Duration(seconds: 90),
      pauseFor: const Duration(seconds: 8),
      localeId: 'en_US',
    );
  }

  void _stopListening() {
    _stt.stop();
    if (_transcript.isNotEmpty) {
      _score();
    } else {
      widget.onNext();
    }
  }

  void _score() {
    if (_scored) return;
    _scored = true;
    final sim = levenshteinSimilarity(_transcript, widget.chunk.text);
    final diff = wordDiff(_transcript, widget.chunk.text);
    if (sim >= 0.7) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(
          const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
    }
    if (!mounted) return;
    setState(() {
      _state = _ReadState.scored;
      _similarity = sim;
      _diff = diff;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _ReadState.initializing => const Center(
          child: CircularProgressIndicator(color: MyWalkColor.golden),
        ),
      _ReadState.preview => _buildPreview(),
      _ReadState.listening => _buildListening(),
      _ReadState.scored => _buildScored(),
    };
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            '${widget.chunkIndex + 1} / ${widget.totalChunks}',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MyWalkColor.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.chunk.text,
              style: const TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 20,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Text(
            'Read this phrase aloud, then recite it from memory.',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _sttAvailable ? Colors.red.shade700 : MyWalkColor.golden,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _sttAvailable ? _startListening : widget.onNext,
              icon: Icon(_sttAvailable ? Icons.mic : Icons.chevron_right),
              label: Text(_sttAvailable
                  ? 'Ready to recite from memory'
                  : 'Read it aloud — tap to continue'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildListening() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            '${widget.chunkIndex + 1} / ${widget.totalChunks}',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          const _PulsingMicIndicator(),
          const SizedBox(height: 16),
          Text(
            'Listening…',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: MyWalkColor.warmWhite),
          ),
          const SizedBox(height: 12),
          if (_transcript.isNotEmpty)
            Text(
              _transcript,
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _stopListening,
              style: OutlinedButton.styleFrom(
                foregroundColor: MyWalkColor.warmWhite,
                side: BorderSide(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.4)),
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Done reading'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildScored() {
    final pct = (_similarity * 100).round();
    final Color color = pct >= 90
        ? const Color(0xFF7A9E7E)
        : pct >= 70
            ? MyWalkColor.golden
            : pct >= 50
                ? Colors.orange.shade400
                : Colors.red.shade400;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.chunkIndex + 1} / ${widget.totalChunks}',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                pct >= 70 ? 'Well spoken!' : 'Keep practising',
                style: TextStyle(color: color, fontSize: 15),
              ),
            ],
          ),
          if (_diff != null && _transcript.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Your reading',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MyWalkColor.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 6,
                children: _diff!.map((token) {
                  final isExtra = token.type == DiffType.extra;
                  final isMissing = token.type == DiffType.missing;
                  return Container(
                    padding: isExtra || isMissing
                        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                        : EdgeInsets.zero,
                    decoration: isExtra
                        ? BoxDecoration(
                            color: Colors.red.shade900.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4))
                        : isMissing
                            ? BoxDecoration(
                                color: const Color(0xFF7A9E7E)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4))
                            : null,
                    child: Text(
                      token.word,
                      style: TextStyle(
                        color: isExtra
                            ? Colors.red.shade300
                            : isMissing
                                ? const Color(0xFF7A9E7E)
                                : MyWalkColor.warmWhite,
                        fontSize: 14,
                        height: 1.5,
                        decoration:
                            isExtra ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.red.shade300,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: MyWalkButtonStyle.primary(),
              onPressed: widget.onNext,
              child: Text(
                widget.chunkIndex < widget.totalChunks - 1
                    ? 'Next phrase →'
                    : 'Continue →',
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Quick Flip  (Exercise A: flip card → Exercise B: letter fill-in)
// ---------------------------------------------------------------------------

class _FlipFillStep extends StatefulWidget {
  final MemorizationItem item;
  final int chunkIndex;
  final VoidCallback onChunkComplete;

  const _FlipFillStep({
    required this.item,
    required this.chunkIndex,
    required this.onChunkComplete,
  });

  @override
  State<_FlipFillStep> createState() => _FlipFillStepState();
}

class _FlipFillStepState extends State<_FlipFillStep> {
  bool _flipDone = false;

  @override
  void didUpdateWidget(_FlipFillStep old) {
    super.didUpdateWidget(old);
    if (old.chunkIndex != widget.chunkIndex) {
      setState(() => _flipDone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chunk = widget.item.chunks[widget.chunkIndex];
    if (!_flipDone) {
      return _FlipExercise(
        key: ValueKey('flip_${widget.chunkIndex}'),
        chunk: chunk,
        itemTitle: widget.item.title,
        chunkIndex: widget.chunkIndex,
        totalChunks: widget.item.chunks.length,
        onComplete: (_) => setState(() => _flipDone = true),
      );
    }
    return _FillExercise(
      key: ValueKey('fill_${widget.chunkIndex}'),
      chunk: chunk,
      chunkIndex: widget.chunkIndex,
      totalChunks: widget.item.chunks.length,
      onComplete: widget.onChunkComplete,
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise A — 3D flip card (hint front → full text + reference back)
// ---------------------------------------------------------------------------

class _FlipExercise extends StatefulWidget {
  final TextChunk chunk;
  final String itemTitle;
  final int chunkIndex;
  final int totalChunks;
  final void Function(bool knew) onComplete;

  const _FlipExercise({
    super.key,
    required this.chunk,
    required this.itemTitle,
    required this.chunkIndex,
    required this.totalChunks,
    required this.onComplete,
  });

  @override
  State<_FlipExercise> createState() => _FlipExerciseState();
}

class _FlipExerciseState extends State<_FlipExercise>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _anim;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _anim = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_animCtrl.isAnimating || _answered || _animCtrl.value > 0) return;
    _animCtrl.forward();
  }

  void _answer(bool knew) {
    if (_answered) return;
    setState(() => _answered = true);
    if (knew) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(
          const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
    }
    widget.onComplete(knew);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final angle = _anim.value;
          final isBack = angle > pi / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${widget.chunkIndex + 1} / ${widget.totalChunks}',
                style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Exercise A — Can you remember what the verse is?',
                style: TextStyle(
                  color: MyWalkColor.golden.withValues(alpha: 0.7),
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: isBack ? null : _flip,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: isBack
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi),
                          child: _buildBack(),
                        )
                      : _buildFront(),
                ),
              ),
              const SizedBox(height: 20),
              if (!isBack)
                Text(
                  'Tap card above to reveal the verse',
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
                    fontSize: 13,
                  ),
                )
              else
                _buildAnswerButtons(),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.chunk.hint,
            style: const TextStyle(
              color: MyWalkColor.golden,
              fontSize: 22,
              fontFamily: 'monospace',
              letterSpacing: 2.5,
              height: 1.9,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_outlined,
                color: MyWalkColor.golden.withValues(alpha: 0.5),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Tap to flip',
                style: TextStyle(
                  color: MyWalkColor.golden.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.chunk.text,
            style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 20,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            widget.itemTitle,
            style: TextStyle(
              color: MyWalkColor.golden,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _answer(false),
            icon: const Icon(Icons.close, size: 18),
            label: const Text("I didn't know"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade300,
              side: BorderSide(color: Colors.red.shade300),
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _answer(true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('I knew it'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A9E7E),
              foregroundColor: MyWalkColor.charcoal,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise B — Letter fill-in (type missing letters; first-attempt scoring)
// ---------------------------------------------------------------------------

class _FillExercise extends StatefulWidget {
  final TextChunk chunk;
  final int chunkIndex;
  final int totalChunks;
  final VoidCallback onComplete;

  const _FillExercise({
    super.key,
    required this.chunk,
    required this.chunkIndex,
    required this.totalChunks,
    required this.onComplete,
  });

  @override
  State<_FillExercise> createState() => _FillExerciseState();
}

class _FillExerciseState extends State<_FillExercise> {
  late List<_DispItem> _items;
  late List<_BlankSlot> _slots;
  int _currentSlotIndex = 0;
  int _successCount = 0;
  int _revealedCount = 0;
  bool _allFilled = false;
  bool _programmaticClear = false;

  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _buildItems();
    _autoFocus();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _autoFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_allFilled) _focus.requestFocus();
    });
  }

  // Re-shows the keyboard whether or not the FocusNode already has focus.
  // On Android, requestFocus() is a no-op when the node is already focused
  // but the user has manually dismissed the keyboard, so we prod the platform
  // channel directly in that case.
  void _ensureKeyboardVisible() {
    if (!mounted || _allFilled) return;
    if (_focus.hasFocus) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    } else {
      _focus.requestFocus();
    }
  }

  void _revealLetter() {
    if (_allFilled || _currentSlotIndex >= _slots.length) return;
    final slot = _slots[_currentSlotIndex];
    setState(() {
      if (!slot.firstAttemptMade) {
        slot.firstAttemptMade = true;
        slot.firstAttemptCorrect = false;
      }
      slot.currentInput = slot.expected;
      slot.revealed = true;
      _revealedCount++;
    });
    _programmaticClear = true;
    _ctrl.clear();
    _programmaticClear = false;
    final nextIdx = _slots.indexWhere((s) => !s.locked, _currentSlotIndex + 1);
    if (nextIdx == -1) {
      setState(() {
        _allFilled = true;
        _currentSlotIndex = _slots.length;
      });
      _focus.unfocus();
    } else {
      setState(() => _currentSlotIndex = nextIdx);
      _ensureKeyboardVisible();
    }
  }

  void _resetExercise() {
    setState(() => _buildItems());
    _programmaticClear = true;
    _ctrl.clear();
    _programmaticClear = false;
    _autoFocus();
  }

  void _buildItems() {
    _items = [];
    _slots = [];
    _successCount = 0;
    _revealedCount = 0;
    _currentSlotIndex = 0;
    _allFilled = false;

    final hint = widget.chunk.hint;
    final text = widget.chunk.text;
    final len = hint.length < text.length ? hint.length : text.length;

    for (var i = 0; i < len; i++) {
      if (hint[i] == '_') {
        final slot = _BlankSlot(expected: text[i].toLowerCase());
        _items.add(slot);
        _slots.add(slot);
      } else {
        _items.add(_StaticChar(hint[i]));
      }
    }

    if (_slots.isEmpty) _allFilled = true;
  }

  void _onChanged(String value) {
    if (_programmaticClear) return;
    if (value.length == 1) {
      _processChar(value[0]);
    } else if (value.isEmpty) {
      _handleBackspaceFromField();
    } else {
      // More than 1 char shouldn't happen with maxLength:1; take last char
      _processChar(value[value.length - 1]);
    }
  }

  void _processChar(String char) {
    if (_allFilled || _currentSlotIndex >= _slots.length) return;
    final slot = _slots[_currentSlotIndex];
    if (slot.locked) return;

    final isCorrect = char.toLowerCase() == slot.expected;

    if (!slot.firstAttemptMade) {
      slot.firstAttemptMade = true;
      slot.firstAttemptCorrect = isCorrect;
      if (isCorrect) _successCount++;
    }

    setState(() => slot.currentInput = char.toLowerCase());

    if (isCorrect) {
      // Clear field and advance to next slot
      _programmaticClear = true;
      _ctrl.clear();
      _programmaticClear = false;

      final nextIdx =
          _slots.indexWhere((s) => !s.locked, _currentSlotIndex + 1);
      if (nextIdx == -1) {
        setState(() {
          _allFilled = true;
          _currentSlotIndex = _slots.length;
        });
        _focus.unfocus();
      } else {
        setState(() => _currentSlotIndex = nextIdx);
        _focus.requestFocus();
      }
    }
    // If wrong: slot shows red char, field still has the wrong char.
    // User must backspace to try again (triggers _handleBackspaceFromField).
  }

  // Called when user backspaces from a 1-char field → field becomes empty.
  void _handleBackspaceFromField() {
    if (_allFilled || _currentSlotIndex >= _slots.length) return;
    final slot = _slots[_currentSlotIndex];
    if (slot.currentInput != null && !slot.locked) {
      setState(() => slot.currentInput = null);
    }
  }


  @override
  Widget build(BuildContext context) {
    final total = _slots.length;
    final pct = total > 0 ? ((_successCount / total) * 100).round() : 100;

    return GestureDetector(
      onTap: _ensureKeyboardVisible,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.chunkIndex + 1} / ${widget.totalChunks}',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Exercise B — Try to complete the verse by filling in the missing text',
              style: TextStyle(
                color: MyWalkColor.golden.withValues(alpha: 0.7),
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 20),
            _buildPuzzle(),
            const SizedBox(height: 16),
            if (!_allFilled) ...[
              // Hidden 1-char TextField captures keyboard input.
              SizedBox(
                height: 1,
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  maxLength: 1,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  style: const TextStyle(color: Colors.transparent, fontSize: 1),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  onChanged: _onChanged,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _revealLetter,
                      icon: const Icon(Icons.lightbulb_outline, size: 16),
                      label: const Text('Show letter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MyWalkColor.golden.withValues(alpha: 0.85),
                        side: BorderSide(
                            color: MyWalkColor.golden.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _resetExercise,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Start over'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          MyWalkColor.warmWhite.withValues(alpha: 0.5),
                      side: BorderSide(
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (pct >= 60
                              ? const Color(0xFF7A9E7E)
                              : Colors.orange.shade400)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (pct >= 60
                                ? const Color(0xFF7A9E7E)
                                : Colors.orange.shade400)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      _revealedCount > 0
                          ? '$_successCount correct · $_revealedCount revealed'
                          : '$_successCount / $total correct',
                      style: TextStyle(
                        color: pct >= 60
                            ? const Color(0xFF7A9E7E)
                            : Colors.orange.shade400,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    pct >= 60 ? 'Great work!' : 'Keep practising',
                    style: TextStyle(
                      color: pct >= 60
                          ? const Color(0xFF7A9E7E)
                          : Colors.orange.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: MyWalkButtonStyle.primary(),
                  onPressed: widget.onComplete,
                  child: Text(
                    widget.chunkIndex < widget.totalChunks - 1
                        ? 'Next chunk'
                        : 'Finish',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzle() {
    // Group _DispItems into word units, splitting on static spaces.
    final wordUnits = <Widget>[];
    var current = <_DispItem>[];

    for (final item in _items) {
      if (item is _StaticChar && item.char == ' ') {
        if (current.isNotEmpty) {
          wordUnits.add(_buildWordUnit(current));
          current = [];
        }
      } else {
        current.add(item);
      }
    }
    if (current.isNotEmpty) wordUnits.add(_buildWordUnit(current));

    return Container(
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
        spacing: 10,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: wordUnits,
      ),
    );
  }

  Widget _buildWordUnit(List<_DispItem> items) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: items.map((item) {
        if (item is _StaticChar) return _buildStaticChar(item.char);
        return _buildSlotBox(item as _BlankSlot);
      }).toList(),
    );
  }

  Widget _buildStaticChar(String char) {
    final isLetter = RegExp(r'[a-zA-Z]').hasMatch(char);
    return SizedBox(
      width: isLetter ? 14 : 7,
      child: Text(
        char,
        style: TextStyle(
          color: isLetter
              ? MyWalkColor.warmWhite
              : MyWalkColor.warmWhite.withValues(alpha: 0.55),
          fontSize: 18,
          fontFamily: 'monospace',
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSlotBox(_BlankSlot slot) {
    final idx = _slots.indexOf(slot);
    final isActive =
        !_allFilled && !slot.locked && idx == _currentSlotIndex;

    Color borderColor;
    Color textColor;
    Color? bgColor;

    if (slot.revealed) {
      borderColor = MyWalkColor.golden;
      textColor = MyWalkColor.golden;
      bgColor = MyWalkColor.golden.withValues(alpha: 0.12);
    } else if (slot.locked) {
      borderColor = const Color(0xFF7A9E7E);
      textColor = const Color(0xFF7A9E7E);
      bgColor = const Color(0xFF7A9E7E).withValues(alpha: 0.12);
    } else if (slot.currentInput != null) {
      borderColor = Colors.red.shade400;
      textColor = Colors.red.shade300;
      bgColor = Colors.red.shade900.withValues(alpha: 0.15);
    } else if (isActive) {
      borderColor = MyWalkColor.golden;
      textColor = Colors.transparent;
      bgColor = MyWalkColor.golden.withValues(alpha: 0.06);
    } else {
      borderColor = MyWalkColor.warmWhite.withValues(alpha: 0.2);
      textColor = Colors.transparent;
      bgColor = null;
    }

    return GestureDetector(
      onTap: _ensureKeyboardVisible,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 18,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(color: borderColor, width: isActive ? 2.0 : 1.5),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          slot.currentInput ?? '',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data classes for fill exercise
// ---------------------------------------------------------------------------

class _DispItem {}

class _StaticChar extends _DispItem {
  final String char;
  _StaticChar(this.char);
}

class _BlankSlot extends _DispItem {
  final String expected;
  bool firstAttemptMade = false;
  bool firstAttemptCorrect = false;
  bool revealed = false;
  String? currentInput;

  bool get locked =>
      currentInput != null && currentInput!.toLowerCase() == expected;

  _BlankSlot({required this.expected});
}

// ---------------------------------------------------------------------------
// Pulsing mic indicator
// ---------------------------------------------------------------------------

class _PulsingMicIndicator extends StatefulWidget {
  const _PulsingMicIndicator();

  @override
  State<_PulsingMicIndicator> createState() => _PulsingMicIndicatorState();
}

class _PulsingMicIndicatorState extends State<_PulsingMicIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: 70 + _anim.value * 16,
        height: 70 + _anim.value * 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.shade700
              .withValues(alpha: 0.15 + _anim.value * 0.1),
        ),
        child: const Icon(Icons.mic, size: 34, color: Colors.redAccent),
      ),
    );
  }
}
