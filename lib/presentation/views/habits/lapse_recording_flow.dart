import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'guardrails_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Full-screen 5-step lapse recording flow.
/// Screen 0 — Stop the spiral (no fields, message only)
/// Screen 1 — Recovery letter + self-compassion text field
/// Screen 2 — Forensic analysis (4 mini fields)
/// Screen 3 — Extract and recommit (2 required text fields + coping plan link)
/// Screen 4 — Completion (auto-pop)
class LapseRecordingFlow extends StatefulWidget {
  final String habitId;

  const LapseRecordingFlow({super.key, required this.habitId});

  @override
  State<LapseRecordingFlow> createState() => _LapseRecordingFlowState();
}

class _LapseRecordingFlowState extends State<LapseRecordingFlow> {
  int _step = 0;

  // Screen 1 — self-compassion
  final TextEditingController _selfCompassionCtrl = TextEditingController();

  // Screen 2 — forensic analysis (4 mini fields)
  final TextEditingController _situationCtrl = TextEditingController();
  final TextEditingController _emotionCtrl = TextEditingController();
  final TextEditingController _thoughtCtrl = TextEditingController();
  final TextEditingController _copingGapCtrl = TextEditingController();

  // Screen 3 — extract and recommit
  final TextEditingController _copingPlanGapCtrl = TextEditingController();
  final TextEditingController _recommittedValueCtrl = TextEditingController();
  bool _copingPlanUpdated = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _selfCompassionCtrl,
      _copingPlanGapCtrl,
      _recommittedValueCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _selfCompassionCtrl.dispose();
    _situationCtrl.dispose();
    _emotionCtrl.dispose();
    _thoughtCtrl.dispose();
    _copingGapCtrl.dispose();
    _copingPlanGapCtrl.dispose();
    _recommittedValueCtrl.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_step) {
      case 0: return true;
      case 1: return _selfCompassionCtrl.text.trim().isNotEmpty;
      case 2: return true; // mini fields not strictly required
      case 3:
        return _copingPlanGapCtrl.text.trim().isNotEmpty &&
            _recommittedValueCtrl.text.trim().isNotEmpty;
      default: return false;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();

      final responseJson = jsonEncode({
        'selfCompassion': _selfCompassionCtrl.text.trim(),
        'situation': _situationCtrl.text.trim(),
        'emotion': _emotionCtrl.text.trim(),
        'thought': _thoughtCtrl.text.trim(),
        'situationalCopingGap': _copingGapCtrl.text.trim(),
        'copingPlanGap': _copingPlanGapCtrl.text.trim(),
        'recommittedValue': _recommittedValueCtrl.text.trim(),
      });

      final lapseData = LapseData(
        selfCompassionText: _selfCompassionCtrl.text.trim(),
        copingPlanGapText: _copingPlanGapCtrl.text.trim(),
        recommittedValue: _recommittedValueCtrl.text.trim(),
        copingPlanUpdated: _copingPlanUpdated,
      );

      final session = RecoverySession(
        id: '${widget.habitId}_m5LapseResponse_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m5LapseResponse,
        moduleNumber: 5,
        responseText: responseJson,
        createdAt: now,
        lapseData: lapseData,
      );
      await prov.saveSession(session);

      if (mounted) setState(() { _saving = false; _step = 4; });
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
    if (_step == 4) return const _CompletionView();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          RecoveryModuleContent.lapseFlowAppBarTitle,
          style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
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
                // Progress dots (4 dots, steps 0–3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    children: List.generate(4, (i) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: i == _step ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? _kRpPurple
                              : _kRpPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: _buildCurrentStep(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_step) {
      case 0: return _buildScreen0();
      case 1: return _buildScreen1(context);
      case 2: return _buildScreen2();
      case 3: return _buildScreen3(context);
      default: return const SizedBox.shrink();
    }
  }

  // ── Screen 0 — Stop the spiral ────────────────────────────────────────────

  Widget _buildScreen0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            'First — stop.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.2),
          ),
          const SizedBox(height: 28),
          Text(
            'Whatever your mind is telling you right now about what this means, '
            'about who you are, about whether change is possible — those thoughts are not facts.\n\n'
            'One moment is one moment. It is not a verdict.\n\n'
            'Take a breath. You\'re still here. That matters.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                height: 1.75),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('I\'m ready to continue',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Screen 1 — Recovery letter + self-compassion ──────────────────────────

  Widget _buildScreen1(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LetterCard(habitId: widget.habitId),
          const SizedBox(height: 24),
          const Text(
            'What would you say to a good friend who had just gone through exactly this moment?',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite,
                height: 1.4),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _selfCompassionCtrl,
            minLines: 4,
            maxLines: null,
            style: const TextStyle(
                color: MyWalkColor.warmWhite, fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText: 'Write as if your most compassionate self is speaking.',
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canAdvance ? () => setState(() => _step = 2) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('I\'ve read it — continue',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Screen 2 — Forensic analysis ──────────────────────────────────────────

  Widget _buildScreen2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Let\'s understand what happened — not to judge it, but to learn from it.',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.3),
          ),
          const SizedBox(height: 20),
          _MiniField(
              label: 'What was the situation just before? Where were you, what were you doing?',
              controller: _situationCtrl),
          _MiniField(
              label: 'What were you feeling emotionally?',
              controller: _emotionCtrl),
          _MiniField(
              label: 'What thought arose just before?',
              controller: _thoughtCtrl),
          _MiniField(
              label: 'Where did your coping plan not hold — and what do you think got in the way?',
              controller: _copingGapCtrl),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 3),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Screen 3 — Extract and recommit ───────────────────────────────────────

  Widget _buildScreen3(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            RecoveryModuleContent.lapseStep3Title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.3),
          ),
          const SizedBox(height: 20),

          // Question A
          const Text(
            'What does this moment teach you about your coping plan that you didn\'t know before? What would need to be different next time?',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite,
                height: 1.4),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _copingPlanGapCtrl,
            minLines: 3,
            maxLines: null,
            autofocus: true,
            style: const TextStyle(
                color: MyWalkColor.warmWhite, fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText: 'Be specific about what would change.',
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
          const SizedBox(height: 20),

          // Question B
          const Text(
            'Which of your values do you want to take the next right step toward — right now, today?',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite,
                height: 1.4),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _recommittedValueCtrl,
            minLines: 2,
            maxLines: null,
            style: const TextStyle(
                color: MyWalkColor.warmWhite, fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText: 'e.g. My family. My faith. My health.',
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
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canAdvance && !_saving ? _save : null,
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
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save and update my plan',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() => _copingPlanUpdated = true);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GuardrailsScreen(
                    habitId: widget.habitId,
                    habitName: '',
                    initialTab: 1,
                  ),
                ));
              },
              child: Text(
                'Update my coping plan →',
                style: TextStyle(
                    color: _kRpPurple.withValues(alpha: 0.7), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Letter card ───────────────────────────────────────────────────────────────

class _LetterCard extends StatelessWidget {
  final String habitId;
  const _LetterCard({required this.habitId});

  @override
  Widget build(BuildContext context) {
    final letter = context
        .watch<RecoveryPathProvider>()
        .pathFor(habitId)
        ?.recoveryLetterDraft;

    final text = (letter != null && letter.trim().isNotEmpty)
        ? letter.trim()
        : RecoveryModuleContent.lapseFallbackLetter;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kRpPurple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _kRpPurple.withValues(alpha: 0.2), width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (letter != null && letter.trim().isNotEmpty) ...[
            Row(children: [
              const Icon(Icons.mail_outline_rounded,
                  size: 12, color: _kRpPurple),
              const SizedBox(width: 6),
              Text('Your recovery letter',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kRpPurple.withValues(alpha: 0.8))),
            ]),
            const SizedBox(height: 10),
          ],
          Text(
            text,
            style: TextStyle(
                fontSize: 14,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                height: 1.6,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ── Mini field ────────────────────────────────────────────────────────────────

class _MiniField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _MiniField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.75))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: null,
            style: const TextStyle(
                color: MyWalkColor.warmWhite, fontSize: 13, height: 1.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: MyWalkColor.surfaceOverlay,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion ────────────────────────────────────────────────────────────────

class _CompletionView extends StatefulWidget {
  const _CompletionView();

  @override
  State<_CompletionView> createState() => _CompletionViewState();
}

class _CompletionViewState extends State<_CompletionView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _kRpPurple.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: _kRpPurple, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('You came back.',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.warmWhite)),
                  const SizedBox(height: 14),
                  Text(
                    RecoveryModuleContent.lapseCompletionMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                        height: 1.55),
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
