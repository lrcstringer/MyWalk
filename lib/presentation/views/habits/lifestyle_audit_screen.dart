import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Module 4 — Monthly Balance Check.
/// 2-step flow (step 0 has two fields; step 1 has one).
/// Surfaces when dayNumber >= 30 and lastLifestyleAuditAt was > 30 days ago.
class LifestyleAuditScreen extends StatefulWidget {
  final String habitId;
  const LifestyleAuditScreen({super.key, required this.habitId});

  @override
  State<LifestyleAuditScreen> createState() => _LifestyleAuditScreenState();
}

class _LifestyleAuditScreenState extends State<LifestyleAuditScreen> {
  int _step = 0;
  bool _saving = false;
  bool _done = false;

  // Step 0 — two fields
  final TextEditingController _takingCtrl = TextEditingController();
  final TextEditingController _nourishingCtrl = TextEditingController();

  // Step 1 — one field
  final TextEditingController _activitiesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [_takingCtrl, _nourishingCtrl, _activitiesCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _takingCtrl.dispose();
    _nourishingCtrl.dispose();
    _activitiesCtrl.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    if (_step == 0) {
      return _takingCtrl.text.trim().isNotEmpty &&
          _nourishingCtrl.text.trim().isNotEmpty;
    }
    return _activitiesCtrl.text.trim().isNotEmpty;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final responseJson = jsonEncode({
        'taking': _takingCtrl.text.trim(),
        'nourishing': _nourishingCtrl.text.trim(),
        'activities': _activitiesCtrl.text.trim(),
      });
      await context
          .read<RecoveryPathProvider>()
          .saveLifestyleAudit(widget.habitId, responseJson);
      if (mounted) {
        setState(() { _saving = false; _done = true; });
        await Future.delayed(const Duration(milliseconds: 2200));
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
    if (_done) return _AuditDoneView();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Monthly Balance Check',
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
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(top: false,
            child: Column(
              children: [
                // Step dots
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: List.generate(2, (i) {
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
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: _step == 0 ? _buildStep0() : _buildStep1(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canAdvance && !_saving
                          ? (_step == 0
                              ? () => setState(() => _step = 1)
                              : _save)
                          : null,
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
                          : Text(
                              _step == 0 ? 'Next' : 'Save',
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

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kRpPurple.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kRpPurple.withValues(alpha: 0.15)),
          ),
          child: Text(
            'This isn\'t about optimising your schedule. It\'s about making sure your life '
            'has enough real goodness in it that this habit doesn\'t feel like the only '
            'available relief.',
            style: TextStyle(
                fontSize: 13,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                height: 1.55),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Looking at your typical week honestly — what is taking from you?',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _takingCtrl,
          minLines: 3,
          maxLines: null,
          autofocus: true,
          style: const TextStyle(
              color: MyWalkColor.warmWhite, fontSize: 14, height: 1.6),
          decoration: InputDecoration(
            hintText:
                'e.g. Long commute, difficult relationships, too much screen time',
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
          'What is genuinely nourishing you — not numbing, not obligation, but something you\'d actually choose?',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nourishingCtrl,
          minLines: 3,
          maxLines: null,
          style: const TextStyle(
              color: MyWalkColor.warmWhite, fontSize: 14, height: 1.6),
          decoration: InputDecoration(
            hintText:
                'e.g. Morning walks, time with certain people, creative work',
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

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What two activities could you build into the next month that would genuinely nourish you?',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'Be specific. "Exercise" is a category — "30-min walk on Tuesday evenings" is a plan.',
          style: TextStyle(
              fontSize: 13,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
              height: 1.5,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _activitiesCtrl,
          minLines: 4,
          maxLines: null,
          autofocus: true,
          style: const TextStyle(
              color: MyWalkColor.warmWhite, fontSize: 14, height: 1.6),
          decoration: InputDecoration(
            hintText: 'Two specific activities…',
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
}

// ── Done view ─────────────────────────────────────────────────────────────────

class _AuditDoneView extends StatelessWidget {
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
                    child: const Icon(Icons.balance_rounded,
                        color: _kRpPurple, size: 26),
                  ),
                  const SizedBox(height: 20),
                  const Text('Balance check done.',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.warmWhite)),
                  const SizedBox(height: 14),
                  Text(
                    'Good. A life with genuine nourishment in it makes the pattern less necessary.',
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
