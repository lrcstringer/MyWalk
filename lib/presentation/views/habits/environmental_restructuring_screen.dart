import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/services/cue_rubric_service.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

const _kVaguePhrases = [
  'be strong',
  'think positive',
  'try harder',
  'just stop',
  'willpower',
  'be better',
];

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
  late final List<TextEditingController> _controllers;
  late final List<List<String>> _suggestions;
  late final List<bool> _showVagueness;
  bool _saving = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    final hierarchy = path?.cueHierarchy ?? [];
    _cues = hierarchy.take(3).toList();

    _controllers = List.generate(_cues.length, (_) => TextEditingController());
    _showVagueness = List.filled(_cues.length, false);
    _suggestions = _cues.map((c) {
      final cueText = c['cueText'] as String? ?? '';
      return CueRubricService.environmentalSuggestionsFor(
          widget.habitType, cueText);
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      final idx = i;
      _controllers[idx].addListener(() {
        final vague = _isVague(_controllers[idx].text);
        if (vague != _showVagueness[idx]) {
          setState(() => _showVagueness[idx] = vague);
        } else {
          setState(() {}); // rebuild for button enable
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isVague(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (t.length < 15) return true;
    return _kVaguePhrases.any((p) => t.contains(p));
  }

  bool get _canSave =>
      _controllers.isNotEmpty &&
      _controllers.every((c) => c.text.trim().length >= 15) &&
      !_showVagueness.any((v) => v);

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final changes = List.generate(_cues.length, (i) => {
        'cue': _cues[i]['cueText'] as String? ?? '',
        'change': _controllers[i].text.trim(),
      });
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

  @override
  Widget build(BuildContext context) {
    if (_done) return const _EnvCompletionView();

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
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Intro callout
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kRpPurple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _kRpPurple.withValues(alpha: 0.18)),
                          ),
                          child: Text(
                            'Willpower works worst exactly when you need it most. '
                            'Making concrete changes to your environment is more effective '
                            'than relying on willpower in the moment.',
                            style: TextStyle(
                                fontSize: 13,
                                color:
                                    MyWalkColor.warmWhite.withValues(alpha: 0.7),
                                height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_cues.isEmpty)
                          _emptyState()
                        else
                          ...List.generate(_cues.length, (i) => _CueSection(
                                cueText:
                                    _cues[i]['cueText'] as String? ?? '',
                                controller: _controllers[i],
                                suggestions: _suggestions[i],
                                showVagueness: _showVagueness[i],
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

// ── Cue section ───────────────────────────────────────────────────────────────

class _CueSection extends StatefulWidget {
  final String cueText;
  final TextEditingController controller;
  final List<String> suggestions;
  final bool showVagueness;

  const _CueSection({
    required this.cueText,
    required this.controller,
    required this.suggestions,
    required this.showVagueness,
  });

  @override
  State<_CueSection> createState() => _CueSectionState();
}

class _CueSectionState extends State<_CueSection> {
  final Set<int> _dismissedSuggestions = {};

  @override
  Widget build(BuildContext context) {
    final visibleSuggestions = widget.suggestions
        .asMap()
        .entries
        .where((e) => !_dismissedSuggestions.contains(e.key))
        .toList();

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
              widget.cueText,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kRpPurple),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'What one concrete change will you make?',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MyWalkColor.warmWhite),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.controller,
            minLines: 2,
            maxLines: null,
            style: const TextStyle(
                color: MyWalkColor.warmWhite, fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText:
                  'e.g. Move my phone charger to the hallway before 9pm',
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
          if (widget.showVagueness) ...[
            const SizedBox(height: 6),
            Text(
              'Can you make this more specific — a concrete action, not a mindset?',
              style: TextStyle(
                  fontSize: 12,
                  color: MyWalkColor.warmCoral.withValues(alpha: 0.85)),
            ),
          ],
          if (visibleSuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: visibleSuggestions.map((entry) {
                return _SuggestionChip(
                  label: entry.value,
                  onTap: () =>
                      widget.controller.text = entry.value,
                  onDismiss: () =>
                      setState(() => _dismissedSuggestions.add(entry.key)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Suggestion chip ───────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.65))),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.close_rounded,
                  size: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
            ),
          ],
        ),
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
