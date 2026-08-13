import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'record_a_moment_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

enum _Phase { input, affirmation, postSave }

class _ThoughtType {
  final String key;
  final String description;
  const _ThoughtType(this.key, this.description);
}

const _kThoughtTypes = [
  _ThoughtType('permission_giving',
      'I deserve this / just this once / a little won\'t matter'),
  _ThoughtType('minimising', 'It\'s not that bad / everyone does it'),
  _ThoughtType(
      'catastrophising', 'I could never give this up / I have no willpower'),
  _ThoughtType('all_or_nothing', 'I\'ve already slipped, the day is ruined'),
  _ThoughtType(
      'externalising', 'It\'s stress / my relationship / work that causes this'),
  _ThoughtType('self_condemnation',
      'I\'m broken / weak / hopeless / this is just who I am'),
];

const _kQ1Examples = [
  'I\'ve earned this.',
  'Just this once.',
  'No one will know.',
  'I can\'t cope without it.',
];

const _kQ5Example =
    'The evidence from my own history is that once never stays once. '
    'The urge will pass in about 20 minutes whether or not I act on it.';

/// Module 2 — Examine Your Thoughts.
/// First visit: 5-question linear flow. Subsequent visits: scrollable edit form.
class ThoughtExaminationScreen extends StatefulWidget {
  final String habitId;
  final Color accentColor;

  const ThoughtExaminationScreen({
    super.key,
    required this.habitId,
    this.accentColor = _kRpPurple,
  });

  @override
  State<ThoughtExaminationScreen> createState() =>
      _ThoughtExaminationScreenState();
}

class _ThoughtExaminationScreenState extends State<ThoughtExaminationScreen> {
  Color get _kRpPurple => widget.accentColor;

  bool _showOpening = true;
  int _step = 0;
  _Phase _phase = _Phase.input;
  bool _editMode = false;
  bool _saving = false;
  bool _isFirstSave = false;

  // Q1 — dynamic thought list (min 1)
  final List<TextEditingController> _thoughtCtrls = [];
  final Set<int> _dismissedQ1Examples = {};

  // Q2 — multi-select thought types + optional Other text
  final Set<String> _selectedTypes = {};
  late final TextEditingController _q2OtherCtrl;

  // Q3 — permission-giving thoughts
  late final TextEditingController _q3Ctrl;

  // Q4 — friend encouragement
  late final TextEditingController _q4Ctrl;

  // Q5 — dynamic counter-responses (min 1)
  final List<TextEditingController> _counterCtrls = [];
  bool _q5ExampleDismissed = false;

