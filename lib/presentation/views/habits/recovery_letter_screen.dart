import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Module 5 — Recovery Letter.
/// 4-prompt guided flow → stitched letter preview (editable) → save.
class RecoveryLetterScreen extends StatefulWidget {
  final String habitId;

  const RecoveryLetterScreen({super.key, required this.habitId});

  @override
  State<RecoveryLetterScreen> createState() => _RecoveryLetterScreenState();
}

class _RecoveryLetterScreenState extends State<RecoveryLetterScreen> {
  static final _prompts = RecoveryModuleContent.m5RecoveryLetterPrompts;

  final List<TextEditingController> _controllers =
      List.generate(_prompts.length, (_) => TextEditingController());
  int _step = 0; // 0–3 = prompts; 4 = preview; 5 = done
  late final TextEditingController _previewCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _previewCtrl = TextEditingController();
    for (final c in _controllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _previewCtrl.dispose();
    super.dispose();
  }

  bool get _canAdvance => _controllers[_step].text.trim().isNotEmpty;

  void _buildPreview() {
    final answers = _controllers.map((c) => c.text.trim()).toList();
    _previewCtrl.text =
        RecoveryModuleContent.stitchRecoveryLetter(answers);
    setState(() => _step = 4);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final letter = _previewCtrl.text.trim();
      final prov = context.read<RecoveryPathProvider>();

      // Save the letter draft onto the path.
      await prov.saveRecoveryLetterDraft(widget.habitId, letter);

      // Also save as a session (encrypted).
      final now = DateTime.now();
      final session = RecoverySession(
        id: '${widget.habitId}_m5RecoveryLetter_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m5RecoveryLetter,
        moduleNumber: 5,
        responseText: letter,
        createdAt: now,
      );
      await prov.saveSession(session);

      if (mounted) setState(() { _saving = false; _step = 5; });
      await Future.delayed(const Duration(milliseconds: 2400));
      if (mounted) Navigator.of(context).pop();
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
    if (_step == 5) return _DoneView();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _step == 4
              ? RecoveryModuleContent.m5RecoveryLetterPreviewTitle
              : RecoveryModuleContent.m5RecoveryLetterTitle,
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
      body: _step == 4 ? _PreviewStep(
        controller: _previewCtrl,
        saving: _saving,
        onSave: _save,
      ) : _PromptStep(
        step: _step,
        total: _prompts.length,
        prompt: _prompts[_step],
        controller: _controllers[_step],
        canAdvance: _canAdvance,
        isLast: _step == _prompts.length - 1,
        onNext: () {
          if (_step == _prompts.length - 1) {
            _buildPreview();
          } else {
            setState(() => _step++);
          }
        },
      ),
    );
  }
}

class _PromptStep extends StatelessWidget {
  final int step;
  final int total;
  final String prompt;
  final TextEditingController controller;
  final bool canAdvance;
  final bool isLast;
  final VoidCallback onNext;

  const _PromptStep({
    required this.step,
    required this.total,
    required this.prompt,
    required this.controller,
    required this.canAdvance,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step dots
          Row(
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
          const SizedBox(height: 20),

          // Intro (first step only)
          if (step == 0) ...[
            Text(
              RecoveryModuleContent.m5RecoveryLetterIntro,
              style: TextStyle(
                  fontSize: 13,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                  height: 1.5),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            prompt,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite,
                height: 1.4),
          ),
          const SizedBox(height: 18),

          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              autofocus: true,
              style: const TextStyle(
                  color: MyWalkColor.warmWhite, fontSize: 15, height: 1.6),
              decoration: InputDecoration(
                hintText: 'Write honestly…',
                hintStyle: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.25),
                    fontSize: 14),
                filled: true,
                fillColor: MyWalkColor.surfaceOverlay,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canAdvance ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.25),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isLast ? 'Preview my letter' : 'Next',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewStep extends StatelessWidget {
  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;

  const _PreviewStep({
    required this.controller,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            RecoveryModuleContent.m5RecoveryLetterPreviewBody,
            style: TextStyle(
                fontSize: 13,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                height: 1.5),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                  color: MyWalkColor.warmWhite, fontSize: 14, height: 1.7),
              decoration: InputDecoration(
                filled: true,
                fillColor: MyWalkColor.surfaceOverlay,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.25),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save my letter',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kRpPurple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_outline_rounded,
                    color: _kRpPurple, size: 26),
              ),
              const SizedBox(height: 20),
              const Text('Letter saved',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MyWalkColor.warmWhite)),
              const SizedBox(height: 14),
              Text(
                RecoveryModuleContent.m5LetterSavedMessage,
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
