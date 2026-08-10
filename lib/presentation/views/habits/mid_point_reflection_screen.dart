import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

const _kPrompts = [
  'Looking at what you\'ve logged so far — does anything surprise you?',
  'Is there a time of day, place, or emotional state that seems to come up more than once?',
  'How are you feeling about this process so far?',
];

const _kHints = [
  'Even if you haven\'t noticed a pattern yet, that\'s worth noting.',
  'Don\'t force a pattern — just notice if anything stands out.',
  'Honest is good. Frustrated is fine. There are no wrong answers here.',
];

class MidPointReflectionScreen extends StatefulWidget {
  final String habitId;

  const MidPointReflectionScreen({super.key, required this.habitId});

  @override
  State<MidPointReflectionScreen> createState() =>
      _MidPointReflectionScreenState();
}

class _MidPointReflectionScreenState extends State<MidPointReflectionScreen> {
  late final List<TextEditingController> _controllers;
  int _step = 0;
  bool _saving = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _kPrompts.length,
      (_) => TextEditingController(),
    );
    for (final c in _controllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canAdvance => _controllers[_step].text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final parts = <String>[];
      for (int i = 0; i < _kPrompts.length; i++) {
        parts.add('${_kPrompts[i]}\n${_controllers[i].text.trim()}');
      }
      final session = RecoverySession(
        id: '${widget.habitId}_m1MidPointReflection_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m1MidPointReflection,
        moduleNumber: 1,
        responseText: parts.join('\n\n'),
        createdAt: now,
      );
      await context.read<RecoveryPathProvider>().saveSession(session);
      if (mounted) {
        setState(() {
          _saving = false;
          _done = true;
        });
        await Future.delayed(const Duration(milliseconds: 2800));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save. Check your connection.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const _MidPointCompletionView();

    final total = _kPrompts.length;
    final isLast = _step == total - 1;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mid-Point Reflection',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: BackButton(
          color: MyWalkColor.warmWhite,
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Persistent intro
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kRpPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _kRpPurple.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    "You've been logging moments for a little while now. Before looking "
                    "for patterns, just take a few minutes to reflect honestly.",
                    style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                        height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),

                // Step dots
                Row(
                  children: List.generate(total, (i) {
                    final active = i == _step;
                    final done = i < _step;
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: active ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: (done || active)
                            ? _kRpPurple
                            : _kRpPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Prompt
                Text(
                  _kPrompts[_step],
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: MyWalkColor.warmWhite,
                      height: 1.4),
                ),
                const SizedBox(height: 18),

                // Text field
                Expanded(
                  child: TextField(
                    controller: _controllers[_step],
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    autofocus: true,
                    style: const TextStyle(
                        color: MyWalkColor.warmWhite,
                        fontSize: 15,
                        height: 1.6),
                    decoration: InputDecoration(
                      hintText: _kHints[_step],
                      hintStyle: TextStyle(
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.28),
                          fontSize: 14),
                      filled: true,
                      fillColor: MyWalkColor.surfaceOverlay,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Next / Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canAdvance && !_saving
                        ? () {
                            if (isLast) {
                              _save();
                            } else {
                              setState(() => _step++);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRpPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            isLast ? 'Save reflection' : 'Next',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion view ───────────────────────────────────────────────────────────

class _MidPointCompletionView extends StatelessWidget {
  const _MidPointCompletionView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _kRpPurple.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded,
                        color: _kRpPurple, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('Reflection saved',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.warmWhite)),
                  const SizedBox(height: 14),
                  Text(
                    'Keep logging. The pattern will become clearer with more data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                        height: 1.6,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
