import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../domain/utils/text_similarity.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../widgets/memorization_celebration.dart';

// Recitation mode: full-passage recording + STT scoring.
// This widget manages its own SM2 dispatch and navigation (bypasses the shell).

class RecitationModeWidget extends StatefulWidget {
  final MemorizationItem item;

  /// When true, the widget pops with the similarity score (double) instead of
  /// dispatching SM2 and navigating to the celebration screen.
  final bool sessionMode;

  const RecitationModeWidget({
    super.key,
    required this.item,
    this.sessionMode = false,
  });

  @override
  State<RecitationModeWidget> createState() => _RecitationModeWidgetState();
}

enum _RecitationState { preview, listening, scored, error }

class _RecitationModeWidgetState extends State<RecitationModeWidget> {
  final _stt = SpeechToText();

  _RecitationState _state = _RecitationState.preview;
  String _transcript = '';
  double _similarity = 0;
  List<DiffToken>? _diff;
  bool _sttAvailable = false;
  bool _scored = false; // guards against double-scoring from onResult + _stopListening
  bool _isSubmitting = false; // guards against double-tap on Continue
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }

  Future<void> _initStt() async {
    final available = await _stt.initialize(
      onError: (_) {
        if (mounted) setState(() => _state = _RecitationState.error);
      },
    );
    if (mounted) {
      setState(() {
        _sttAvailable = available;
        if (_state != _RecitationState.error) {
          _state = _RecitationState.preview;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: Text(widget.item.title),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: switch (_state) {
                _RecitationState.preview => _buildPreview(),
                _RecitationState.listening => _buildListening(),
                _RecitationState.scored => _buildScored(),
                _RecitationState.error => _buildError(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MyWalkColor.cardBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            widget.item.fullText,
            style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 17,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Read the passage, then recite it from memory.',
          style: TextStyle(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
            fontSize: 14,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _sttAvailable ? _startListening : null,
            icon: const Icon(Icons.mic),
            label: Text(_sttAvailable
                ? 'Ready to recite from memory'
                : 'Microphone access required'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildListening() {
    return Column(
      children: [
        const Spacer(),
        const _PulsingMic(),
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
              color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
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
                pct >= 70 ? 'Well spoken!' : 'Keep pressing in',
                style: TextStyle(color: color, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_diff != null) ...[
            Text(
              'Your recitation',
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
                        ? const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2)
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
              onPressed: _submitResult,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_off, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Could not access microphone.\nPlease check your permissions.',
            style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go back',
                style: TextStyle(color: MyWalkColor.golden)),
          ),
        ],
      ),
    );
  }

  Future<void> _startListening() async {
    _scored = false;
    _stopwatch
      ..reset()
      ..start();
    setState(() {
      _state = _RecitationState.listening;
      _transcript = '';
    });
    await _stt.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _transcript = result.recognizedWords);
        // No auto-score on finalResult — only Done reading triggers scoring
      },
      listenFor: const Duration(seconds: 120),
      pauseFor: const Duration(seconds: 8),
      localeId: 'en_US',
    );
  }

  void _stopListening() {
    _stt.stop();
    if (_transcript.isNotEmpty) {
      _score();
    } else {
      setState(() => _state = _RecitationState.preview);
    }
  }

  void _score() {
    if (_scored) return; // guard against double-scoring (onResult + _stopListening race)
    _scored = true;
    _stopwatch.stop();
    final sim = levenshteinSimilarity(_transcript, widget.item.fullText);
    final diff = wordDiff(_transcript, widget.item.fullText);
    if (!mounted) return;
    setState(() {
      _state = _RecitationState.scored;
      _similarity = sim;
      _diff = diff;
    });
  }

  Future<void> _submitResult() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    // In session mode, simply pop with the similarity score so the session
    // screen can aggregate results and dispatch SM2 at the very end.
    if (widget.sessionMode) {
      if (mounted) Navigator.of(context).pop(_similarity);
      return;
    }

    final qualityScore = _similarity >= 0.9
        ? 5
        : _similarity >= 0.7
            ? 4
            : _similarity >= 0.5
                ? 3
                : _similarity >= 0.3
                    ? 2
                    : 1;

    // Compare each chunk against its proportional slice of the transcript
    // (with 2-word padding) so multi-chunk items score correctly.
    final transcriptWords = _transcript.trim().split(RegExp(r'\s+'));
    final missedIds = <String>[];
    var offset = 0;
    for (final chunk in widget.item.chunks) {
      final start = (offset - 2).clamp(0, transcriptWords.length);
      final end = (offset + chunk.wordCount + 2).clamp(0, transcriptWords.length);
      final window = transcriptWords.sublist(start, end).join(' ');
      if (levenshteinSimilarity(window, chunk.text) < 0.5) {
        missedIds.add(chunk.id);
      }
      offset += chunk.wordCount;
    }

    final nextReview = await context.read<MemorizationProvider>().completeReview(
          item: widget.item,
          mode: ReviewMode.recitation,
          qualityScore: qualityScore,
          confidence: 3,
          timeToRecallSeconds: _stopwatch.elapsed.inSeconds,
          missedChunkIds: missedIds,
          userResponse: _transcript,
          levenshteinScore: _similarity,
        );

    if (!mounted) return;
    final passed = qualityScore >= 3;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => MemorizationCelebration(
          message: passed ? 'Well spoken!' : 'Keep pressing in',
          subtitle: _reviewSubtitle(nextReview, passed),
          onContinue: () =>
              Navigator.of(ctx).popUntil((r) => r.isFirst || r.settings.name == '/'),
        ),
      ),
    );
  }

  String _reviewSubtitle(DateTime nextReview, bool passed) {
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
        ? 'Your next review is in $when.\nKeep coming back — repetition is how the Word takes root.'
        : 'Your next review is in $when.\nConsistency is the key — keep showing up.';
  }
}

class _PulsingMic extends StatefulWidget {
  const _PulsingMic();

  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic>
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
        width: 80 + _anim.value * 20,
        height: 80 + _anim.value * 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.shade700.withValues(alpha: 0.15 + _anim.value * 0.1),
        ),
        child: const Icon(Icons.mic, size: 40, color: Colors.redAccent),
      ),
    );
  }
}
