import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Generic multi-prompt session screen used by M1 (daily check-in, weekly
/// review) and M3 (weekly compass).
///
/// Shows one prompt per step with a text field. On completing the last step
/// the combined response is saved as a [RecoverySession] and a rotating
/// affirmation is shown before the screen closes.
class ModuleSessionScreen extends StatefulWidget {
  final String habitId;
  final RecoverySessionType sessionType;
  final int moduleNumber;
  final String title;
  final List<String> prompts;
  final String hint;
  /// Called with the saved session text after saving but before the affirmation.
  /// Awaited — callers can show dialogs (e.g. M2 counter-response prompt) here.
  final Future<void> Function(String responseText)? onSaved;

  const ModuleSessionScreen({
    super.key,
    required this.habitId,
    required this.sessionType,
    required this.moduleNumber,
    required this.title,
    required this.prompts,
    required this.hint,
    this.onSaved,
  });

  @override
  State<ModuleSessionScreen> createState() => _ModuleSessionScreenState();
}

class _ModuleSessionScreenState extends State<ModuleSessionScreen> {
  late final List<TextEditingController> _controllers;
  int _step = 0;
  bool _saving = false;
  bool _done = false;
  late final String _affirmation;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.prompts.length,
      (_) => TextEditingController(),
    );
    for (final c in _controllers) {
      c.addListener(() => setState(() {}));
    }
    _affirmation = RecoveryModuleContent.affirmationForDate(DateTime.now());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canAdvance => _controllers[_step].text.trim().isNotEmpty;

  Future<void> _save() async {
    // Combine all prompt responses.
    final parts = <String>[];
    for (int i = 0; i < widget.prompts.length; i++) {
      parts.add('${widget.prompts[i]}\n${_controllers[i].text.trim()}');
    }
    final combined = parts.join('\n\n');

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final session = RecoverySession(
        id: '${widget.habitId}_${widget.sessionType.value}_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: widget.sessionType,
        moduleNumber: widget.moduleNumber,
        responseText: combined,
        createdAt: now,
      );
      await context.read<RecoveryPathProvider>().saveSession(session);
      if (widget.onSaved != null && mounted) {
        await widget.onSaved!(combined);
      }
      if (mounted) setState(() { _saving = false; _done = true; });
      await Future.delayed(const Duration(milliseconds: 2200));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't save. Check your connection."),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _AffirmationView(text: _affirmation);

    final total = widget.prompts.length;
    final isLast = _step == total - 1;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title,
            style: const TextStyle(
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
      body: Padding(
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
            if (total > 1) ...[
              Row(
                children: List.generate(total, (i) {
                  final active = i == _step;
                  final done = i < _step;
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
            ],

            // Prompt
            Text(
              widget.prompts[_step],
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.warmWhite,
                  height: 1.4),
            ),
            const SizedBox(height: 18),

            // Text field
            Expanded(
              child: TextField(
                controller: _controllers[_step],
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                autofocus: true,
                style: const TextStyle(
                    color: MyWalkColor.warmWhite, fontSize: 15, height: 1.6),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.28),
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

            // Next / Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canAdvance && !_saving
                    ? () {
                        if (isLast) {
                          _save();
                        } else {
                          setState(() => _step++);
                        }
                      }
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
                        isLast ? 'Save reflection' : 'Next',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Affirmation shown after saving ────────────────────────────────────────────

class _AffirmationView extends StatelessWidget {
  final String text;
  const _AffirmationView({required this.text});

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
                text,
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
