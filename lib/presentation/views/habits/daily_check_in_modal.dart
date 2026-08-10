import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'guardrails_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Shows the daily check-in as a modal bottom sheet.
/// Caller is responsible for the trigger logic (dayNumber % 3 == 0 && not done today).
Future<void> showDailyCheckInModal(
  BuildContext context, {
  required String habitId,
  required String habitName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<RecoveryPathProvider>(),
      child: _CheckInSheet(habitId: habitId, habitName: habitName),
    ),
  );
}

// ── Sheet body ────────────────────────────────────────────────────────────────

class _CheckInSheet extends StatefulWidget {
  final String habitId;
  final String habitName;

  const _CheckInSheet({required this.habitId, required this.habitName});

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  int _rating = 5;
  bool _hasMovedSlider = false;
  String? _outcome; // 'slipped' | 'urge_only' | 'clear'

  final _notesController = TextEditingController();
  final _notesFocus = FocusNode();

  bool _saving = false;
  bool _done = false;
  bool _showHighStress = false;
  String _affirmation = '';

  @override
  void initState() {
    super.initState();
    _affirmation = RecoveryModuleContent.affirmationForDate(DateTime.now());
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _save({String notes = ''}) async {
    setState(() => _saving = true);
    try {
      final prov = context.read<RecoveryPathProvider>();
      final now = DateTime.now();
      final payload = <String, dynamic>{
        'rating': _rating,
        'outcome': _outcome,
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
      final session = RecoverySession(
        id: '${widget.habitId}_m1DailyCheckIn_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m1DailyCheckIn,
        moduleNumber: 1,
        responseText: jsonEncode(payload),
        createdAt: now,
      );
      await prov.saveSession(session);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _done = true;
        _showHighStress = _rating <= 3;
      });
      // Auto-dismiss for 'clear' with no high-stress prompt.
      if (_outcome == 'clear' && !_showHighStress) {
        await Future.delayed(const Duration(milliseconds: 2000));
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

  void _selectOutcome(String outcome) {
    setState(() {
      _outcome = outcome;
      _notesController.clear();
    });
    if (outcome == 'clear') {
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding + MediaQuery.of(context).padding.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            const SizedBox(height: 16),
            if (_done) _buildCompletionView() else _buildFormView(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: MyWalkColor.warmWhite.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check in',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 20),

        // Q1 — Emotional slider
        const Text(
          'How are you doing emotionally today?',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 16),
        _buildSlider(),
        const SizedBox(height: 28),

        // Q2 — Outcome (after slider moved)
        if (_hasMovedSlider) ...[
          const Text(
            'Did you encounter your pattern today?',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite,
                height: 1.4),
          ),
          const SizedBox(height: 12),
          _buildOutcomeChips(),
          const SizedBox(height: 16),

          // Inline follow-up for 'slipped'
          if (_outcome == 'slipped') _buildFollowUp(
            callout: 'It\'s important to log these slips so that we can build up a pattern history.',
            hint: 'What happened? (optional)',
          ),

          // Inline follow-up for 'urge_only'
          if (_outcome == 'urge_only') _buildFollowUp(
            callout: 'Let\'s examine the thought that came up. Capture what you were thinking at that moment.',
            hint: 'What came up for you? (optional)',
          ),

          // Saving spinner for 'clear' auto-save
          if (_outcome == 'clear' && _saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2, color: _kRpPurple),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSlider() {
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
            value: _rating.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_rating',
            onChanged: (v) => setState(() {
              _rating = v.round();
              _hasMovedSlider = true;
            }),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _kRpPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_rating / 10',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kRpPurple),
              ),
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

  Widget _buildOutcomeChips() {
    return Column(
      children: [
        _OutcomeChip(
          label: 'Yes, I slipped',
          value: 'slipped',
          selected: _outcome,
          onTap: _selectOutcome,
        ),
        const SizedBox(height: 8),
        _OutcomeChip(
          label: "I felt the urge but didn't act",
          value: 'urge_only',
          selected: _outcome,
          onTap: _selectOutcome,
        ),
        const SizedBox(height: 8),
        _OutcomeChip(
          label: 'Clear day',
          value: 'clear',
          selected: _outcome,
          onTap: _selectOutcome,
        ),
      ],
    );
  }

  Widget _buildFollowUp({required String callout, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kRpPurple.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: _kRpPurple.withValues(alpha: 0.15), width: 0.75),
          ),
          child: Text(
            callout,
            style: TextStyle(
                fontSize: 13,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          focusNode: _notesFocus,
          maxLines: 4,
          minLines: 2,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(fontSize: 14, color: MyWalkColor.warmWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                fontSize: 13,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kRpPurple),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _saving ? null : () => _save(notes: _notesController.text),
              style: TextButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: _saving ? null : () => _save(),
              child: Text(
                'Not now',
                style: TextStyle(
                    fontSize: 13,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.45)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCompletionView() {
    return Column(
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kRpPurple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: _kRpPurple, size: 24),
              ),
              const SizedBox(height: 14),
              const Text(
                'Checked in',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MyWalkColor.warmWhite),
              ),
              const SizedBox(height: 10),
              Text(
                _affirmation,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                    height: 1.6,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        if (_showHighStress) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'It looks like it\'s been a difficult stretch. '
                  'Stressful periods are when the plan matters most. '
                  'Is your coping plan still working?',
                  style: TextStyle(
                      fontSize: 13,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                      height: 1.5),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => GuardrailsScreen(
                        habitId: widget.habitId,
                        habitName: widget.habitName,
                        initialTab: 1,
                      ),
                    ));
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '→ View coping plan',
                    style: TextStyle(color: _kRpPurple, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.4)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Outcome chip ──────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? _kRpPurple.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
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
