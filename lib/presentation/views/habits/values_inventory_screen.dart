import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/recovery_path_provider.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/partner_invite_dialog.dart';
import 'breaking_free_encouraging_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// 8-domain values inventory for Module 3.
/// Each domain: open reflection text, two 1–10 sliders, compass selector.
/// All fields required before advancing. Draft saved per domain.
class ValuesInventoryScreen extends StatefulWidget {
  final String habitId;
  final String habitName;
  final bool setupMode;
  final bool wantsPartner;
  final bool wantsRecoveryPath;
  final Color accentColor;

  const ValuesInventoryScreen({
    super.key,
    required this.habitId,
    this.habitName = '',
    this.setupMode = false,
    this.wantsPartner = false,
    this.wantsRecoveryPath = false,
    this.accentColor = _kRpPurple,
  });

  @override
  State<ValuesInventoryScreen> createState() => _ValuesInventoryScreenState();
}

class _ValuesInventoryScreenState extends State<ValuesInventoryScreen> {
  Color get _kRpPurple => widget.accentColor;

  final List<String> _domains = RecoveryModuleContent.m3ValuesDomains;
  late final List<int> _importance;       // 1–10
  late final List<int> _alignment;        // 1–10
  late final List<String> _reflection;
  late final List<String?> _compassDir;   // 'toward'|'neutral'|'away'|null
  late final List<TextEditingController> _controllers;

