import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'behaviour_log_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

enum _Phase { input, affirmation, postSave }

class _ThoughtType {
  final String key;
  final String label;
  final String description;
  const _ThoughtType(this.key, this.label, this.description);
}

const _kThoughtTypes = [
  _ThoughtType('permission_giving', 'Permission-giving',
      'I deserve this / just this once / a little won\'t matter'),
  _ThoughtType('minimising', 'Minimising',
      'It\'s not that bad / everyone does it'),
  _ThoughtType('catastrophising', 'Catastrophising',
      'I could never give this up / I have no willpower'),
  _ThoughtType('all_or_nothing', 'All-or-nothing',
      'I\'ve already slipped, the day is ruined'),
  _ThoughtType('externalising', 'Externalising',
      'It\'s stress / my relationship / work that causes this'),
  _ThoughtType('self_condemnation', 'Self-condemnation',
      'I\'m broken / weak / hopeless / this is just who I am'),
];

const _kStep0Examples = [
  'I deserve this.',
  'Just this once.',
  'No one will know.',
  'I can\'t cope without it.',
];

const _kStep3Example =
    'The evidence from my own history is that once never stays once. '
    'The urge will pass in about 20 minutes whether or not I act on it.';

/// Module 2 — 5-step thought examination screen.
/// Heterogeneous step types: text field, grid select, dual fields, text+chip, two-button.
class ThoughtExaminationScreen extends StatefulWidget {
  final String habitId;

  const ThoughtExaminationScreen({super.key, required this.habitId});

  @override
  State<ThoughtExaminationScreen> createState() =>
      _ThoughtExaminationScreenState();
}

class _ThoughtExaminationScreenState extends State<ThoughtExaminationScreen> {
  int _step = 0;
  _Phase _phase = _Phase.input;

  // Step 0 — raw thought
  late final TextEditingController _step0Ctrl;
  final Set<int> _dismissedStep0Examples = {};

  // Step 1 — thought type
  String? _step1Selection;
  late final TextEditingController _step1OtherCtrl;

  // Step 2 — evidence + friend response
  late final TextEditingController _step2aCtrl;
  late final TextEditingController _step2bCtrl;

  // Step 3 — alternative statement
  late final TextEditingController _step3Ctrl;
  bool _step3ExampleDismissed = false;

  // Step 4 — library choice (drives save, no Next button)
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _step0Ctrl = TextEditingController();
    _step1OtherCtrl = TextEditingController();
    _step2aCtrl = TextEditingController();
    _step2bCtrl = TextEditingController();
    _step3Ctrl = TextEditingController();

    for (final c in [_step0Ctrl, _step1OtherCtrl, _step2aCtrl, _step2bCtrl, _step3Ctrl]) {
      c.addListener(() => setState(() {}));
    }

    // Restore draft if available
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  @override
  void dispose() {
    _step0Ctrl.dispose();
    _step1OtherCtrl.dispose();
    _step2aCtrl.dispose();
    _step2bCtrl.dispose();
    _step3Ctrl.dispose();
    super.dispose();
  }

  void _restoreDraft() {
    final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    if (path == null || path.thoughtExaminationDraftStep == 0) return;
    final draft = path.thoughtExaminationDraft;
    if (draft == null || draft.isEmpty) return;
    setState(() {
      _step = path.thoughtExaminationDraftStep;
      _step0Ctrl.text = (draft['step0'] as String?) ?? '';
      _step1Selection = draft['step1'] as String?;
      _step1OtherCtrl.text = (draft['step1Other'] as String?) ?? '';
      _step2aCtrl.text = (draft['step2a'] as String?) ?? '';
      _step2bCtrl.text = (draft['step2b'] as String?) ?? '';
      _step3Ctrl.text = (draft['step3'] as String?) ?? '';
    });
  }

  Map<String, dynamic> _buildDraft() => {
        'step0': _step0Ctrl.text.trim(),
        'step1': _step1Selection ?? '',
        'step1Other': _step1OtherCtrl.text.trim(),
        'step2a': _step2aCtrl.text.trim(),
        'step2b': _step2bCtrl.text.trim(),
        'step3': _step3Ctrl.text.trim(),
      };

