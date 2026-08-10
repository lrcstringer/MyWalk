import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'lapse_recording_flow.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// ONG01 — "Record a moment"
///
/// Phase versioning:
///   Phase 1 (lighter)       → 3-field form, both branches
///   Phase 2+ before letter  → Branch A: 4-field medium
///                             Branch B: 4+compassion+nextstep medium
///   Phase 2+ after letter   → Branch A: 4-field medium (unchanged)
///                             Branch B: full LapseRecordingFlow
enum _RecordVersion { lighter, medium, full }

class RecordAMomentScreen extends StatefulWidget {
  final String habitId;

  const RecordAMomentScreen({super.key, required this.habitId});

  @override
  State<RecordAMomentScreen> createState() => _RecordAMomentScreenState();
}

class _RecordAMomentScreenState extends State<RecordAMomentScreen> {
  // null = entry screen, 'navigated', 'acted_lighter', 'acted_medium'
  String? _branch;
  bool _done = false;
  bool _saving = false;
  bool _hasLapseDraft = false;
  String _doneAffirmation = '';

  String get _navDraftKey => 'ram_nav_draft_${widget.habitId}';
  String get _lapseFlagKey => 'ram_lapse_flag_${widget.habitId}';

  // Phase 1 lighter — 3 fields, shared by both branches
  final _lHappenedCtrl = TextEditingController();
  final _lFeelingCtrl = TextEditingController();
  final _lNextStepCtrl = TextEditingController();

  // Phase 2+ — 4 shared location/activity/emotion/thought fields
  final _locationCtrl = TextEditingController();
  final _activityCtrl = TextEditingController();
  final _emotionCtrl = TextEditingController();
  final _thoughtCtrl = TextEditingController();