  int _step = 0;
  bool _saving = false;
  bool _done = false;
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    final n = _domains.length;
    _importance = List.filled(n, 5);
    _alignment = List.filled(n, 5);
    _reflection = List.filled(n, '');
    _compassDir = List.filled(n, null);
    _controllers = List.generate(n, (_) => TextEditingController());
    for (int i = 0; i < n; i++) {
      _controllers[i].addListener(() => setState(() {}));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _restoreDraft() {
    final path =
        context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    if (path == null) return;

    // Edit mode: values already saved — load them and skip the intro.
    if (path.module3.valuesInventoryDone &&
        path.module3.valuesInventory.isNotEmpty) {
      final existing = path.module3.valuesInventory;
      setState(() {
        _showIntro = false;
        _step = 0;
        for (int i = 0; i < existing.length && i < _domains.length; i++) {
          final entry = existing[i];
          _importance[i] = entry.importance;
          _alignment[i] = entry.alignment;
          _reflection[i] = entry.reflectionText;
          _controllers[i].text = entry.reflectionText;
          _compassDir[i] = entry.compassDirection;
        }
      });
      return;
    }

    // Resume an in-progress draft.
    if (path.valuesInventoryDraftStep == 0) return;
    final draft = path.valuesInventoryDraft;
    setState(() {
      _showIntro = false;
      _step = path.valuesInventoryDraftStep.clamp(0, _domains.length - 1);
      for (int i = 0; i < draft.length && i < _domains.length; i++) {
        final item = draft[i];
        _importance[i] = (item['importance'] as int?) ?? 5;
        _alignment[i] = (item['alignment'] as int?) ?? 5;
        final text = (item['reflectionText'] as String?) ?? '';
        _reflection[i] = text;
        _controllers[i].text = text;
        _compassDir[i] = item['compassDirection'] as String?;
      }
    });
  }

  bool get _isCurrentStepValid {
    return _controllers[_step].text.trim().length >= 60 &&
        _compassDir[_step] != null;
  }

  Future<void> _advanceStep() async {
    _reflection[_step] = _controllers[_step].text.trim();
    final nextStep = _step + 1;
    final currentEntries = List<Map<String, dynamic>>.generate(
      nextStep,
      (i) => {
        'importance': _importance[i],
        'alignment': _alignment[i],
        'reflectionText': _reflection[i],
        'compassDirection': _compassDir[i] ?? 'neutral',
      },
    );
    // Fire-and-forget draft save; do not block navigation.
    context
        .read<RecoveryPathProvider>()
        .saveValuesInventoryDraft(widget.habitId, nextStep, currentEntries)
        .ignore();
    setState(() => _step = nextStep);
  }

  Future<void> _save() async {
    _reflection[_step] = _controllers[_step].text.trim();
    setState(() => _saving = true);
    try {
      final entries = List.generate(
        _domains.length,
        (i) => ValuesInventoryEntry(
          domain: _domains[i],
          importance: _importance[i],
          alignment: _alignment[i],
          reflectionText: _reflection[i],
          compassDirection: _compassDir[i] ?? 'neutral',
        ),
      );

      final summary = entries
          .map((e) =>
              '${e.domain}: importance=${e.importance}, '
              'alignment=${e.alignment}, '
              'compassDirection=${e.compassDirection}, '
              'reflection=${e.reflectionText}')
          .join('\n\n');

      final prov = context.read<RecoveryPathProvider>();

      // Ensure a recovery_paths document exists so saveValuesInventoryEntries
      // and saveSession can write to it. Created with planActive: false —
      // activation only happens if the user explicitly chose the Freedom Plan.
      if (prov.pathFor(widget.habitId) == null) {
        final hp = context.read<HabitProvider>();
        await prov.startPath(widget.habitId);
        if (!mounted) return;
        final habit = hp.habits.where((h) => h.id == widget.habitId).firstOrNull;
        if (habit != null && !habit.hasRecoveryPath) {
          await hp.updateHabit(habit.copyWith(hasRecoveryPath: true));
        }
      }

      // Activate the plan only when the user explicitly chose it.
      if (widget.wantsRecoveryPath) {
        final path = prov.pathFor(widget.habitId);
        if (path != null && !path.planActive) {
          await prov.activatePlan(widget.habitId);
        }
        if (!mounted) return;
      }

      final now = DateTime.now();
      final session = RecoverySession(
        id: '${widget.habitId}_m3ValuesInventory_${now.millisecondsSinceEpoch}',
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m3ValuesInventory,
        moduleNumber: 3,
        responseText: summary,
        createdAt: now,
      );

      await prov.saveValuesInventoryEntries(widget.habitId, entries);
      await prov.saveSession(session);
      await prov.saveValuesInventoryDraft(widget.habitId, 0, []);

      if (!mounted) return;
      setState(() => _saving = false);

      if (widget.setupMode) {
        if (widget.wantsPartner) {
          await showPartnerInviteDialog(
            context,
            habitId: widget.habitId,
            habitName: widget.habitName,
            habitLabel: 'Breaking Patterns: ${widget.habitName}',
          );
        }
        if (!mounted) return;
        if (widget.wantsRecoveryPath) {
          setState(() => _done = true);
        } else {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => const BreakingFreeEncouragingScreen(),
            ),
          );
        }
      } else {
        // Accessed from within the plan (not setup) — just return.
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e, st) {
      debugPrint('ValuesInventory save error: $e\n$st');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Save failed. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return _WhatHappensNextView(isSetupMode: widget.setupMode);
    }

    if (_showIntro) {
      return _ValuesIntroPage(
        onStart: () => setState(() => _showIntro = false),
        setupMode: widget.setupMode,
      );
    }

    final domain = _domains[_step];
    final isLast = _step == _domains.length - 1;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Values',
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
              setState(() => _showIntro = true);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Domain counter
                        Text(
                          'Domain ${_step + 1} of ${_domains.length}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
                              letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 6),

                        // Progress dots
                        Row(
                          children: List.generate(_domains.length, (i) {
                            final active = i == _step;
                            final done = i < _step;
                            return Container(
                              margin: const EdgeInsets.only(right: 5),
                              width: active ? 14 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: done || active
                                    ? _kRpPurple
                                    : _kRpPurple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),

                        // Domain name
                        Text(
                          domain,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: MyWalkColor.warmWhite,
                              height: 1.3),
                        ),
                        const SizedBox(height: 20),

                        // Reflection text field
                        _ReflectionField(
                          controller: _controllers[_step],
                          domain: domain,
                        ),
                        const SizedBox(height: 24),

                        // Consistency slider (single slider per spec)
                        _SliderRow(
                          label: 'How consistently am I living this?',
                          value: _alignment[_step],
                          onChanged: (v) =>
                              setState(() => _alignment[_step] = v),
                        ),
                        const SizedBox(height: 16),

                        // Compass selector
                        _CompassSelector(
                          selected: _compassDir[_step],
                          onSelected: (val) =>
                              setState(() => _compassDir[_step] = val),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Pinned button
                if (isLast)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_saving || !_isCurrentStepValid) ? null : _save,
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
                            : const Text('Save my values',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCurrentStepValid ? _advanceStep : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRpPurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Next → ${_domains[_step + 1]}',
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
}

// ── Values intro page (shown before first domain) ────────────────────────────

class _ValuesIntroPage extends StatelessWidget {
  final VoidCallback onStart;
  final bool setupMode;
  const _ValuesIntroPage({required this.onStart, this.setupMode = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Values',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        // In setup mode the user must complete values — block back nav.
        leading: setupMode
            ? const SizedBox.shrink()
            : BackButton(color: MyWalkColor.warmWhite),
        automaticallyImplyLeading: !setupMode,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'The Role of your Values in Breaking Patterns',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: MyWalkColor.warmWhite,
                              height: 1.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          RecoveryModuleContent.m3InventoryIntro,
                          style: TextStyle(
                              fontSize: 15,
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.72),
                              height: 1.65),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Start →',
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
}

// ── Reflection field ─────────────────────────────────────────────────────────

class _ReflectionField extends StatelessWidget {
  final TextEditingController controller;
  final String domain;

  const _ReflectionField({required this.controller, required this.domain});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What matters most to me in this area?',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: null,
          style: const TextStyle(
              color: MyWalkColor.warmWhite, fontSize: 14, height: 1.5),
          decoration: InputDecoration(
            hintText:
                'What does $domain mean in your life, and what would living it well look like for you?',
            hintStyle: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: _kRpPurple, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 6),
        Text(
          'Minimum 60 characters required',
          style: TextStyle(
              fontSize: 11,
              color: MyWalkColor.softGold.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

// ── Compass selector ─────────────────────────────────────────────────────────

class _CompassSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _CompassSelector(
      {required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Does your current pattern move you toward or away from this?',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _CompassChip(
              label: 'Toward',
              value: 'toward',
              selected: selected,
              onTap: onSelected,
              color: MyWalkColor.sage,
            ),
            const SizedBox(width: 8),
            _CompassChip(
              label: 'Neutral',
              value: 'neutral',
              selected: selected,
              onTap: onSelected,
              color: _kRpPurple.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            _CompassChip(
              label: 'Away',
              value: 'away',
              selected: selected,
              onTap: onSelected,
              color: MyWalkColor.golden,
            ),
          ],
        ),
        if (selected == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Select one to continue',
              style: TextStyle(
                  fontSize: 11,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.35),
                  fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}

class _CompassChip extends StatelessWidget {
  final String label;
  final String value;
  final String? selected;
  final ValueChanged<String> onTap;
  final Color color;

  const _CompassChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? color
                  : MyWalkColor.warmWhite.withValues(alpha: 0.12),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? color
                  : MyWalkColor.warmWhite.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Slider row ───────────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.7))),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _kRpPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text('$value',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kRpPurple)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _kRpPurple,
            inactiveTrackColor: _kRpPurple.withValues(alpha: 0.15),
            thumbColor: _kRpPurple,
            overlayColor: _kRpPurple.withValues(alpha: 0.1),
            trackHeight: 4,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 — Not at all',
                style: TextStyle(
                    fontSize: 10,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.3))),
            Text('10 — Very consistently',
                style: TextStyle(
                    fontSize: 10,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.3))),
          ],
        ),
      ],
    );
  }
}

