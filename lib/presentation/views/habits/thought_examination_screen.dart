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
  'I\'ve earned this.',
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
  final Color accentColor;

  const ThoughtExaminationScreen({super.key, required this.habitId, this.accentColor = _kRpPurple});

  @override
  State<ThoughtExaminationScreen> createState() =>
      _ThoughtExaminationScreenState();
}

class _ThoughtExaminationScreenState extends State<ThoughtExaminationScreen> {
  Color get _kRpPurple => widget.accentColor;

  bool _showOpening = true;
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
  bool _savedToLibraryFirst = false;

  // Review mode — entered when counterResponses exists and no draft is active
  bool _reviewMode = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreDraft();
      _maybeEnterReviewMode();
    });
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
      _showOpening = false;
      _step = path.thoughtExaminationDraftStep;
      _step0Ctrl.text = (draft['step0'] as String?) ?? '';
      _step1Selection = draft['step1'] as String?;
      _step1OtherCtrl.text = (draft['step1Other'] as String?) ?? '';
      _step2aCtrl.text = (draft['step2a'] as String?) ?? '';
      _step2bCtrl.text = (draft['step2b'] as String?) ?? '';
      _step3Ctrl.text = (draft['step3'] as String?) ?? '';
    });
  }

  void _maybeEnterReviewMode() {
    final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    if (path == null || path.counterResponses.isEmpty) return;
    // Draft takes priority — if a draft is in progress, don't clobber it.
    if (path.thoughtExaminationDraftStep > 0) return;
    final cr = path.counterResponses.last;
    final errorType = cr['errorType'] as String? ?? '';
    setState(() {
      _reviewMode = true;
      _showOpening = false;
      _step0Ctrl.text = cr['thought'] as String? ?? '';
      _step3Ctrl.text = cr['alternative'] as String? ?? '';
      final known = _kThoughtTypes.any((t) => t.key == errorType);
      if (known) {
        _step1Selection = errorType;
      } else {
        _step1Selection = 'other';
        _step1OtherCtrl.text = errorType;
      }
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
        'honestResponse': _step2bCtrl.text.trim(),
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
        final isFirst = prov.pathFor(widget.habitId)?.counterResponses.isEmpty ?? true;
        await prov.addCounterResponse(widget.habitId, {
          'thought': _step0Ctrl.text.trim(),
          'errorType': errorType,
          'alternative': alternative,
          'createdAt': Timestamp.now(),
        });
        if (isFirst) _savedToLibraryFirst = true;
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
    if (_reviewMode) {
      Navigator.of(context).pop();
      return;
    }
    if (_step > 0) {
      setState(() => _step--);
    } else {
      setState(() => _showOpening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.affirmation) return _AffirmationView();
    if (_phase == _Phase.postSave) return _PostSaveView(habitId: widget.habitId, showCounterResponseNotification: _savedToLibraryFirst);
    if (_reviewMode) return _buildReviewScaffold();
    if (_showOpening) return _buildOpeningScaffold();

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
          SafeArea(top: false,
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

  String _formatReviewDate(dynamic createdAt) {
    DateTime? dt;
    if (createdAt is Timestamp) dt = createdAt.toDate();
    if (dt == null) return '';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  Widget _buildReviewScaffold() {
    final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    final cr = (path != null && path.counterResponses.isNotEmpty)
        ? path.counterResponses.last
        : null;
    final thought = cr?['thought'] as String? ?? '';
    final errorType = cr?['errorType'] as String? ?? '';
    final alternative = cr?['alternative'] as String? ?? '';
    final dateStr = _formatReviewDate(cr?['createdAt']);
    final typeDesc = _kThoughtTypes
        .where((t) => t.key == errorType)
        .map((t) => t.description)
        .firstOrNull ?? errorType;

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        width: 3, height: 18,
                        decoration: BoxDecoration(
                            color: _kRpPurple,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Text('Most recent examination',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kRpPurple.withValues(alpha: 0.9))),
                    const Spacer(),
                    if (dateStr.isNotEmpty)
                      Text(dateStr,
                          style: TextStyle(
                              fontSize: 12,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.4))),
                  ]),
                  const SizedBox(height: 20),
                  _ReviewSection(label: 'The thought', value: thought),
                  if (typeDesc.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ReviewSection(label: 'Thought type', value: typeDesc),
                  ],
                  const SizedBox(height: 16),
                  _ReviewSection(label: 'Your counter-response', value: alternative),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() {
                        _reviewMode = false;
                        _showOpening = true;
                        _step = 0;
                        _step0Ctrl.clear();
                        _step1Selection = null;
                        _step1OtherCtrl.clear();
                        _step2aCtrl.clear();
                        _step2bCtrl.clear();
                        _step3Ctrl.clear();
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Examine a new thought',
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
          SafeArea(top: false,
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
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.72),
                              height: 1.65),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Here\'s what you\'ll do: write the thought down exactly as it occurred, '
                          'identify what kind of thought it is, then write a more honest response to it.',
                          style: TextStyle(
                              fontSize: 15,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.72),
                              height: 1.65),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _showOpening = false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kRpPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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

  // ── Step 1 — Thought type (descriptions only — no clinical labels shown) ────

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
        ..._kThoughtTypes.map((t) => _DescOnlyCard(
              description: t.description,
              selected: _step1Selection == t.key,
              onTap: () => setState(() => _step1Selection = t.key),
            )),
        _DescOnlyCard(
          description: 'Other →',
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

  // ── Step 2 — Evidence from history + honest response ─────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'When you\'ve given in to this thought before — what actually happened in the hours after? Not what you hoped. What actually happened.',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 6),
        Text(
          'Your honest answer to this is the only evidence that matters.',
          style: TextStyle(
              fontSize: 12,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
              fontStyle: FontStyle.italic,
              height: 1.4),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _step2aCtrl,
          minLines: 3,
          maxLines: null,
          autofocus: true,
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
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.arrow_downward_rounded,
                size: 14, color: _kRpPurple.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              '↓ builds on your answer above',
              style: TextStyle(
                  fontSize: 12,
                  color: _kRpPurple.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Based on that — what\'s the most truthful thing you can say back to this thought right now?',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 6),
        Text(
          'Not "everything will be fine." Something you actually believe, built from what you just wrote.',
          style: TextStyle(
              fontSize: 12,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
              fontStyle: FontStyle.italic,
              height: 1.4),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _step2bCtrl,
          minLines: 3,
          maxLines: null,
          autofocus: false,
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
          'Write your counter-response in your own words — draw on the evidence you just wrote.',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 10),
        Text(
          'Not an affirmation. Something grounded in your own history.',
          style: TextStyle(
              fontSize: 12,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              height: 1.5,
              fontStyle: FontStyle.italic),
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
            hintText: 'Write your counter-response here',
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

// ── Review section widget ─────────────────────────────────────────────────────

class _ReviewSection extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewSection({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kRpPurple.withValues(alpha: 0.7),
                letterSpacing: 0.6)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MyWalkColor.surfaceOverlay,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite,
                  height: 1.55)),
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
          if (step >= 0 && step < 4) ...[
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
  final bool showCounterResponseNotification;
  const _PostSaveView({required this.habitId, this.showCounterResponseNotification = false});

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
                        Icon(Icons.touch_app_rounded,
                            size: 16,
                            color: _kRpPurple.withValues(alpha: 0.8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'The "Examine a thought" button will now appear on your habit card.',
                            style: TextStyle(
                                fontSize: 13,
                                color: _kRpPurple.withValues(alpha: 0.9),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showCounterResponseNotification) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kRpPurple.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _kRpPurple.withValues(alpha: 0.2)),
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