  // Phase 2+ Branch B medium additions
  final _compassionCtrl = TextEditingController();
  final _medNextStepCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [
      _lHappenedCtrl, _lFeelingCtrl, _lNextStepCtrl,
      _locationCtrl, _activityCtrl, _emotionCtrl, _thoughtCtrl,
      _compassionCtrl, _medNextStepCtrl,
    ]) {
      c.addListener(() {
        setState(() {});
        if (_branch == 'navigated') _saveDraft();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDraft();
      _checkLapseDraft();
    });
  }

  @override
  void dispose() {
    _lHappenedCtrl.dispose();
    _lFeelingCtrl.dispose();
    _lNextStepCtrl.dispose();
    _locationCtrl.dispose();
    _activityCtrl.dispose();
    _emotionCtrl.dispose();
    _thoughtCtrl.dispose();
    _compassionCtrl.dispose();
    _medNextStepCtrl.dispose();
    super.dispose();
  }

  _RecordVersion _getVersion() {
    final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    if (path == null || path.currentPhase == 1) return _RecordVersion.lighter;
    if (path.module5.recoveryLetterWritten) return _RecordVersion.full;
    return _RecordVersion.medium;
  }

  // ── Draft ─────────────────────────────────────────────────────────────────

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final raw = prefs.getString(_navDraftKey);
    if (raw == null) return;
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    setState(() {
      _branch = data['branch'] as String?;
      _lHappenedCtrl.text = (data['happened'] as String?) ?? '';
      _lFeelingCtrl.text = (data['feeling'] as String?) ?? '';
      _lNextStepCtrl.text = (data['lNextStep'] as String?) ?? '';
      _locationCtrl.text = (data['location'] as String?) ?? '';
      _activityCtrl.text = (data['activity'] as String?) ?? '';
      _emotionCtrl.text = (data['emotion'] as String?) ?? '';
      _thoughtCtrl.text = (data['thought'] as String?) ?? '';
    });
  }

  Future<void> _saveDraft() async {
    if (_branch != 'navigated') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_navDraftKey, jsonEncode({
      'branch': _branch,
      'happened': _lHappenedCtrl.text,
      'feeling': _lFeelingCtrl.text,
      'lNextStep': _lNextStepCtrl.text,
      'location': _locationCtrl.text,
      'activity': _activityCtrl.text,
      'emotion': _emotionCtrl.text,
      'thought': _thoughtCtrl.text,
    }));
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_navDraftKey);
  }

  Future<void> _checkLapseDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _hasLapseDraft = prefs.getBool(_lapseFlagKey) ?? false);
  }

  Future<void> _discardLapseDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lapseFlagKey);
    if (mounted) setState(() => _hasLapseDraft = false);
  }

  void _resumeLapseFlow() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LapseRecordingFlow(habitId: widget.habitId)),
    );
  }

  Future<void> _startLapseFlow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lapseFlagKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LapseRecordingFlow(habitId: widget.habitId)),
    );
  }

  // ── Can-save ──────────────────────────────────────────────────────────────

  bool get _canSaveLighter =>
      _lHappenedCtrl.text.trim().isNotEmpty &&
      _lFeelingCtrl.text.trim().isNotEmpty &&
      _lNextStepCtrl.text.trim().isNotEmpty;

  bool get _canSaveMediumNav =>
      _locationCtrl.text.trim().isNotEmpty &&
      _activityCtrl.text.trim().isNotEmpty &&
      _emotionCtrl.text.trim().isNotEmpty;

  bool get _canSaveMediumActed =>
      _locationCtrl.text.trim().isNotEmpty &&
      _activityCtrl.text.trim().isNotEmpty &&
      _emotionCtrl.text.trim().isNotEmpty &&
      _compassionCtrl.text.trim().isNotEmpty &&
      _medNextStepCtrl.text.trim().isNotEmpty;

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _doSave(Map<String, dynamic> payload, {String affirmation = ''}) async {
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();
      final session = RecoverySession(
        id: '${widget.habitId}_m1BehaviourLog_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m1BehaviourLog,
        moduleNumber: 1,
        responseText: jsonEncode(payload),
        createdAt: now,
      );
      await prov.saveSession(session);
      await _clearDraft();
      _doneAffirmation = affirmation;
      if (mounted) {
        setState(() { _saving = false; _done = true; });
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

  Future<void> _saveLighterNavigated() => _doSave({
    'branch': 'navigated_lighter',
    'whatHappened': _lHappenedCtrl.text.trim(),
    'emotionalState': _lFeelingCtrl.text.trim(),
    'nextStep': _lNextStepCtrl.text.trim(),
  }, affirmation: 'Logged. Every honest record brings you closer to understanding your pattern.');

  Future<void> _saveLighterActed() => _doSave({
    'branch': 'acted_lighter',
    'whatHappened': _lHappenedCtrl.text.trim(),
    'emotionalState': _lFeelingCtrl.text.trim(),
    'nextStep': _lNextStepCtrl.text.trim(),
  }, affirmation: 'Logged. Coming back and recording this honestly is the practice.');

  Future<void> _saveMediumNavigated() => _doSave({
    'branch': 'navigated',
    'locationTime': _locationCtrl.text.trim(),
    'activityBefore': _activityCtrl.text.trim(),
    'emotionalState': _emotionCtrl.text.trim(),
    if (_thoughtCtrl.text.trim().isNotEmpty) 'thoughtArose': _thoughtCtrl.text.trim(),
  }, affirmation: 'Logged. Every honest record brings you closer to understanding your pattern.');

  Future<void> _saveMediumActed() => _doSave({
    'branch': 'acted_medium',
    'locationTime': _locationCtrl.text.trim(),
    'activityBefore': _activityCtrl.text.trim(),
    'emotionalState': _emotionCtrl.text.trim(),
    if (_thoughtCtrl.text.trim().isNotEmpty) 'thoughtArose': _thoughtCtrl.text.trim(),
    'selfCompassion': _compassionCtrl.text.trim(),
    'nextStep': _medNextStepCtrl.text.trim(),
  }, affirmation: 'Logged. Coming back and recording this honestly is the practice.');

  // ── Routing ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<RecoveryPathProvider>();
    final version = _getVersion();

    if (_done) return _buildDoneScaffold();

    if (_branch == null) {
      if (_hasLapseDraft) return _buildLapseResumeScaffold();
      return _buildEntryScaffold(version);
    }

    if (_branch == 'navigated') {
      return version == _RecordVersion.lighter
          ? _buildLighterForm(isActed: false)
          : _buildMediumNavigatedForm();
    }

    if (_branch == 'acted_lighter') return _buildLighterForm(isActed: true);
    if (_branch == 'acted_medium') return _buildMediumActedForm();

    return _buildEntryScaffold(version);
  }

  // ── Entry ──────────────────────────────────────────────────────────────────

  Widget _buildEntryScaffold(_RecordVersion version) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Record a moment',
          style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: const BackButton(color: MyWalkColor.warmWhite),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  const Spacer(),
                  const Text(
                    'Did you act on it, or did you navigate it?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite, height: 1.35),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _branch = 'navigated'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MyWalkColor.warmWhite,
                            side: BorderSide(color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('I navigated it',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (version == _RecordVersion.full) {
                              _startLapseFlow();
                            } else if (version == _RecordVersion.medium) {
                              setState(() => _branch = 'acted_medium');
                            } else {
                              setState(() => _branch = 'acted_lighter');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MyWalkColor.warmWhite,
                            side: BorderSide(color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('I acted on it',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lapse draft resume ─────────────────────────────────────────────────────

  Widget _buildLapseResumeScaffold() {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Record a moment',
          style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: const BackButton(color: MyWalkColor.warmWhite),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kRpPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kRpPurple.withValues(alpha: 0.2), width: 0.75),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'It looks like you were working through something earlier.',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600,
                              color: MyWalkColor.warmWhite, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Do you want to continue from where you were?',
                          style: TextStyle(
                              fontSize: 14,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                              height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _resumeLapseFlow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kRpPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Continue',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: _discardLapseDraft,
                            child: Text(
                              'Start fresh',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: MyWalkColor.warmWhite.withValues(alpha: 0.45)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase 1 lighter form — 3 fields, both branches ────────────────────────

  Widget _buildLighterForm({required bool isActed}) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Record a moment',
          style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: BackButton(
          color: MyWalkColor.warmWhite,
          onPressed: () => setState(() => _branch = null),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StepBadge(label: isActed ? 'Acted on it' : 'Navigated'),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RamField(
                          label: 'What happened, and where were you?',
                          controller: _lHappenedCtrl,
                          autofocus: true,
                        ),
                        _RamField(
                          label: 'How were you feeling?',
                          controller: _lFeelingCtrl,
                        ),
                        _RamField(
                          label: "What's one thing you'll do right now?",
                          controller: _lNextStepCtrl,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSaveLighter && !_saving
                          ? (isActed ? _saveLighterActed : _saveLighterNavigated)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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

  // ── Phase 2+ navigated form — 4 fields ────────────────────────────────────

  Widget _buildMediumNavigatedForm() {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Record a moment',
          style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: BackButton(
          color: MyWalkColor.warmWhite,
          onPressed: () => setState(() => _branch = null),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StepBadge(label: 'Navigated'),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RamField(
                          label: 'Where were you? What time of day was it?',
                          hint: 'e.g. Home alone, 11pm · Office, after a difficult meeting',
                          controller: _locationCtrl,
                          autofocus: true,
                        ),
                        _RamField(
                          label: 'What were you doing immediately before?',
                          controller: _activityCtrl,
                        ),
                        _RamField(
                          label: 'What were you feeling emotionally? Name it + rate intensity out of 10.',
                          controller: _emotionCtrl,
                        ),
                        _RamField(
                          label: 'What thought arose just before?',
                          hint: 'Even a single sentence is fine.',
                          controller: _thoughtCtrl,
                          optional: true,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSaveMediumNav && !_saving ? _saveMediumNavigated : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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

  // ── Phase 2+ acted medium form — 4+compassion+nextstep ───────────────────

  Widget _buildMediumActedForm() {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Record a moment',
          style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: BackButton(
          color: MyWalkColor.warmWhite,
          onPressed: () => setState(() => _branch = null),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StepBadge(label: 'Acted on it'),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RamField(
                          label: 'Where were you? What time of day was it?',
                          hint: 'e.g. Home alone, 11pm · Office, after a difficult meeting',
                          controller: _locationCtrl,
                          autofocus: true,
                        ),
                        _RamField(
                          label: 'What were you doing immediately before?',
                          controller: _activityCtrl,
                        ),
                        _RamField(
                          label: 'What were you feeling emotionally? Name it + rate intensity out of 10.',
                          controller: _emotionCtrl,
                        ),
                        _RamField(
                          label: 'What thought arose just before?',
                          hint: 'Even a single sentence is fine.',
                          controller: _thoughtCtrl,
                          optional: true,
                        ),
                        _RamField(
                          label: 'What would you say to a good friend who had just gone through exactly this moment?',
                          controller: _compassionCtrl,
                        ),
                        _RamField(
                          label: "What's one thing you'll do right now?",
                          controller: _medNextStepCtrl,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSaveMediumActed && !_saving ? _saveMediumActed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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

  // ── Completion ────────────────────────────────────────────────────────────

  Widget _buildDoneScaffold() {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: DeepSpaceBackground())),
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
                    child: const Icon(Icons.check_rounded, color: _kRpPurple, size: 28),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _doneAffirmation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                        height: 1.6),
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

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _StepBadge extends StatelessWidget {
  final String label;
  const _StepBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kRpPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: _kRpPurple),
      ),
    );
  }
}

class _RamField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool autofocus;
  final bool optional;
  final bool last;

  const _RamField({
    required this.label,
    this.hint,
    required this.controller,
    this.autofocus = false,
    this.optional = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: MyWalkColor.warmWhite,
                      height: 1.4),
                ),
              ),
              if (optional)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    'Optional',
                    style: TextStyle(
                        fontSize: 12,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.35)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: null,
            autofocus: autofocus,
            style: const TextStyle(
                color: MyWalkColor.warmWhite, fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText: hint,
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
      ),
    );
  }
}