// ── What happens next view ────────────────────────────────────────────────────

class _WhatHappensNextView extends StatelessWidget {
  final bool isSetupMode;
  const _WhatHappensNextView({this.isSetupMode = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'What\'s next',
          style: TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
          SafeArea(top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Plan created banner ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _kRpPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _kRpPurple.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: _kRpPurple, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Your Freedom Plan has been created',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  MyWalkColor.warmWhite.withValues(alpha: 0.9),
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'What Happens Next?',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.3),
                  ),
                  const SizedBox(height: 20),

                  // ── Body ─────────────────────────────────────────────
                  Text(
                    'For the next six days there\'s nothing required except to keep a brief record of any time you slip into the pattern you\'re working on — or even if you felt a strong urge but didn\'t act on it.',
                    style: TextStyle(
                        fontSize: 15,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.72),
                        height: 1.65),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                          fontSize: 15,
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.72),
                          height: 1.65),
                      children: const [
                        TextSpan(text: 'You\'ll see a '),
                        TextSpan(
                          text: '\'Record a moment\'',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text:
                              ' button on your habit card. Tap it whenever something happens — the sooner after the moment, the better. Above all, be brutally honest. No one can read what you enter — it\'s all encrypted. It\'s between you and God and there is nothing you can say that He has not heard or seen and He wants us to lay everything before Him with honesty as He cares.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Don\'t try to change anything yet. Just observe and record.',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
                        height: 1.65),
                  ),
                  const SizedBox(height: 24),
                  Divider(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.12),
                      thickness: 1),
                  const SizedBox(height: 20),

                  // ── Why section ───────────────────────────────────────
                  const Text(
                    'Why do we do this?',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'You can change unwanted patterns and this plan will help you do that. It is based on solid behavioral change research and is designed to make this as easy as possible for you. So, be encouraged.',
                    style: TextStyle(
                        fontSize: 15,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.72),
                        height: 1.65),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Our first goal is merely to begin tracking behavior. One cannot change what you cannot see.\n\nMost problematic habits feel chaotic and uncontrollable partly because the pattern is invisible — things seem to \'just happen.\' The first job is to make the invisible visible: map the specific cues, emotional states, thoughts, and consequences. This data becomes the foundation for everything else.\n\nSelf-monitoring is one of the most robust behavior change techniques. What many people discover within two weeks is that their behavior clusters around a surprisingly small number of cues (perhaps three to five distinct patterns). This recognition is itself therapeutic — you will see that the patterns you want to break aren\'t necessarily random and chaotic but follow certain cues, and when you know what those cues are they become manageable by you.',
                    style: TextStyle(
                        fontSize: 15,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.72),
                        height: 1.65),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We\'re not keeping a record of guilt or wrongs here.\n\nWe\'re starting to gather the data we need to see whether there are any patterns — cues that tend to trigger this behavior — so we can start doing something about them.',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
                        height: 1.65),
                  ),
                  const SizedBox(height: 32),
                  _ScriptureBlock(
                    verse: '"Do not be anxious about anything, but in everything by prayer and supplication with thanksgiving let your requests be made known to God."',
                    reference: 'Philippians 4:6',
                  ),
                  const SizedBox(height: 16),
                  _ScriptureBlock(
                    verse: '"Come to me, all who labor and are heavy laden, and I will give you rest."',
                    reference: 'Matthew 11:28',
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isSetupMode) {
                          context
                              .read<NavigationProvider>()
                              .switchToTab(0);
                        }
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Let\'s begin',
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
}

class _ScriptureBlock extends StatelessWidget {
  final String verse;
  final String reference;
  const _ScriptureBlock({required this.verse, required this.reference});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _kRpPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRpPurple.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            verse,
            style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                height: 1.6),
          ),
          const SizedBox(height: 6),
          Text(
            '— $reference',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kRpPurple.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