  @override
  void initState() {
    super.initState();
    _q2OtherCtrl = TextEditingController()..addListener(() => setState(() {}));
    _q3Ctrl = TextEditingController()..addListener(() => setState(() {}));
    _q4Ctrl = TextEditingController()..addListener(() => setState(() {}));
    _addThoughtCtrl('');
    _addCounterCtrl('');
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromPath());
  }

  @override
  void dispose() {
    for (final c in _thoughtCtrls) c.dispose();
    _q2OtherCtrl.dispose();
    _q3Ctrl.dispose();
    _q4Ctrl.dispose();
    for (final c in _counterCtrls) c.dispose();
    super.dispose();
  }

  void _addThoughtCtrl(String text) {
    final ctrl = TextEditingController(text: text)
      ..addListener(() => setState(() {}));
    _thoughtCtrls.add(ctrl);
  }

  void _addCounterCtrl(String text) {
    final ctrl = TextEditingController(text: text)
      ..addListener(() => setState(() {}));
    _counterCtrls.add(ctrl);
  }

  void _initFromPath() {
    final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    if (path == null) return;

    if (path.thoughtExaminationResult != null &&
        path.thoughtExaminationDraftStep == 0) {
      _loadFromMap(path.thoughtExaminationResult!, isResult: true);
      setState(() {
        _showOpening = false;
        _editMode = true;
      });
      return;
    }

    if (path.thoughtExaminationDraftStep > 0 &&
        path.thoughtExaminationDraft != null) {
      _loadFromMap(path.thoughtExaminationDraft!, isResult: false);
      setState(() {
        _showOpening = false;
        _step = path.thoughtExaminationDraftStep;
      });
    }
  }

  void _loadFromMap(Map<String, dynamic> data, {required bool isResult}) {
    // Q1 thoughts
    for (final c in _thoughtCtrls) c.dispose();
    _thoughtCtrls.clear();
    final ts = (data['thoughts'] as List?)?.cast<String>() ?? [];
    for (final t in ts) _addThoughtCtrl(t);
    if (_thoughtCtrls.isEmpty) _addThoughtCtrl('');

    // Q2 thought types
    _selectedTypes.clear();
    final types = (data['thoughtTypes'] as List?)?.cast<String>() ?? [];
    _selectedTypes.addAll(types);
    _q2OtherCtrl.text = isResult
        ? (data['otherThoughtType'] as String?) ?? ''
        : (data['q2Other'] as String?) ?? '';

    // Q3
    _q3Ctrl.text = isResult
        ? (data['permissionGivingThoughts'] as String?) ?? ''
        : (data['q3'] as String?) ?? '';

    // Q4
    _q4Ctrl.text = isResult
        ? (data['friendEncouragement'] as String?) ?? ''
        : (data['q4'] as String?) ?? '';

    // Q5 counter-responses
    for (final c in _counterCtrls) c.dispose();
    _counterCtrls.clear();
    final crs = (data['counterResponses'] as List?)?.cast<String>() ?? [];
    for (final cr in crs) _addCounterCtrl(cr);
    if (_counterCtrls.isEmpty) _addCounterCtrl('');
  }

  Map<String, dynamic> _buildDraft() => {
        'thoughts': _thoughtCtrls
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'thoughtTypes': _selectedTypes.toList(),
        'q2Other': _q2OtherCtrl.text.trim(),
        'q3': _q3Ctrl.text.trim(),
        'q4': _q4Ctrl.text.trim(),
        'counterResponses': _counterCtrls
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
      };

  Map<String, dynamic> _buildResult() => {
        'thoughts': _thoughtCtrls
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'thoughtTypes': _selectedTypes.toList(),
        'otherThoughtType': _q2OtherCtrl.text.trim(),
        'permissionGivingThoughts': _q3Ctrl.text.trim(),
        'friendEncouragement': _q4Ctrl.text.trim(),
        'counterResponses': _counterCtrls
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'savedAt': Timestamp.now(),
      };

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _thoughtCtrls.any((c) => c.text.trim().isNotEmpty);
      case 1:
        return _selectedTypes.isNotEmpty;
      case 2:
        return _q3Ctrl.text.trim().isNotEmpty;
      case 3:
        return _q4Ctrl.text.trim().isNotEmpty;
      case 4:
        return _counterCtrls.any((c) => c.text.trim().isNotEmpty);
      default:
        return false;
    }
  }

  bool get _canSaveEdit =>
      _thoughtCtrls.any((c) => c.text.trim().isNotEmpty) &&
      _q3Ctrl.text.trim().isNotEmpty &&
      _q4Ctrl.text.trim().isNotEmpty &&
      _counterCtrls.any((c) => c.text.trim().isNotEmpty);

  Future<void> _advance() async {
    setState(() => _step++);
    await context.read<RecoveryPathProvider>().saveThoughtExaminationDraft(
        widget.habitId, _step, _buildDraft());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final path = prov.pathFor(widget.habitId);
      _isFirstSave = path?.thoughtExaminationResult == null &&
          (path?.counterResponses.isEmpty ?? true);
      final result = _buildResult();
      final now = DateTime.now();
      final sessionData = Map<String, dynamic>.from(result)..remove('savedAt');
      await prov.saveSession(RecoverySession(
        id: '${widget.habitId}_m2ThoughtExamination_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m2ThoughtExamination,
        moduleNumber: 2,
        responseText: jsonEncode(sessionData),
        createdAt: now,
      ));
      await prov.saveThoughtExaminationResult(widget.habitId, result);
      if (mounted) {
        setState(() {
          _saving = false;
          _phase = _Phase.affirmation;
        });
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
      setState(() => _showOpening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.affirmation) return const _AffirmationView();
    if (_phase == _Phase.postSave) {
      return _PostSaveView(habitId: widget.habitId, isFirstSave: _isFirstSave);
    }
    if (_editMode) return _buildEditScaffold();
    if (_showOpening) return _buildOpeningScaffold();
    return _buildStepScaffold();
  }

  // ── Opening scaffold ─────────────────────────────────────────────────────────

  Widget _buildOpeningScaffold() {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            top: false,
            child: Column(
              children: [
                _StepDots(step: -1, total: 5),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The cue doesn\'t cause the behaviour — the thought does. '
                          'This takes about 5 minutes and works best done as soon as possible after you notice the thought.',
                          style: TextStyle(
                              fontSize: 15,
                              color:
                                  MyWalkColor.warmWhite.withValues(alpha: 0.72),
                              height: 1.65),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'What we will do',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: MyWalkColor.warmWhite),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Here\'s what you\'ll do: write the thought down exactly as it occurred, '
                          'identify what kind of thought it is, then write a honest response to it.',
                          style: TextStyle(
                              fontSize: 15,
                              color:
                                  MyWalkColor.warmWhite.withValues(alpha: 0.72),
                              height: 1.65),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                setState(() => _showOpening = false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kRpPurple,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Start',
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
          ),
        ],
      ),
    );
  }

  // ── Step scaffold ─────────────────────────────────────────────────────────────

  Widget _buildStepScaffold() {
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
            top: false,
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                        child: const Text('Next',
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

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildQ1();
      case 1:
        return _buildQ2();
      case 2:
        return _buildQ3();
      case 3:
        return _buildQ4();
      case 4:
        return _buildQ5();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Edit scaffold ─────────────────────────────────────────────────────────────

  Widget _buildEditScaffold() {
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQ1(),
                        _buildEditDivider('What kind of thoughts'),
                        _buildQ2(),
                        _buildEditDivider('Permission-giving thoughts'),
                        _buildQ3(),
                        _buildEditDivider('Friend perspective'),
                        _buildQ4(),
                        _buildEditDivider('Counter-responses'),
                        _buildQ5(inEditMode: true),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_canSaveEdit && !_saving) ? _save : null,
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
                          : const Text('Save changes',
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

  Widget _buildEditDivider(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: _kRpPurple.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kRpPurple.withValues(alpha: 0.7),
                  letterSpacing: 0.4)),
        ],
      ),
    );
  }

  // ── Q1 — Thoughts (dynamic list) ─────────────────────────────────────────────

  Widget _buildQ1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What thoughts came up?',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'Write each one exactly as it occurred — the uncleaned version.',
          style: TextStyle(
              fontSize: 12,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              height: 1.5,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < _thoughtCtrls.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _thoughtCtrls[i],
                  minLines: 2,
                  maxLines: null,
                  autofocus: i == 0 && _step == 0 && !_editMode,
                  style: const TextStyle(
                      color: MyWalkColor.warmWhite, fontSize: 15, height: 1.6),
                  decoration: InputDecoration(
                    hintText: 'Write the thought here...',
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
              ),
              if (_thoughtCtrls.length > 1) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _thoughtCtrls[i].dispose();
                      _thoughtCtrls.removeAt(i);
                    }),
                    child: Icon(Icons.remove_circle_outline_rounded,
                        size: 20,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _addThoughtCtrl('')),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  size: 16, color: _kRpPurple.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text('Add another thought',
                  style: TextStyle(
                      fontSize: 13,
                      color: _kRpPurple.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (!_editMode) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _kQ1Examples
                .asMap()
                .entries
                .where((e) => !_dismissedQ1Examples.contains(e.key))
                .map((e) => _ExampleChip(
                      label: e.value,
                      onTap: () => setState(() {
                        if (_thoughtCtrls.isNotEmpty) {
                          _thoughtCtrls.first.text = e.value;
                        }
                      }),
                      onDismiss: () =>
                          setState(() => _dismissedQ1Examples.add(e.key)),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Q2 — Thought types (multi-select) ────────────────────────────────────────

  Widget _buildQ2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What kind of thoughts are these?',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 6),
        Text(
          'Select all that apply.',
          style: TextStyle(
              fontSize: 12,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
              height: 1.4),
        ),
        const SizedBox(height: 16),
        ..._kThoughtTypes.map((t) => _DescOnlyCard(
              description: t.description,
              selected: _selectedTypes.contains(t.key),
              onTap: () => setState(() {
                if (_selectedTypes.contains(t.key)) {
                  _selectedTypes.remove(t.key);
                } else {
                  _selectedTypes.add(t.key);
                }
              }),
            )),
        _DescOnlyCard(
          description: 'Other →',
          selected: _selectedTypes.contains('other'),
          onTap: () => setState(() {
            if (_selectedTypes.contains('other')) {
              _selectedTypes.remove('other');
            } else {
              _selectedTypes.add('other');
            }
          }),
        ),
        if (_selectedTypes.contains('other')) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _q2OtherCtrl,
            style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
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

  // ── Q3 — Permission-giving thoughts ──────────────────────────────────────────

  Widget _buildQ3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What permission-giving thoughts came up?',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'Thoughts like "I deserve this", "just this once", "no one will know". Write them out exactly.',
          style: TextStyle(
              fontSize: 12,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              height: 1.5,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _q3Ctrl,
          minLines: 3,
          maxLines: null,
          autofocus: _step == 2 && !_editMode,
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
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Q4 — Friend encouragement ─────────────────────────────────────────────────

  Widget _buildQ4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What would you say to a close friend who came to you believing these same thoughts?',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'What you\'d say to them is often truer than what you tell yourself.',
          style: TextStyle(
              fontSize: 12,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              height: 1.5,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _q4Ctrl,
          minLines: 3,
          maxLines: null,
          autofocus: _step == 3 && !_editMode,
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
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Q5 — Counter-responses (dynamic list) + Save ──────────────────────────────

  Widget _buildQ5({bool inEditMode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Write your counter-responses',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'What do you know to be true? What would you say back to these thoughts?',
          style: TextStyle(
              fontSize: 12,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              height: 1.5,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < _counterCtrls.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _counterCtrls[i],
                  minLines: 2,
                  maxLines: null,
                  autofocus: i == 0 && _step == 4 && !inEditMode,
                  style: const TextStyle(
                      color: MyWalkColor.warmWhite, fontSize: 15, height: 1.6),
                  decoration: InputDecoration(
                    hintText: 'Write your response here...',
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
              ),
              if (_counterCtrls.length > 1) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _counterCtrls[i].dispose();
                      _counterCtrls.removeAt(i);
                    }),
                    child: Icon(Icons.remove_circle_outline_rounded,
                        size: 20,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _addCounterCtrl('')),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  size: 16, color: _kRpPurple.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text('Add another counter-response',
                  style: TextStyle(
                      fontSize: 13,
                      color: _kRpPurple.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (!_q5ExampleDismissed) ...[
          const SizedBox(height: 12),
          _ExampleChip(
            label: _kQ5Example,
            onTap: () => setState(() {
              if (_counterCtrls.isNotEmpty) {
                _counterCtrls.first.text = _kQ5Example;
              }
            }),
            onDismiss: () => setState(() => _q5ExampleDismissed = true),
          ),
        ],
        if (!inEditMode) ...[
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_canAdvance && !_saving) ? _save : null,
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
                  : const Text('Save to my Freedom Plan',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// ── Step dots ─────────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int step;
  final int total;
  const _StepDots({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          ...List.generate(total, (i) {
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
          if (step >= 0 && step < 5) ...[
            const SizedBox(width: 10),
            Text(
              'Step ${step + 1} of 5',
              style: TextStyle(
                  fontSize: 11,
                  color: _kRpPurple.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Description-only select card (used for Q2 multi-select) ──────────────────

class _DescOnlyCard extends StatelessWidget {
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _DescOnlyCard({
    required this.description,
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
              child: Text(
                description,
                style: TextStyle(
                    fontSize: 13,
                    color: selected
                        ? _kRpPurple
                        : MyWalkColor.warmWhite.withValues(alpha: 0.75)),
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

// ── Example chip ──────────────────────────────────────────────────────────────

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
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.55))),
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

// ── Post-save ─────────────────────────────────────────────────────────────────

class _PostSaveView extends StatelessWidget {
  final String habitId;
  final bool isFirstSave;
  const _PostSaveView({required this.habitId, this.isFirstSave = false});

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
                  const SizedBox(height: 14),
                  Text(
                    'You slowed down a thought that usually moves faster than you can catch it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                        height: 1.5),
                  ),
                  if (isFirstSave) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kRpPurple.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _kRpPurple.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.library_books_rounded,
                              size: 16,
                              color: _kRpPurple.withValues(alpha: 0.8)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The "My counter-responses" button will now appear on your habit card.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _kRpPurple.withValues(alpha: 0.9),
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
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
                        builder: (_) => RecordAMomentScreen(habitId: habitId),
                      ),
                    ),
                    child: Text(
                      'Record a moment',
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
