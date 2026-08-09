import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'guardrails_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// UNG01 — Urge surfed log. 7-question form capturing a completed urge-surfing session.
class UrgeSurfedLogScreen extends StatefulWidget {
  final String habitId;
  final String habitName;

  const UrgeSurfedLogScreen({
    super.key,
    required this.habitId,
    this.habitName = '',
  });

  @override
  State<UrgeSurfedLogScreen> createState() => _UrgeSurfedLogScreenState();
}

class _UrgeSurfedLogScreenState extends State<UrgeSurfedLogScreen> {
  final _triggerCtrl = TextEditingController();
  final _feelingCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();

  String? _riseAndDecrease;  // 'faded' | 'still_going' | 'not_sure'
  String? _duration;          // '<5' | '5-15' | '15-30' | '30+'
  String? _activatedPlan;    // 'rode_wave' | 'used_plan'
  String? _lookedAtResponses; // 'yes' | 'no'

  bool _saving = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_triggerCtrl, _feelingCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _triggerCtrl.dispose();
    _feelingCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _triggerCtrl.text.trim().isNotEmpty &&
      _feelingCtrl.text.trim().isNotEmpty;

  bool get _hasCounterResponses =>
      (context.read<RecoveryPathProvider>().pathFor(widget.habitId)?.counterResponses.isNotEmpty) ?? false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();
      final payload = <String, dynamic>{
        'trigger': _triggerCtrl.text.trim(),
        'feeling': _feelingCtrl.text.trim(),
        if (_riseAndDecrease != null) 'riseAndDecrease': _riseAndDecrease,
        if (_duration != null) 'duration': _duration,
        if (_activatedPlan != null) 'activatedPlan': _activatedPlan,
        if (_lookedAtResponses != null) 'lookedAtCounterResponses': _lookedAtResponses,
        if (_otherCtrl.text.trim().isNotEmpty) 'otherThoughts': _otherCtrl.text.trim(),
      };
      final session = RecoverySession(
        id: '${widget.habitId}_m4UrgeSurfing_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m4UrgeSurfing,
        moduleNumber: 4,
        responseText: jsonEncode(payload),
        createdAt: now,
      );
      await prov.saveSession(session);
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

  @override
  Widget build(BuildContext context) {
    if (_done) return _buildDone();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Urge surfed',
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UslField(
                          label: 'What was the urge — what triggered it?',
                          controller: _triggerCtrl,
                          autofocus: true,
                        ),
                        const SizedBox(height: 20),
                        _UslField(
                          label: 'How did it feel — in your body and emotionally?',
                          controller: _feelingCtrl,
                        ),
                        const SizedBox(height: 24),
                        _UslChipQuestion(
                          label: 'Did it rise and then decrease?',
                          chips: const [
                            ('faded', 'Yes, it faded'),
                            ('still_going', 'Still going'),
                            ('not_sure', 'Not sure'),
                          ],
                          selected: _riseAndDecrease,
                          onSelected: (v) => setState(() => _riseAndDecrease = v),
                        ),
                        if (_riseAndDecrease == 'still_going') ...[
                          const SizedBox(height: 10),
                          _CopingPlanCallout(
                            habitId: widget.habitId,
                            habitName: widget.habitName,
                          ),
                        ],
                        const SizedBox(height: 24),
                        _UslChipQuestion(
                          label: 'How long did it last approximately?',
                          chips: const [
                            ('<5', 'Less than 5 min'),
                            ('5-15', '5 – 15 min'),
                            ('15-30', '15 – 30 min'),
                            ('30+', 'More than 30 min'),
                          ],
                          selected: _duration,
                          onSelected: (v) => setState(() => _duration = v),
                        ),
                        const SizedBox(height: 24),
                        _UslChipQuestion(
                          label: 'Did you activate your coping plan, or ride the wave out?',
                          chips: const [
                            ('rode_wave', 'Rode the wave'),
                            ('used_plan', 'Used my coping plan'),
                          ],
                          selected: _activatedPlan,
                          onSelected: (v) => setState(() => _activatedPlan = v),
                        ),
                        if (_hasCounterResponses) ...[
                          const SizedBox(height: 24),
                          _UslChipQuestion(
                            label: 'Did you look at your counter-responses?',
                            chips: const [
                              ('yes', 'Yes'),
                              ('no', 'No'),
                            ],
                            selected: _lookedAtResponses,
                            onSelected: (v) =>
                                setState(() => _lookedAtResponses = v),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _UslField(
                          label: 'Any other thoughts?',
                          controller: _otherCtrl,
                          optional: true,
                          last: true,
                        ),
                        const SizedBox(height: 8),
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
                      onPressed: _canSave && !_saving ? _save : null,
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

  Widget _buildDone() {
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
                    'Logged. Every time you ride one out, the urge loses a little of its power.',
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

// ── Coping plan callout ───────────────────────────────────────────────────────

class _CopingPlanCallout extends StatelessWidget {
  final String habitId;
  final String habitName;
  const _CopingPlanCallout({required this.habitId, required this.habitName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined,
              size: 16, color: Colors.orange.withValues(alpha: 0.8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your coping plan is ready when you need it.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.withValues(alpha: 0.9),
                      height: 1.4),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GuardrailsScreen(
                      habitId: habitId,
                      habitName: habitName,
                      initialTab: 1,
                    ),
                  )),
                  child: Text(
                    'Open my coping plan →',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field widget ──────────────────────────────────────────────────────────────

class _UslField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool autofocus;
  final bool optional;
  final bool last;

  const _UslField({
    required this.label,
    required this.controller,
    this.autofocus = false,
    this.optional = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

// ── Chip question widget ──────────────────────────────────────────────────────

class _UslChipQuestion extends StatelessWidget {
  final String label;
  final List<(String, String)> chips; // (value, displayLabel)
  final String? selected;
  final ValueChanged<String> onSelected;

  const _UslChipQuestion({
    required this.label,
    required this.chips,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips.map((chip) {
            final (value, displayLabel) = chip;
            final isSelected = selected == value;
            return GestureDetector(
              onTap: () => onSelected(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _kRpPurple.withValues(alpha: 0.18)
                      : MyWalkColor.surfaceOverlay,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _kRpPurple
                        : MyWalkColor.warmWhite.withValues(alpha: 0.12),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? _kRpPurple
                        : MyWalkColor.warmWhite.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
