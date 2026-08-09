import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_phase_calculator.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'lapse_recording_flow.dart';

const _kRpPurple = Color(0xFF8B7EC8);

enum _RamVersion { lighter, medium, full }

/// "Record a moment" — merged behaviour log + lapse entry point.
/// Opens with a branch question: "Did you act on it or navigate it?"
/// lighter = Phase 1, medium = Phase 2 before letter, full = Phase 2 after letter.
class RecordAMomentScreen extends StatefulWidget {
  final String habitId;

  const RecordAMomentScreen({super.key, required this.habitId});

  @override
  State<RecordAMomentScreen> createState() => _RecordAMomentScreenState();
}

class _RecordAMomentScreenState extends State<RecordAMomentScreen> {
  String? _branch; // null=choosing | 'navigated' | 'acted'
  _RamVersion? _cachedVersion;
  bool _done = false;
  bool _saving = false;
  String _affirmation = '';

  // Lighter form (3 fields)
  final _l1 = TextEditingController();
  final _l2 = TextEditingController();
  final _l3 = TextEditingController();

  // Medium form (4 required + 2 optional)
  final _m1 = TextEditingController();
  final _m2 = TextEditingController();
  final _m3 = TextEditingController();
  final _m4 = TextEditingController();
  final _mCompassion = TextEditingController();
  final _mNext = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [_l1, _l2, _l3, _m1, _m2, _m3, _m4, _mCompassion, _mNext]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_l1, _l2, _l3, _m1, _m2, _m3, _m4, _mCompassion, _mNext]) {
      c.dispose();
    }
    super.dispose();
  }

  _RamVersion _computeVersion() {
    final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    if (path == null) return _RamVersion.lighter;
    final phase = RecoveryPhaseCalculator.calculate(path);
    if (phase == 1) return _RamVersion.lighter;
    if (!path.module5.recoveryLetterWritten) return _RamVersion.medium;
    return _RamVersion.full;
  }

  void _onBranchSelected(String branch) {
    final version = _computeVersion();
    if (branch == 'acted' && version == _RamVersion.full) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LapseRecordingFlow(habitId: widget.habitId),
        ),
      );
      return;
    }
    setState(() {
      _branch = branch;
      _cachedVersion = version;
    });
  }

  bool get _canSave {
    final v = _cachedVersion ?? _RamVersion.lighter;
    if (v == _RamVersion.lighter) {
      return _l1.text.trim().isNotEmpty &&
          _l2.text.trim().isNotEmpty &&
          _l3.text.trim().isNotEmpty;
    }
    return _m1.text.trim().isNotEmpty &&
        _m2.text.trim().isNotEmpty &&
        _m3.text.trim().isNotEmpty &&
        _m4.text.trim().isNotEmpty;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();
      final v = _cachedVersion ?? _RamVersion.lighter;

      final Map<String, dynamic> payload;
      if (v == _RamVersion.lighter) {
        payload = {
          'branch': _branch,
          'whatHappened': _l1.text.trim(),
          'howFeeling': _l2.text.trim(),
          'nextStep': _l3.text.trim(),
        };
      } else {
        payload = {
          'branch': _branch,
          'locationTime': _m1.text.trim(),
          'activityBefore': _m2.text.trim(),
          'emotionName': _m3.text.trim(),
          'thoughtArose': _m4.text.trim(),
          if (_mCompassion.text.trim().isNotEmpty)
            'selfCompassion': _mCompassion.text.trim(),
          if (_mNext.text.trim().isNotEmpty)
            'immediateNext': _mNext.text.trim(),
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

      if (mounted) {
        _affirmation = _branch == 'navigated'
            ? 'Logged. Every honest record brings you closer to understanding your pattern.'
            : 'Logged. Coming back and recording this honestly is the practice.';
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
    if (_done) return _buildDoneScaffold();
    if (_branch == null) return _buildBranchScaffold();
    return _buildFormScaffold(_cachedVersion ?? _RamVersion.lighter);
  }

  // ── Branch selection ──────────────────────────────────────────────────────

  Widget _buildBranchScaffold() {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Record a moment',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: const BackButton(color: MyWalkColor.warmWhite),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Did you act on it, or did you navigate it?',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Either way, recording it honestly is the work.',
                    style: TextStyle(
                        fontSize: 14,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                        height: 1.5),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _onBranchSelected('navigated'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('I navigated it',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _onBranchSelected('acted'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MyWalkColor.warmWhite,
                        side: BorderSide(
                            color: MyWalkColor.warmWhite.withValues(alpha: 0.25)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
            ),
          ),
        ],
      ),
    );
  }

  // ── Form scaffold ─────────────────────────────────────────────────────────

  Widget _buildFormScaffold(_RamVersion version) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _branch == 'navigated' ? 'I navigated it' : 'I acted on it',
          style: const TextStyle(
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: version == _RamVersion.lighter
                        ? _buildLighterForm()
                        : _buildMediumForm(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20,
                      MediaQuery.of(context).viewInsets.bottom + 20),
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
                          : const Text('Save this moment',
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

  Widget _buildLighterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RamField(
          label: 'What happened, and where were you?',
          controller: _l1,
          autofocus: true,
        ),
        _RamField(
          label: 'How were you feeling?',
          controller: _l2,
        ),
        _RamField(
          label: "What's one thing you'll do right now?",
          controller: _l3,
          last: true,
        ),
      ],
    );
  }

  Widget _buildMediumForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RamField(
          label: 'Where were you? What time of day was it?',
          hint: 'e.g. Home alone, 11pm / Office, after a difficult meeting',
          controller: _m1,
          autofocus: true,
        ),
        _RamField(
          label: 'What were you doing immediately before?',
          controller: _m2,
        ),
        _RamField(
          label: 'What were you feeling emotionally? Name it + rate intensity out of 10.',
          controller: _m3,
        ),
        _RamField(
          label: 'What thought arose just before? Even a single sentence is fine.',
          controller: _m4,
        ),
        _RamField(
          label: 'What would you say to yourself with compassion right now?',
          hint: 'Optional',
          controller: _mCompassion,
        ),
        _RamField(
          label: "What's your immediate next step?",
          hint: 'Optional',
          controller: _mNext,
          last: true,
        ),
      ],
    );
  }

  // ── Completion ────────────────────────────────────────────────────────────

  Widget _buildDoneScaffold() {
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
                    _affirmation,
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

// ── Form field widget ─────────────────────────────────────────────────────────

class _RamField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool autofocus;
  final bool last;

  const _RamField({
    required this.label,
    this.hint,
    required this.controller,
    this.autofocus = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MyWalkColor.warmWhite,
                height: 1.4),
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
