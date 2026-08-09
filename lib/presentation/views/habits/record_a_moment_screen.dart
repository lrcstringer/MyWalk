import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_phase_calculator.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'lapse_recording_flow.dart';

const _kRpPurple = Color(0xFF8B7EC8);

enum _RecordVersion { lighter, medium, full }

/// "Record a moment" — branches on "Did you act on it, or did you navigate it?".
/// Version is determined by the user's current phase and whether they've written
/// their recovery letter. Full version (Branch B only) routes to LapseRecordingFlow.
class RecordAMomentScreen extends StatefulWidget {
  final String habitId;

  const RecordAMomentScreen({super.key, required this.habitId});

  @override
  State<RecordAMomentScreen> createState() => _RecordAMomentScreenState();
}

class _RecordAMomentScreenState extends State<RecordAMomentScreen> {
  String? _branch; // null=unselected, 'navigated', 'acted'
  bool _done = false;
  bool _saving = false;
  bool _hasLapseDraft = false;

  String get _navDraftKey => 'ram_nav_draft_${widget.habitId}';
  String get _lapseFlagKey => 'ram_lapse_flag_${widget.habitId}';

  // Phase 1 lighter fields (3 required)
  final _happenedCtrl = TextEditingController();
  final _phase1FeelingCtrl = TextEditingController();
  final _nextStepCtrl = TextEditingController();

  // Phase 2+ medium fields (3 required, 3 optional)
  final _locationCtrl = TextEditingController();
  final _activityCtrl = TextEditingController();
  final _emotionCtrl = TextEditingController();
  final _thoughtCtrl = TextEditingController();
  final _compassionCtrl = TextEditingController();
  final _immediateStepCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [
      _happenedCtrl,
      _phase1FeelingCtrl,
      _nextStepCtrl,
      _locationCtrl,
      _activityCtrl,
      _emotionCtrl,
      _compassionCtrl,
      _immediateStepCtrl,
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
    _happenedCtrl.dispose();
    _phase1FeelingCtrl.dispose();
    _nextStepCtrl.dispose();
    _locationCtrl.dispose();
    _activityCtrl.dispose();
    _emotionCtrl.dispose();
    _thoughtCtrl.dispose();
    _compassionCtrl.dispose();
    _immediateStepCtrl.dispose();
    super.dispose();
  }

