import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'behaviour_log_screen.dart';
import 'guardrails_screen.dart';
import 'thought_examination_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Daily emotional check-in for the Freedom Plan (Breaking Habits).
/// Two questions: emotional slider + outcome chip.
class DailyCheckInScreen extends StatefulWidget {
  final String habitId;
  final String habitName;

  const DailyCheckInScreen({
    super.key,
    required this.habitId,
    required this.habitName,
  });

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  int _rating = 5;
  bool _hasMovedSlider = false;
  String? _outcome; // 'slipped' | 'urge_only' | 'clear'
  bool _saving = false;
  bool _done = false;
  bool _showHighStress = false;

  Future<void> _save() async {
    if (_outcome == null) return;
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();
      final session = RecoverySession(
        id: '${widget.habitId}_m1DailyCheckIn_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m1DailyCheckIn,
        moduleNumber: 1,
        responseText: jsonEncode({'rating': _rating, 'outcome': _outcome}),
        createdAt: now,
      );
      await prov.saveSession(session);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _done = true;
        _showHighStress = _rating <= 3;
      });
      // Auto-pop after affirmation delay.
      await Future.delayed(const Duration(milliseconds: 3000));
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

  /// Saves the check-in, shows a brief affirmation, then opens BehaviourLogScreen.
  Future<void> _saveAndExamine() async {
    if (_outcome == null) return;
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();
      final session = RecoverySession(
        id: '${widget.habitId}_m1DailyCheckIn_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m1DailyCheckIn,
        moduleNumber: 1,
        responseText: jsonEncode({'rating': _rating, 'outcome': _outcome}),
        createdAt: now,
      );
      await prov.saveSession(session);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _done = true;
        _showHighStress = _rating <= 3;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ThoughtExaminationScreen(habitId: widget.habitId),
        ),
      );
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

  Future<void> _saveAndLog() async {
    if (_outcome == null) return;
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();
      final session = RecoverySession(
        id: '${widget.habitId}_m1DailyCheckIn_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m1DailyCheckIn,
        moduleNumber: 1,
        responseText: jsonEncode({'rating': _rating, 'outcome': _outcome}),
        createdAt: now,
      );
      await prov.saveSession(session);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _done = true;
        _showHighStress = _rating <= 3;
      });
      // Brief affirmation pause before opening the behaviour log.
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BehaviourLogScreen(habitId: widget.habitId),
        ),
      );
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

  void _selectOutcome(String outcome) {
    setState(() => _outcome = outcome);
    if (outcome == 'clear') {
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _CompletionView(showHighStress: _showHighStress, habitId: widget.habitId, habitName: widget.habitName);

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Daily Check-In',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: BackButton(color: MyWalkColor.warmWhite),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 40 + MediaQuery.of(context).padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Q1 — Emotional slider
                Text(
                  'How are you doing emotionally today?',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: MyWalkColor.warmWhite,
                      height: 1.4),
                ),
                const SizedBox(height: 20),
                _RatingSlider(
                  value: _rating,
                  onChanged: (v) => setState(() {
                    _rating = v;
                    _hasMovedSlider = true;
                  }),
                ),
                const SizedBox(height: 36),

                // Q2 — Outcome (shown after slider moved)
                if (_hasMovedSlider) ...[
                  Text(
                    'Did you encounter your pattern today?',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite,
                        height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  _OutcomeChips(
                    selected: _outcome,
                    onSelected: _selectOutcome,
                  ),
                  const SizedBox(height: 24),

                  // Follow-up block for slipped
                  if (_outcome == 'slipped')
                    _FollowUpBlock(
                      question: 'Do you want to log what happened?',
                      yesLabel: 'Yes, log it',
                      noLabel: 'Not now',
                      saving: _saving,
                      onYes: _saveAndLog,
                      onNo: _save,
                    ),

                  // Follow-up block for urge_only
                  if (_outcome == 'urge_only')
                    _FollowUpBlock(
                      question: 'Do you want to examine the thought that came up?',
                      yesLabel: 'Yes, examine it',
                      noLabel: 'Not now',
                      saving: _saving,
                      onYes: _saveAndExamine,
                      onNo: _save,
                    ),

                  // Saving spinner for 'clear' auto-save
                  if (_outcome == 'clear' && _saving)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kRpPurple),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rating slider ─────────────────────────────────────────────────────────────

class _RatingSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingSlider({required this.value, required this.onChanged});

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
            min: 1,
            max: 10,
            divisions: 9,
            label: '$value',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Not great',
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
            Text('Really well',
                style: TextStyle(
                    fontSize: 11,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.4))),
          ],
        ),
      ],
    );
  }
}

// ── Outcome chips ─────────────────────────────────────────────────────────────

class _OutcomeChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _OutcomeChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OutcomeChip(
          label: 'Yes, I slipped',
          value: 'slipped',
          selected: selected,
          onTap: onSelected,
        ),
        const SizedBox(height: 8),
        _OutcomeChip(
          label: "I felt the urge but didn't act",
          value: 'urge_only',
          selected: selected,
          onTap: onSelected,
        ),
        const SizedBox(height: 8),
        _OutcomeChip(
          label: 'Clear day',
          value: 'clear',
          selected: selected,
          onTap: onSelected,
        ),
      ],
    );
  }
}

class _OutcomeChip extends StatelessWidget {
  final String label;
  final String value;
  final String? selected;
  final ValueChanged<String> onTap;

  const _OutcomeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? _kRpPurple.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _kRpPurple
                : MyWalkColor.warmWhite.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? _kRpPurple
                : MyWalkColor.warmWhite.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

// ── Follow-up block ───────────────────────────────────────────────────────────

class _FollowUpBlock extends StatelessWidget {
  final String question;
  final String yesLabel;
  final String noLabel;
  final bool saving;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _FollowUpBlock({
    required this.question,
    required this.yesLabel,
    required this.noLabel,
    required this.saving,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                  height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: saving ? null : onYes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRpPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(yesLabel,
                          style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onNo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        MyWalkColor.warmWhite.withValues(alpha: 0.6),
                    side: BorderSide(
                        color:
                            MyWalkColor.warmWhite.withValues(alpha: 0.15)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(noLabel,
                      style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Completion / affirmation view ─────────────────────────────────────────────

class _CompletionView extends StatelessWidget {
  final bool showHighStress;
  final String habitId;
  final String habitName;

  const _CompletionView({
    required this.showHighStress,
    required this.habitId,
    required this.habitName,
  });

  @override
  Widget build(BuildContext context) {
    final affirmation =
        RecoveryModuleContent.affirmationForDate(DateTime.now());

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
                  const Text('Checked in',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.warmWhite)),
                  const SizedBox(height: 14),
                  Text(
                    affirmation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                        height: 1.6,
                        fontStyle: FontStyle.italic),
                  ),
                  if (showHighStress) ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: MyWalkColor.warmWhite
                                .withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "It looks like it's been a difficult stretch. "
                            "Stressful periods are when the plan matters most. "
                            "Is your coping plan still working?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: MyWalkColor.warmWhite
                                    .withValues(alpha: 0.7),
                                height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GuardrailsScreen(
                                  habitId: habitId,
                                  habitName: habitName,
                                ),
                              ),
                            ),
                            child: const Text('Review my coping plan →',
                                style: TextStyle(
                                    color: _kRpPurple, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
