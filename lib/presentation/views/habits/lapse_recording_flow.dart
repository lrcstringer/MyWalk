import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'guardrails_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// ONG01-B — 4-screen "I acted on it" lapse flow.
///
/// B1 (step 0) — Stop the Spiral   [full immersive, no AppBar, badge "1 of 4"]
/// B2 (step 1) — Your Letter       [letter card + compassion, AppBar "Your letter"]
/// B3 (step 2) — Forensic          [4 fields, AppBar "What happened"]
/// B4 (step 3) — Recommit          [2 fields, AppBar "Going forward"]
/// Completion (step 4)
class LapseRecordingFlow extends StatefulWidget {
  final String habitId;

  const LapseRecordingFlow({super.key, required this.habitId});

  @override
  State<LapseRecordingFlow> createState() => _LapseRecordingFlowState();
}

class _LapseRecordingFlowState extends State<LapseRecordingFlow> {
  int _step = 0;
  bool _letterRead = false; // B3 Variant A: reveals compassion field

  // B3 — Forensic (first 3 required, thought optional)
  final _situationCtrl = TextEditingController();
  final _emotionCtrl = TextEditingController();
  final _thoughtCtrl = TextEditingController();
  final _forensicGapCtrl = TextEditingController();

  // B2 — Self-compassion (required)
  final _selfCompassionCtrl = TextEditingController();