  // ── Draft persistence ─────────────────────────────────────────────────────

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
      _happenedCtrl.text = (data['happened'] as String?) ?? '';
      _phase1FeelingCtrl.text = (data['feeling'] as String?) ?? '';
      _nextStepCtrl.text = (data['nextStep'] as String?) ?? '';
      _locationCtrl.text = (data['location'] as String?) ?? '';
      _activityCtrl.text = (data['activity'] as String?) ?? '';
      _emotionCtrl.text = (data['emotion'] as String?) ?? '';
      _thoughtCtrl.text = (data['thought'] as String?) ?? '';
      _compassionCtrl.text = (data['compassion'] as String?) ?? '';
      _immediateStepCtrl.text = (data['immediateStep'] as String?) ?? '';
    });
  }

  Future<void> _saveDraft() async {
    if (_branch != 'navigated') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_navDraftKey, jsonEncode({
      'branch': _branch,
      'happened': _happenedCtrl.text,
      'feeling': _phase1FeelingCtrl.text,
      'nextStep': _nextStepCtrl.text,
      'location': _locationCtrl.text,
      'activity': _activityCtrl.text,
      'emotion': _emotionCtrl.text,
      'thought': _thoughtCtrl.text,
      'compassion': _compassionCtrl.text,
      'immediateStep': _immediateStepCtrl.text,
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
      MaterialPageRoute(
        builder: (_) => LapseRecordingFlow(habitId: widget.habitId),
      ),
    );
  }

  _RecordVersion _getVersion(RecoveryPathProvider prov) {
    final path = prov.pathFor(widget.habitId);
    if (path == null) return _RecordVersion.lighter;
    final phase = RecoveryPhaseCalculator.calculate(path);
    if (phase <= 1) return _RecordVersion.lighter;
    if (path.module5.recoveryLetterWritten) return _RecordVersion.full;
    return _RecordVersion.medium;
  }

  bool get _canSaveLighter =>
      _happenedCtrl.text.trim().isNotEmpty &&
      _phase1FeelingCtrl.text.trim().isNotEmpty &&
      _nextStepCtrl.text.trim().isNotEmpty;

  bool get _canSaveMedium =>
      _locationCtrl.text.trim().isNotEmpty &&
      _activityCtrl.text.trim().isNotEmpty &&
      _emotionCtrl.text.trim().isNotEmpty &&
      _thoughtCtrl.text.trim().isNotEmpty;

  Future<void> _save(_RecordVersion version) async {
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();
      final Map<String, dynamic> payload;

      if (version == _RecordVersion.lighter) {
        payload = {
          'branch': _branch,
          'happened': _happenedCtrl.text.trim(),
          'feeling': _phase1FeelingCtrl.text.trim(),
          'nextStep': _nextStepCtrl.text.trim(),
        };
      } else {
        payload = {
          'branch': _branch,
          'locationTime': _locationCtrl.text.trim(),
          'activityBefore': _activityCtrl.text.trim(),
          'emotionalState': _emotionCtrl.text.trim(),
          'thoughtArose': _thoughtCtrl.text.trim(),
          if (_compassionCtrl.text.trim().isNotEmpty)
            'compassion': _compassionCtrl.text.trim(),
          if (_immediateStepCtrl.text.trim().isNotEmpty)
            'immediateStep': _immediateStepCtrl.text.trim(),
        };
      }

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
    final prov = context.watch<RecoveryPathProvider>();
    final version = _getVersion(prov);

    if (_done) return _buildDoneScaffold();
    if (_branch != null) return _buildForm(version);
    return _buildEntryScaffold(version);
  }

  // ── Entry screen ──────────────────────────────────────────────────────────

  Widget _buildEntryScaffold(_RecordVersion version) {
    if (_hasLapseDraft && version == _RecordVersion.full) {
      return _buildLapseResumeScaffold();
    }

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Record a moment',
          style: TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        leading: const BackButton(color: MyWalkColor.warmWhite),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  const Spacer(),
                  const Text(
                    'Did you act on it, or did you navigate it?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.35),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _branch = 'navigated');
                            _saveDraft();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MyWalkColor.warmWhite,
                            side: BorderSide(
                                color: MyWalkColor.warmWhite
                                    .withValues(alpha: 0.3)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('I navigated it',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            if (version == _RecordVersion.full) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool(_lapseFlagKey, true);
                              if (!mounted) return;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => LapseRecordingFlow(
                                      habitId: widget.habitId),
                                ),
                              );
                            } else {
                              setState(() => _branch = 'acted');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MyWalkColor.warmWhite,
                            side: BorderSide(
                                color: MyWalkColor.warmWhite
                                    .withValues(alpha: 0.3)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('I acted on it',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 15)),
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

  Widget _buildLapseResumeScaffold() {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Record a moment',
          style: TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        leading: const BackButton(color: MyWalkColor.warmWhite),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
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
                      border: Border.all(
                          color: _kRpPurple.withValues(alpha: 0.2),
                          width: 0.75),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'It looks like you were working through something earlier.',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: MyWalkColor.warmWhite,
                              height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Do you want to continue from where you were?',
                          style: TextStyle(
                              fontSize: 14,
                              color: MyWalkColor.warmWhite
                                  .withValues(alpha: 0.65),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Continue',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15)),
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
                                  color: MyWalkColor.warmWhite
                                      .withValues(alpha: 0.45)),
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

  // ── Form ─────────────────────────────────────────────────────────────────

  Widget _buildForm(_RecordVersion version) {
    final isLighter = version == _RecordVersion.lighter;
    final canSave = isLighter ? _canSaveLighter : _canSaveMedium;
    final badgeLabel =
        _branch == 'navigated' ? 'Navigated' : 'Acted on it';

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Record a moment',
          style: TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        leading: BackButton(
          color: MyWalkColor.warmWhite,
          onPressed: () => setState(() => _branch = null),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StepBadge(label: badgeLabel),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: isLighter
                          ? _lighterFields()
                          : _mediumFields(),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      MediaQuery.of(context).viewInsets.bottom + 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          canSave && !_saving ? () => _save(version) : null,
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
                          : const Text('Save',
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

  List<Widget> _lighterFields() => [
        _RamField(
          label: 'What happened, and where were you?',
          controller: _happenedCtrl,
          autofocus: true,
        ),
        _RamField(
          label: 'How were you feeling?',
          controller: _phase1FeelingCtrl,
        ),
        _RamField(
          label: "What's one thing you'll do right now?",
          controller: _nextStepCtrl,
          last: true,
        ),
      ];

  List<Widget> _mediumFields() => [
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
          label:
              'What were you feeling emotionally? Name it + rate intensity out of 10.',
          controller: _emotionCtrl,
        ),
        _RamField(
          label: 'What thought arose just before? Even a single sentence is fine.',
          controller: _thoughtCtrl,
          optional: true,
        ),
        _RamField(
          label:
              'What would you say to yourself with compassion about this moment?',
          controller: _compassionCtrl,
          optional: true,
        ),
        _RamField(
          label: "What's your immediate next step right now?",
          controller: _immediateStepCtrl,
          optional: true,
          last: true,
        ),
      ];

  // ── Completion ────────────────────────────────────────────────────────────

  Widget _buildDoneScaffold() {
    final affirmation = _branch == 'navigated'
        ? 'Logged. Every honest record brings you closer to understanding your pattern.'
        : 'Logged. Coming back and recording this honestly is the practice.';

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
                  Text(
                    affirmation,
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

// ── Shared widgets ────────────────────────────────────────────────────────────

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
