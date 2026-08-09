import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Module 3 — Weekly Values Compass.
/// Three heterogeneous steps:
///   0 — Domain Toward/Away chips (one per values inventory entry)
///   1 — Conditional free text (required only when any domain points away)
///   2 — Committed action (always required)
class WeeklyCompassScreen extends StatefulWidget {
  final String habitId;
  const WeeklyCompassScreen({super.key, required this.habitId});

  @override
  State<WeeklyCompassScreen> createState() => _WeeklyCompassScreenState();
}

class _WeeklyCompassScreenState extends State<WeeklyCompassScreen> {
  int _step = 0;
  bool _done = false;
  bool _saving = false;

  late final List<ValuesInventoryEntry> _inventory;

  // Step 0 — domain toward/away
  late final Map<String, String> _domainSelections; // domain → 'toward'|'away'

  // Step 1 — merged commitment question (conditional wording based on away/toward)
  late final TextEditingController _step1Ctrl;
  bool _allToward = false;

  @override
  void initState() {
    super.initState();
    final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    _inventory = path?.module3.valuesInventory ?? [];
    _domainSelections = {};
    _step1Ctrl = TextEditingController()..addListener(() => setState(() {}));

    // If no inventory, skip domain step
    if (_inventory.isEmpty) _step = 1;
  }

  @override
  void dispose() {
    _step1Ctrl.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _inventory.every((e) => _domainSelections.containsKey(e.domain));
      case 1:
        return _step1Ctrl.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _advance() {
    if (_step == 0) {
      _allToward = _domainSelections.values.every((v) => v == 'toward');
    }
    setState(() => _step++);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final responseJson = jsonEncode({
        'domainDirections': _domainSelections,
        'committedAction': _step1Ctrl.text.trim(),
      });
      final session = RecoverySession(
        id: '${widget.habitId}_m3WeeklyCompass_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m3WeeklyCompass,
        moduleNumber: 3,
        responseText: responseJson,
        createdAt: now,
      );
      await context.read<RecoveryPathProvider>().saveSession(session);
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

  void _onBack() {
    final firstStep = _inventory.isEmpty ? 1 : 0;
    if (_step > firstStep) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _CompassAffirmationView(allToward: _allToward);

    final totalSteps = _inventory.isEmpty ? 1 : 2;
    final displayStep = _inventory.isEmpty ? 0 : _step;
    final isLast = _step == 1;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(RecoveryModuleContent.m3CompassTitle,
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: List.generate(totalSteps, (i) {
                      final active = i == displayStep;
                      final done = i < displayStep;
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
                    child: _buildCurrentStep(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20,
                      MediaQuery.of(context).viewInsets.bottom + 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canAdvance && !_saving
                          ? (isLast ? _save : _advance)
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
                              isLast ? 'Save compass check-in' : 'Next',
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

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0 — Domain Toward/Away ────────────────────────────────────────────

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'For each of your values, did this week\'s actions move toward or away from it?',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 6),
        Text(
          RecoveryModuleContent.m3CompassHint,
          style: TextStyle(
              fontSize: 13,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
              height: 1.4),
        ),
        const SizedBox(height: 20),
        ..._inventory.map((entry) => _DomainRow(
              domain: entry.domain,
              selected: _domainSelections[entry.domain],
              onSelect: (direction) =>
                  setState(() => _domainSelections[entry.domain] = direction),
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Step 1 — Merged commitment question (conditional wording) ─────────────

  Widget _buildStep1() {
    final awayDomains = _domainSelections.entries
        .where((e) => e.value == 'away')
        .map((e) => e.key)
        .toList();

    final hasAway = awayDomains.isNotEmpty;
    final question = hasAway
        ? 'What\'s one concrete thing you\'ll do differently this week — something specific, not a mindset?'
        : 'What\'s one concrete thing you\'ll do this week that moves toward what matters most to you?';
    final hint = hasAway
        ? 'Focus on the area where your compass is pointing away.'
        : 'A "do" action — something concrete you can actually do.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_allToward && _inventory.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MyWalkColor.sage.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: MyWalkColor.sage.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: MyWalkColor.sage),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nothing pointing away this week — that\'s worth noticing.',
                    style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (hasAway) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: awayDomains
                .map((d) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MyWalkColor.warmCoral.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                MyWalkColor.warmCoral.withValues(alpha: 0.25)),
                      ),
                      child: Text(d,
                          style: TextStyle(
                              fontSize: 11,
                              color: MyWalkColor.warmWhite
                                  .withValues(alpha: 0.65))),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          question,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
              height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          style: TextStyle(
              fontSize: 13,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
              height: 1.5,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _step1Ctrl,
          minLines: 3,
          maxLines: null,
          autofocus: true,
          style: const TextStyle(
              color: MyWalkColor.warmWhite, fontSize: 14, height: 1.6),
          decoration: InputDecoration(
            hintText: 'A concrete, specific action.',
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

// ── Domain Toward/Away row ────────────────────────────────────────────────────

class _DomainRow extends StatelessWidget {
  final String domain;
  final String? selected;
  final void Function(String direction) onSelect;

  const _DomainRow({
    required this.domain,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _kRpPurple.withValues(alpha: 0.1), width: 0.75),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(domain,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: MyWalkColor.warmWhite)),
          ),
          const SizedBox(width: 8),
          _DirectionChip(
            label: '→ Toward',
            selected: selected == 'toward',
            color: MyWalkColor.sage,
            onTap: () => onSelect('toward'),
          ),
          const SizedBox(width: 6),
          _DirectionChip(
            label: '← Away',
            selected: selected == 'away',
            color: MyWalkColor.warmCoral,
            onTap: () => onSelect('away'),
          ),
        ],
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DirectionChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.5)
                : MyWalkColor.warmWhite.withValues(alpha: 0.15),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? color
                    : MyWalkColor.warmWhite.withValues(alpha: 0.4))),
      ),
    );
  }
}

// ── Affirmation ───────────────────────────────────────────────────────────────

class _CompassAffirmationView extends StatelessWidget {
  final bool allToward;
  const _CompassAffirmationView({required this.allToward});

  @override
  Widget build(BuildContext context) {
    final body = allToward
        ? RecoveryModuleContent.m3InventoryCompleteMessage
        : RecoveryModuleContent.m3InventoryCompleteMessageWithAway;

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
                    child: const Icon(Icons.explore_outlined,
                        color: _kRpPurple, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('Compass checked.',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.warmWhite)),
                  const SizedBox(height: 14),
                  Text(
                    body,
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