  // B5 — Recommit (both required)
  final _copingPlanGapCtrl = TextEditingController();
  final _recommittedValueCtrl = TextEditingController();
  bool _copingPlanUpdated = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _situationCtrl,
      _emotionCtrl,
      _forensicGapCtrl,
      _selfCompassionCtrl,
      _copingPlanGapCtrl,
      _recommittedValueCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _situationCtrl.dispose();
    _emotionCtrl.dispose();
    _thoughtCtrl.dispose();
    _forensicGapCtrl.dispose();
    _selfCompassionCtrl.dispose();
    _copingPlanGapCtrl.dispose();
    _recommittedValueCtrl.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return true;
      case 1:
        return _selfCompassionCtrl.text.trim().isNotEmpty;
      case 2:
        return _situationCtrl.text.trim().isNotEmpty &&
            _emotionCtrl.text.trim().isNotEmpty &&
            _forensicGapCtrl.text.trim().isNotEmpty;
      case 3:
        return _copingPlanGapCtrl.text.trim().isNotEmpty &&
            _recommittedValueCtrl.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();
      final payload = jsonEncode({
        'branch': 'acted',
        'situation': _situationCtrl.text.trim(),
        'emotionalState': _emotionCtrl.text.trim(),
        if (_thoughtCtrl.text.trim().isNotEmpty)
          'thoughtArose': _thoughtCtrl.text.trim(),
        'forensicGap': _forensicGapCtrl.text.trim(),
        'selfCompassion': _selfCompassionCtrl.text.trim(),
        'copingPlanGap': _copingPlanGapCtrl.text.trim(),
        'recommittedValue': _recommittedValueCtrl.text.trim(),
        'copingPlanUpdated': _copingPlanUpdated,
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
        responseText: payload,
        createdAt: now,
        lapseData: lapseData,
      );
      await prov.saveSession(session);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ram_lapse_flag_${widget.habitId}');
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

  String get _appBarTitle {
    switch (_step) {
      case 1: return 'Your letter';
      case 2: return 'What happened';
      case 3: return 'Going forward';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 4) return const _CompletionView();
    if (_step == 0) return _buildB1();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _appBarTitle,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StepBadge(label: '${_step + 1} of 4'),
                  ),
                ),
                Expanded(child: _buildCurrentStep()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1: return _buildB3(); // letter + compassion
      case 2: return _buildB4(); // forensic (4 fields)
      case 3: return _buildB5(); // recommit
      default: return const SizedBox.shrink();
    }
  }



  // ── B1 — Stop the Spiral (full immersive, no AppBar) ─────────────────────

  Widget _buildB1() {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _StepBadge(label: '1 of 4'),
                  ),
                  const Spacer(),
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
                  const Spacer(),
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
                      child: const Text("I'm ready to continue",
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

  // ── B3 — Your Letter + Self-Compassion ───────────────────────────────────

  Widget _buildB3() {
    final letterRaw = context
        .watch<RecoveryPathProvider>()
        .pathFor(widget.habitId)
        ?.recoveryLetterDraft;
    final hasLetter = letterRaw != null && letterRaw.trim().isNotEmpty;
    final letter = letterRaw ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLetter) ...[
            // Variant A — letter written
            Text(
              'Your recovery letter',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kRpPurple.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 8),
            _LetterCard(text: letter, isLetter: true),
            const SizedBox(height: 14),
            Text(
              'Read it. Take whatever time you need.',
              style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                  height: 1.5),
            ),
            const SizedBox(height: 16),
            if (!_letterRead)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _letterRead = true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kRpPurple,
                    side: const BorderSide(color: _kRpPurple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("I've read it",
                      style: TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                ),
              ),
          ] else ...[
            // Variant B — no letter written yet
            _LetterCard(
              text:
                  "You haven't written your recovery letter yet. That's okay — you'll get to it.\n\n"
                  "For now, read this carefully: A slip is not a verdict. People who successfully change "
                  "long-established patterns almost always experience setbacks — the research on this is "
                  "consistent and clear. What matters is not that a slip happened. What matters is what "
                  "you do in the next hour.\n\n"
                  "The most dangerous thing right now is if your mind turns this into a story about who "
                  "you are. 'I have no willpower.' 'I'll never change.' 'I might as well give up.' These "
                  "thoughts are not facts. They are the all-or-nothing thinking error — and recognising "
                  "them as thoughts, not truths, is your first right move.\n\n"
                  "You came back here. That already matters.",
              isLetter: false,
            ),
          ],
          if (hasLetter && !_letterRead) const SizedBox.shrink()
          else ...[
            const SizedBox(height: 24),
            const Text(
              'What would you say to a good friend who had just gone through exactly this moment?',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.warmWhite,
                  height: 1.4),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _selfCompassionCtrl,
              minLines: 4,
              maxLines: null,
              autofocus: !hasLetter,
              style: const TextStyle(
                  color: MyWalkColor.warmWhite, fontSize: 14, height: 1.6),
              decoration: InputDecoration(
                hintText: 'Write here…',
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
                onPressed:
                    _canAdvance ? () => setState(() => _step = 2) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRpPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── B4 — Forensic (4 fields) ─────────────────────────────────────────────

  Widget _buildB4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Let's understand what happened — not to judge it, but to learn from it.",
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.35),
          ),
          const SizedBox(height: 20),
          _RamField(
            label: 'What was the situation just before? Where were you, what were you doing?',
            controller: _situationCtrl,
            autofocus: true,
          ),
          _RamField(
            label: 'What were you feeling emotionally?',
            controller: _emotionCtrl,
          ),
          _RamField(
            label: 'What thought arose just before?',
            controller: _thoughtCtrl,
            optional: true,
          ),
          _RamField(
            label: 'Where did your coping plan not hold — and what do you think got in the way?',
            controller: _forensicGapCtrl,
            last: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canAdvance ? () => setState(() => _step = 3) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // ── B5 — Recommit (2 required fields) ────────────────────────────────────

  Widget _buildB5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What does this moment teach you about your coping plan that you didn't know before? What would need to be different next time?",
            style: TextStyle(
                fontSize: 14,
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
              hintText: 'Write here…',
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
          const Text(
            'Which of your values do you want to take the next right step toward — right now, today?',
            style: TextStyle(
                fontSize: 14,
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
          const SizedBox(height: 20),
          TextButton(
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
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Update my coping plan →',
              style: TextStyle(
                  color: _kRpPurple.withValues(alpha: 0.8), fontSize: 13),
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
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save and update my plan',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

}

// ── Shared field widgets ──────────────────────────────────────────────────────

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

// ── Letter card ───────────────────────────────────────────────────────────────

class _LetterCard extends StatelessWidget {
  final String text;
  final bool isLetter;

  const _LetterCard({required this.text, required this.isLetter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLetter
            ? _kRpPurple.withValues(alpha: 0.07)
            : const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLetter
              ? _kRpPurple.withValues(alpha: 0.2)
              : const Color(0xFFF59E0B).withValues(alpha: 0.25),
          width: 0.75,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 14,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
            height: 1.6,
            fontStyle: isLetter ? FontStyle.italic : FontStyle.normal),
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
    Future.delayed(const Duration(milliseconds: 3200), () {
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
                  Text(
                    "You didn't give up. You came back. That is what recovery actually looks like — not a straight line, but coming back every time. Your plan is updated. Your values are still yours. Keep going.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                        height: 1.65),
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
