import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);
const _kSteps = 4;

/// 4-step behaviour log for the Freedom Plan.
/// Records: location/time → activity before → emotion + intensity → thought.
/// Draft persists to SharedPreferences keyed '{habitId}_behaviourLogDraft'.
class BehaviourLogScreen extends StatefulWidget {
  final String habitId;

  const BehaviourLogScreen({super.key, required this.habitId});

  @override
  State<BehaviourLogScreen> createState() => _BehaviourLogScreenState();
}

class _BehaviourLogScreenState extends State<BehaviourLogScreen> {
  int _step = 0;
  bool _saving = false;
  bool _done = false;

  final _locationCtrl = TextEditingController();
  final _activityCtrl = TextEditingController();
  final _emotionCtrl = TextEditingController();
  int _emotionRating = 5;
  final _thoughtCtrl = TextEditingController();

  String get _draftKey => '${widget.habitId}_behaviourLogDraft';

  @override
  void initState() {
    super.initState();
    // Rebuild when text changes so Next button enables.
    _locationCtrl.addListener(() => setState(() {}));
    _activityCtrl.addListener(() => setState(() {}));
    _emotionCtrl.addListener(() => setState(() {}));
    _thoughtCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraft());
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _activityCtrl.dispose();
    _emotionCtrl.dispose();
    _thoughtCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || !mounted) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _step = (data['step'] as int? ?? 0).clamp(0, _kSteps - 1);
        _locationCtrl.text = data['locationTime'] as String? ?? '';
        _activityCtrl.text = data['activityBefore'] as String? ?? '';
        _emotionCtrl.text = data['emotionName'] as String? ?? '';
        _emotionRating = (data['emotionRating'] as int? ?? 5).clamp(0, 10);
        _thoughtCtrl.text = data['thoughtArose'] as String? ?? '';
      });
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _draftKey,
      jsonEncode({
        'step': _step,
        'locationTime': _locationCtrl.text,
        'activityBefore': _activityCtrl.text,
        'emotionName': _emotionCtrl.text,
        'emotionRating': _emotionRating,
        'thoughtArose': _thoughtCtrl.text,
      }),
    );
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _locationCtrl.text.trim().isNotEmpty;
      case 1:
        return _activityCtrl.text.trim().isNotEmpty;
      case 2:
        return _emotionCtrl.text.trim().isNotEmpty;
      case 3:
        return _thoughtCtrl.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _advance() {
    if (!_canAdvance) return;
    _saveDraft(); // fire-and-forget
    setState(() => _step++);
  }

  Future<void> _save() async {
    if (!_canAdvance) return;
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();
      final responseText = jsonEncode({
        'locationTime': _locationCtrl.text.trim(),
        'activityBefore': _activityCtrl.text.trim(),
        'emotionName': _emotionCtrl.text.trim(),
        'emotionRating': _emotionRating,
        'thoughtArose': _thoughtCtrl.text.trim(),
      });
      final session = RecoverySession(
        id: '${widget.habitId}_m1BehaviourLog_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m1BehaviourLog,
        moduleNumber: 1,
        responseText: responseText,
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
    if (_done) return const _BehaviourLogAffirmation();

    final isLast = _step == _kSteps - 1;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Log a moment',
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
          const Positioned.fill(child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step dots
                  Row(
                    children: List.generate(_kSteps, (i) {
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
                    _stepPrompt(_step),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite,
                        height: 1.4),
                  ),
                  const SizedBox(height: 18),

                  // Step content
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildStepContent(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Next / Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canAdvance && !_saving
                          ? (isLast ? _save : _advance)
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
                              isLast ? 'Save log' : 'Next',
                              style: const TextStyle(
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

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _StepTextField(
          controller: _locationCtrl,
          hint: 'e.g. Home alone, 11pm / Office, after a difficult meeting',
          autofocus: true,
        );
      case 1:
        return _StepTextField(
          controller: _activityCtrl,
          hint: "e.g. Browsing my phone / Just got home from work / Couldn't sleep",
          autofocus: true,
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepTextField(
              controller: _emotionCtrl,
              hint: 'e.g. lonely, anxious, bored, overwhelmed',
              autofocus: true,
              minLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'How intense was it?',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12),
            _IntensitySlider(
              value: _emotionRating,
              onChanged: (v) => setState(() => _emotionRating = v),
            ),
          ],
        );
      case 3:
        return _StepTextField(
          controller: _thoughtCtrl,
          hint: '"I deserve this." / "Just for a minute." / "No one will know."',
          autofocus: true,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  static String _stepPrompt(int step) {
    switch (step) {
      case 0:
        return 'Where were you? What time of day was it?';
      case 1:
        return 'What were you doing immediately before?';
      case 2:
        return 'What were you feeling emotionally?';
      case 3:
        return 'What thought arose just before? Even a single sentence is fine.';
      default:
        return '';
    }
  }
}

// ── Step text field ───────────────────────────────────────────────────────────

class _StepTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final int minLines;

  const _StepTextField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.minLines = 5,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      autofocus: autofocus,
      style: const TextStyle(
          color: MyWalkColor.warmWhite, fontSize: 15, height: 1.6),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.28), fontSize: 14),
        filled: true,
        fillColor: MyWalkColor.surfaceOverlay,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

// ── Intensity slider (Step 3) ─────────────────────────────────────────────────

class _IntensitySlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _IntensitySlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _kRpPurple,
            inactiveTrackColor: _kRpPurple.withValues(alpha: 0.15),
            thumbColor: _kRpPurple,
            overlayColor: _kRpPurple.withValues(alpha: 0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$value',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mild',
                style: TextStyle(
                    fontSize: 11,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.4))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _kRpPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$value / 10',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kRpPurple)),
            ),
            Text('Overwhelming',
                style: TextStyle(
                    fontSize: 11,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.4))),
          ],
        ),
      ],
    );
  }
}

// ── Completion affirmation ────────────────────────────────────────────────────

class _BehaviourLogAffirmation extends StatelessWidget {
  const _BehaviourLogAffirmation();

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
                    child: const Icon(Icons.edit_note_rounded,
                        color: _kRpPurple, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('Logged',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.warmWhite)),
                  const SizedBox(height: 14),
                  Text(
                    'Every honest record brings you closer to understanding your pattern.',
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
