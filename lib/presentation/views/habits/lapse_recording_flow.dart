import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Full-screen 3-step lapse recording flow.
/// Step 1 — Self-compassion (shows recovery letter or fallback copy)
/// Step 2 — Forensic analysis (3 sub-prompts + structured lapse fields)
/// Step 3 — Re-orientation (top value + journal prompt → save)
class LapseRecordingFlow extends StatefulWidget {
  final String habitId;

  const LapseRecordingFlow({super.key, required this.habitId});

  @override
  State<LapseRecordingFlow> createState() => _LapseRecordingFlowState();
}

class _LapseRecordingFlowState extends State<LapseRecordingFlow> {
  int _step = 0; // 0, 1, 2, or 3 (completion)

  // Step 2 — analysis text
  final TextEditingController _analysisCtrl = TextEditingController();
  // Step 2 — structured fields
  final TextEditingController _timeCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _triggerCtrl = TextEditingController();
  final TextEditingController _emotionCtrl = TextEditingController();

  // Step 3 — re-orientation text
  final TextEditingController _reorientCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _analysisCtrl.dispose();
    _timeCtrl.dispose();
    _locationCtrl.dispose();
    _triggerCtrl.dispose();
    _emotionCtrl.dispose();
    _reorientCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();

      // Combine analysis text with step 3 response.
      final combined =
          'What happened:\n${_analysisCtrl.text.trim()}'
          '\n\nRe-orientation:\n${_reorientCtrl.text.trim()}';

      final lapseData = LapseData(
        time: _timeCtrl.text.trim().isEmpty ? null : _timeCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        trigger: _triggerCtrl.text.trim().isEmpty
            ? null
            : _triggerCtrl.text.trim(),
        emotion: _emotionCtrl.text.trim().isEmpty
            ? null
            : _emotionCtrl.text.trim(),
      );

      final now = DateTime.now();
      final session = RecoverySession(
        id: '${widget.habitId}_lapseRecord_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.lapseRecord,
        moduleNumber: 5,
        responseText: combined,
        createdAt: now,
        lapseData: lapseData,
      );
      await prov.saveSession(session);
      if (mounted) setState(() { _saving = false; _step = 3; });
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
    if (_step == 3) return const _CompletionView();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
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
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress dots
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: List.generate(3, (i) {
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
            child: IndexedStack(
              index: _step,
              children: [
                _Step1(
                  habitId: widget.habitId,
                  onContinue: () => setState(() => _step = 1),
                ),
                _Step2(
                  analysisCtrl: _analysisCtrl,
                  timeCtrl: _timeCtrl,
                  locationCtrl: _locationCtrl,
                  triggerCtrl: _triggerCtrl,
                  emotionCtrl: _emotionCtrl,
                  onContinue: () => setState(() => _step = 2),
                ),
                _Step3(
                  habitId: widget.habitId,
                  reorientCtrl: _reorientCtrl,
                  saving: _saving,
                  onSave: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1 — Self-compassion ──────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final String habitId;
  final VoidCallback onContinue;
  const _Step1({required this.habitId, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Take a breath',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite)),
          const SizedBox(height: 16),

          // Show saved recovery letter if available, else fallback copy.
          _LetterCard(habitId: habitId),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('I\'m ready — let\'s look at what happened',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

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
        border:
            Border.all(color: _kRpPurple.withValues(alpha: 0.2), width: 0.75),
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

// ── Step 2 — Forensic analysis ────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final TextEditingController analysisCtrl;
  final TextEditingController timeCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController triggerCtrl;
  final TextEditingController emotionCtrl;
  final VoidCallback onContinue;

  const _Step2({
    required this.analysisCtrl,
    required this.timeCtrl,
    required this.locationCtrl,
    required this.triggerCtrl,
    required this.emotionCtrl,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            RecoveryModuleContent.lapseStep2Title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite),
          ),
          const SizedBox(height: 8),
          Text(
            RecoveryModuleContent.lapseStep2Body,
            style: TextStyle(
                fontSize: 13,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                height: 1.5),
          ),
          const SizedBox(height: 16),

          // Free-text analysis
          ...RecoveryModuleContent.lapseStep2SubPrompts.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $p',
                    style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.6))),
              )),
          const SizedBox(height: 8),
          TextField(
            controller: analysisCtrl,
            maxLines: 5,
            minLines: 3,
            style: const TextStyle(
                color: MyWalkColor.warmWhite, fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Write freely — no judgement here.',
              hintStyle: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.25),
                  fontSize: 13),
              filled: true,
              fillColor: MyWalkColor.surfaceOverlay,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Structured fields
          Text('Quick capture',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          _MiniField(label: 'Time (approx.)', controller: timeCtrl),
          _MiniField(label: 'Where were you?', controller: locationCtrl),
          _MiniField(label: 'What triggered it?', controller: triggerCtrl),
          _MiniField(label: 'Emotional state before', controller: emotionCtrl),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _MiniField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
              fontSize: 12),
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
    );
  }
}

// ── Step 3 — Re-orientation ───────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final String habitId;
  final TextEditingController reorientCtrl;
  final bool saving;
  final VoidCallback onSave;

  const _Step3({
    required this.habitId,
    required this.reorientCtrl,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecoveryPathProvider>();
    final path = prov.pathFor(habitId);

    // Show top value gap (highest importance - alignment) if M3 is done.
    String? topValueName;
    if (path != null && path.module3.valuesInventoryDone) {
      final inventory = path.module3.valuesInventory;
      if (inventory.isNotEmpty) {
        final top = inventory.reduce(
          (a, b) => a.gap >= b.gap ? a : b,
        );
        if (top.gap > 0) topValueName = top.domain;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Back on the path',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite)),
          const SizedBox(height: 12),

          if (topValueName != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MyWalkColor.sage.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.anchor_rounded,
                    size: 14, color: MyWalkColor.sage),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${RecoveryModuleContent.lapseStep3ValuePrefix}$topValueName',
                    style: const TextStyle(
                        fontSize: 13, color: MyWalkColor.warmWhite),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
          ],

          Text(
            RecoveryModuleContent.lapseStep3Prompt,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite,
                height: 1.4),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: reorientCtrl,
            maxLines: 5,
            minLines: 3,
            autofocus: true,
            style: const TextStyle(
                color: MyWalkColor.warmWhite, fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: 'One specific thing…',
              hintStyle: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.25),
                  fontSize: 13),
              filled: true,
              fillColor: MyWalkColor.surfaceOverlay,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save and get back up',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
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
      body: Center(
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
              const Text('You did it',
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
                    height: 1.5,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
