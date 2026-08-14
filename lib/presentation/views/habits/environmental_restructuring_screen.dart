import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

class EnvironmentalRestructuringScreen extends StatefulWidget {
  final String habitId;
  final String habitType;

  const EnvironmentalRestructuringScreen({
    super.key,
    required this.habitId,
    required this.habitType,
  });

  @override
  State<EnvironmentalRestructuringScreen> createState() =>
      _EnvironmentalRestructuringScreenState();
}

class _EnvironmentalRestructuringScreenState
    extends State<EnvironmentalRestructuringScreen> {
  late final List<Map<String, dynamic>> _cues;
  // One list of controllers per cue — supports multiple changes per cue.
  late final List<List<TextEditingController>> _controllers;
  bool _showIntro = true;
  bool _saving = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    final hierarchy = path?.cueHierarchy ?? [];
    _cues = hierarchy.take(3).toList();
    _controllers = List.generate(_cues.length, (_) => [_makeCtrl()]);
  }

  TextEditingController _makeCtrl() {
    final c = TextEditingController();
    c.addListener(() => setState(() {}));
    return c;
  }

  @override
  void dispose() {
    for (final list in _controllers) {
      for (final c in list) c.dispose();
    }
    super.dispose();
  }

  bool get _canSave =>
      _cues.isNotEmpty &&
      _controllers.every((list) => list.any((c) => c.text.trim().isNotEmpty));

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final changes = <Map<String, dynamic>>[];
      for (int i = 0; i < _cues.length; i++) {
        final cueText = _cues[i]['cueText'] as String? ?? '';
        for (final ctrl in _controllers[i]) {
          final text = ctrl.text.trim();
          if (text.isNotEmpty) changes.add({'cue': cueText, 'change': text});
        }
      }
      await context
          .read<RecoveryPathProvider>()
          .markEnvironmentalChangesDone(widget.habitId, changes);
      if (mounted) setState(() { _saving = false; _done = true; });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save. Check your connection.")),
        );
      }
    }
  }

  Widget _buildIntroScaffold() {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: MyWalkColor.warmWhite),
        title: const Text('Change Your Environment',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change the situation before you need to change your mind.',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Willpower works worst exactly when you need it most — when you\'re stressed, '
                    'tired, and the urge is strong. Making concrete changes to your environment '
                    'is more reliable than relying on willpower in the moment.',
                    style: TextStyle(
                        fontSize: 15,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                        height: 1.7),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _showIntro = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Let's do this",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const _EnvCompletionView();
    if (_showIntro) return _buildIntroScaffold();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: MyWalkColor.warmWhite),
        title: const Text('Change Your Environment',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading + explanatory copy
                        const Text(
                          'What changing your environment is about',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: MyWalkColor.warmWhite),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Willpower is often weakest when you most need it. One way to change the situation is to change your environment or context so that the habit is harder and alternatives are easier. For each of the cues you identified earlier, we are going to record at least one concrete change you can make to increase the friction between cue and behaviour or more easily enable an alternative choice.',
                          style: TextStyle(
                              fontSize: 13,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                              height: 1.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Here are some examples to help you think of ideas:',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.75)),
                        ),
                        const SizedBox(height: 10),
                        _ExampleRow(
                          label: 'Procrastination',
                          text: 'Work in designated spaces with minimal distraction; use website blockers during focus periods; make the first action on any task the smallest possible step (open the document; write one sentence).',
                        ),
                        _ExampleRow(
                          label: 'Gambling',
                          text: 'Self-exclusion from gambling sites and physical venues; remove gambling apps; block gambling sites at the router level; give financial oversight to a trusted person during early recovery.',
                        ),
                        _ExampleRow(
                          label: 'Alcohol',
                          text: 'Do not keep alcohol at home; identify two or three alcohol-free social alternatives; plan non-drinking responses for common social situations in advance.',
                        ),
                        _ExampleRow(
                          label: 'Pornography',
                          text: 'Content filtering on devices, removing the habit browser from the home screen, device-free bedroom rule, support/accountability partner established.',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Let\'s now go through your cues and add concrete changes you will make.',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                              height: 1.5),
                        ),
                        const SizedBox(height: 24),

                        if (_cues.isEmpty)
                          _emptyState()
                        else
                          ...List.generate(_cues.length, (i) => _CueSection(
                                cueText: _cues[i]['cueText'] as String? ?? '',
                                controllers: _controllers[i],
                                onAdd: () => setState(() =>
                                    _controllers[i].add(_makeCtrl())),
                              )),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSave && !_saving ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _kRpPurple.withValues(alpha: 0.3),
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
                          : const Text('Save my changes',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        'Complete your cue map first — your guardrails will be built from it.',
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 14,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
            height: 1.5),
      ),
    );
  }
}

// ── Example row ───────────────────────────────────────────────────────────────

class _ExampleRow extends StatelessWidget {
  final String label;
  final String text;
  const _ExampleRow({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
              fontSize: 13,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
              height: 1.55),
          children: [
            TextSpan(
                text: '$label — ',
                style: const TextStyle(fontWeight: FontWeight.w600,
                    color: _kRpPurple)),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

// ── Cue section ───────────────────────────────────────────────────────────────

class _CueSection extends StatelessWidget {
  final String cueText;
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;

  const _CueSection({
    required this.cueText,
    required this.controllers,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cue label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kRpPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              cueText,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kRpPurple),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'What concrete change will you make?',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MyWalkColor.warmWhite),
          ),
          const SizedBox(height: 8),
          ...List.generate(controllers.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: controllers[i],
              minLines: 2,
              maxLines: null,
              style: const TextStyle(
                  color: MyWalkColor.warmWhite, fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText: 'e.g. Move my phone charger to the hallway before 9pm',
                hintStyle: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.28),
                    fontSize: 13),
                filled: true,
                fillColor: MyWalkColor.surfaceOverlay,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          )),
          Text(
            'Be specific — e.g. "delete the app" not "use my phone less"',
            style: TextStyle(
                fontSize: 12,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.38),
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onAdd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 16, color: _kRpPurple.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  'Add another concrete change',
                  style: TextStyle(
                      fontSize: 13,
                      color: _kRpPurple.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500),
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

class _EnvCompletionView extends StatelessWidget {
  const _EnvCompletionView();

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
                    child: const Icon(Icons.shield_outlined,
                        color: _kRpPurple, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('Environment updated',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.warmWhite)),
                  const SizedBox(height: 14),
                  Text(
                    "Good — you've made it harder for the pattern to happen "
                    "automatically. Up next: a specific plan for each of your triggers.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                        height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back to my plan',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
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