  Future<void> _saveDraft() async {
    await context
        .read<RecoveryPathProvider>()
        .saveThoughtExaminationDraft(widget.habitId, _step, _buildDraft());
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _step0Ctrl.text.trim().isNotEmpty;
      case 1:
        if (_step1Selection == null) return false;
        if (_step1Selection == 'other') return _step1OtherCtrl.text.trim().isNotEmpty;
        return true;
      case 2:
        return _step2aCtrl.text.trim().isNotEmpty &&
            _step2bCtrl.text.trim().isNotEmpty;
      case 3:
        return _step3Ctrl.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _advance() async {
    setState(() => _step++);
    await _saveDraft();
  }

  Future<void> _save(bool saveToLibrary) async {
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final errorType = _step1Selection == 'other'
          ? _step1OtherCtrl.text.trim()
          : _step1Selection ?? '';
      final alternative = _step3Ctrl.text.trim();
      final now = DateTime.now();

      final responseJson = jsonEncode({
        'thought': _step0Ctrl.text.trim(),
        'errorType': errorType,
        'evidence': _step2aCtrl.text.trim(),
        'friendResponse': _step2bCtrl.text.trim(),
        'alternative': alternative,
      });

      await prov.saveSession(RecoverySession(
        id: '${widget.habitId}_m2ThoughtExamination_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m2ThoughtExamination,
        moduleNumber: 2,
        responseText: responseJson,
        createdAt: now,
      ));

      if (saveToLibrary) {
        await prov.addCounterResponse(widget.habitId, {
          'thought': _step0Ctrl.text.trim(),
          'errorType': errorType,
          'alternative': alternative,
          'createdAt': Timestamp.now(),
        });
      }

      await prov.clearThoughtExaminationDraft(widget.habitId);

      if (mounted) {
        setState(() { _saving = false; _phase = _Phase.affirmation; });
        await Future.delayed(const Duration(milliseconds: 2200));
        if (mounted) setState(() => _phase = _Phase.postSave);
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

  void _onBack() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.affirmation) return _AffirmationView();
    if (_phase == _Phase.postSave) return _PostSaveView(habitId: widget.habitId);

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(RecoveryModuleContent.m2Title,
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: BackButton(
          color: MyWalkColor.warmWhite,
          onPressed: _onBack,
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            child: Column(
              children: [
                _StepDots(step: _step, total: 5),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: _buildCurrentStep(),
                  ),
                ),
                if (_step < 4)
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20,
                        MediaQuery.of(context).viewInsets.bottom + 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canAdvance ? _advance : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRpPurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              _kRpPurple.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _step == 3 ? 'Continue' : 'Next',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
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

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0 — Raw thought ───────────────────────────────────────────────────

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Write the thought exactly as it occurred — not a cleaned-up version. The raw thing.',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kRpPurple.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kRpPurple.withValues(alpha: 0.15)),
          ),
          child: Text(
            'The uncleaned version is the one that has power. That\'s the one worth examining.',
            style: TextStyle(
                fontSize: 12,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                height: 1.5,
                fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _step0Ctrl,
          minLines: 4,
          maxLines: null,
          autofocus: true,
          style: const TextStyle(
              color: MyWalkColor.warmWhite, fontSize: 15, height: 1.6),
          decoration: InputDecoration(
            hintText: RecoveryModuleContent.m2Hint,
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _kStep0Examples
              .asMap()
              .entries
              .where((e) => !_dismissedStep0Examples.contains(e.key))
              .map((e) => _ExampleChip(
                    label: e.value,
                    onTap: () =>
                        setState(() => _step0Ctrl.text = e.value),
                    onDismiss: () =>
                        setState(() => _dismissedStep0Examples.add(e.key)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Step 1 — Thought type grid ─────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What kind of thought is this?',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 16),
        ..._kThoughtTypes.map((t) => _ThoughtTypeCard(
              type: t,
              selected: _step1Selection == t.key,
              onTap: () => setState(() => _step1Selection = t.key),
            )),
        _ThoughtTypeCard(
          type: const _ThoughtType(
              'other', 'Other', 'Describe the thought pattern in your own words'),
          selected: _step1Selection == 'other',
          onTap: () => setState(() => _step1Selection = 'other'),
        ),
        if (_step1Selection == 'other') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _step1OtherCtrl,
            autofocus: true,
            style:
                const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Describe the thought pattern',
              hintStyle: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.28),
                  fontSize: 13),
              filled: true,
              fillColor: MyWalkColor.surfaceOverlay,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Step 2 — Evidence + friend response ───────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PromptField(
          prompt:
              'What is the actual evidence for this thought? What does your track record say?',
          controller: _step2aCtrl,
          minLines: 3,
        ),
        const SizedBox(height: 20),
        _PromptField(
          prompt:
              'What would you say to a good friend who told you they believed this thought?',
          controller: _step2bCtrl,
          minLines: 3,
          autofocus: false,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Step 3 — Alternative statement ────────────────────────────────────────

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Write a more accurate alternative — in your own words, not an affirmation.',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kRpPurple.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kRpPurple.withValues(alpha: 0.15)),
          ),
          child: Text(
            'Not "everything will be fine" — something you actually believe. Something grounded '
            'in what your evidence just showed you.',
            style: TextStyle(
                fontSize: 12,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                height: 1.5,
                fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _step3Ctrl,
          minLines: 3,
          maxLines: null,
          autofocus: true,
          style: const TextStyle(
              color: MyWalkColor.warmWhite, fontSize: 15, height: 1.6),
          decoration: InputDecoration(
            hintText: RecoveryModuleContent.m2Hint,
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
        if (!_step3ExampleDismissed) ...[
          const SizedBox(height: 12),
          _ExampleChip(
            label: _kStep3Example,
            onTap: () =>
                setState(() => _step3Ctrl.text = _kStep3Example),
            onDismiss: () =>
                setState(() => _step3ExampleDismissed = true),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Step 4 — Library choice ────────────────────────────────────────────────

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Is this one of your recurring thoughts — something that comes up again and again?',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 10),
        Text(
          'If yes, saving it gives you a quick-access reminder next time the thought appears.',
          style: TextStyle(
              fontSize: 13,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              height: 1.5),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : () => _save(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRpPurple,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.25),
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
                : const Text('Yes, save it to my library',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _saving ? null : () => _save(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: MyWalkColor.warmWhite,
              side: BorderSide(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('No, just this once',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int step;
  final int total;
  const _StepDots({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: List.generate(total, (i) {
          final active = i == step;
          final done = i < step;
          return Container(
            margin: const EdgeInsets.only(right: 6),
            width: active ? 18 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: done || active
                  ? _kRpPurple
                  : _kRpPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

class _ThoughtTypeCard extends StatelessWidget {
  final _ThoughtType type;
  final bool selected;
  final VoidCallback onTap;

  const _ThoughtTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? _kRpPurple.withValues(alpha: 0.12)
              : MyWalkColor.surfaceOverlay,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? _kRpPurple.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? _kRpPurple
                              : MyWalkColor.warmWhite)),
                  const SizedBox(height: 2),
                  Text(type.description,
                      style: TextStyle(
                          fontSize: 11,
                          color: MyWalkColor.warmWhite
                              .withValues(alpha: selected ? 0.6 : 0.4))),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: _kRpPurple),
          ],
        ),
      ),
    );
  }
}

class _PromptField extends StatelessWidget {
  final String prompt;
  final TextEditingController controller;
  final int minLines;
  final bool autofocus;

  const _PromptField({
    required this.prompt,
    required this.controller,
    this.minLines = 3,
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite,
                height: 1.4)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: null,
          autofocus: autofocus,
          style: const TextStyle(
              color: MyWalkColor.warmWhite, fontSize: 14, height: 1.6),
          decoration: InputDecoration(
            hintText: RecoveryModuleContent.m2Hint,
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
      ],
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ExampleChip({
    required this.label,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
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
                      color:
                          MyWalkColor.warmWhite.withValues(alpha: 0.55))),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.close_rounded,
                  size: 12,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Affirmation ───────────────────────────────────────────────────────────────

class _AffirmationView extends StatelessWidget {
  const _AffirmationView();

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
                  const Text('Good work.',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.warmWhite)),
                  const SizedBox(height: 14),
                  Text(
                    'You slowed down a thought that usually moves faster than you can catch it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                        height: 1.5),
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

// ── Post-save options ─────────────────────────────────────────────────────────

class _PostSaveView extends StatelessWidget {
  final String habitId;
  const _PostSaveView({required this.habitId});

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
                    child: const Icon(Icons.check_rounded,
                        color: _kRpPurple, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('Saved',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.warmWhite)),
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
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BehaviourLogScreen(habitId: habitId),
                      ),
                    ),
                    child: Text(
                      'Log this moment too',
                      style: TextStyle(
                          color: _kRpPurple.withValues(alpha: 0.8),
                          fontSize: 14),
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
