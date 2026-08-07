import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// 8-domain values inventory for Module 3.
/// Each domain: open reflection text, two 1–10 sliders, compass selector.
/// All fields required before advancing. Draft saved per domain.
class ValuesInventoryScreen extends StatefulWidget {
  final String habitId;
  const ValuesInventoryScreen({super.key, required this.habitId});

  @override
  State<ValuesInventoryScreen> createState() => _ValuesInventoryScreenState();
}

class _ValuesInventoryScreenState extends State<ValuesInventoryScreen> {
  final List<String> _domains = RecoveryModuleContent.m3ValuesDomains;
  late final List<int> _importance;       // 1–10
  late final List<int> _alignment;        // 1–10
  late final List<String> _reflection;
  late final List<String?> _compassDir;   // 'toward'|'neutral'|'away'|null
  late final List<TextEditingController> _controllers;

  int _step = 0;
  bool _saving = false;
  bool _done = false;
  bool _completionHasAway = false;

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
    if (path == null || path.valuesInventoryDraftStep == 0) return;
    final draft = path.valuesInventoryDraft;
    setState(() {
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
    return _controllers[_step].text.trim().length >= 10 &&
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

      final hasAway = entries.any((e) => e.compassDirection == 'away');

      final summary = entries
          .map((e) =>
              '${e.domain}: importance=${e.importance}, '
              'alignment=${e.alignment}, '
              'compassDirection=${e.compassDirection}, '
              'reflection=${e.reflectionText}')
          .join('\n\n');

      final prov = context.read<RecoveryPathProvider>();
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
      // Clear draft after successful save.
      await prov.saveValuesInventoryDraft(widget.habitId, 0, []);

      if (mounted) {
        setState(() {
          _saving = false;
          _done = true;
          _completionHasAway = hasAway;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return _CompletionView(hasAway: _completionHasAway);
    }

    final domain = _domains[_step];
    final isLast = _step == _domains.length - 1;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Values Inventory',
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
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_step == 0) ...[
                        Text(
                          RecoveryModuleContent.m3InventoryIntro,
                          style: TextStyle(
                              fontSize: 13,
                              color:
                                  MyWalkColor.warmWhite.withValues(alpha: 0.6),
                              height: 1.5),
                        ),
                        const SizedBox(height: 16),
                      ],

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

                      // Importance slider
                      _SliderRow(
                        label: RecoveryModuleContent.m3ImportanceLabel,
                        value: _importance[_step],
                        color: _kRpPurple,
                        onChanged: (v) =>
                            setState(() => _importance[_step] = v),
                      ),
                      const SizedBox(height: 20),

                      // Alignment slider
                      _SliderRow(
                        label: RecoveryModuleContent.m3AlignmentLabel,
                        value: _alignment[_step],
                        color: MyWalkColor.sage,
                        onChanged: (v) =>
                            setState(() => _alignment[_step] = v),
                      ),
                      const SizedBox(height: 16),

                      // Gap callout
                      _GapCallout(
                          gap: _importance[_step] - _alignment[_step]),
                      const SizedBox(height: 28),

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
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_saving || !_isCurrentStepValid)
                        ? null
                        : () {
                            if (isLast) {
                              _save();
                            } else {
                              _advanceStep();
                            }
                          },
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
                            isLast ? 'Save my values map' : 'Next',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                  ),
                ),
              ),
            ],
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
          'In your own words',
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
  final Color color;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.color,
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
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.7))),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text('$value',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
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
            Text('Not much',
                style: TextStyle(
                    fontSize: 10,
                    color:
                        MyWalkColor.warmWhite.withValues(alpha: 0.3))),
            Text('Very much',
                style: TextStyle(
                    fontSize: 10,
                    color:
                        MyWalkColor.warmWhite.withValues(alpha: 0.3))),
          ],
        ),
      ],
    );
  }
}

// ── Gap callout ──────────────────────────────────────────────────────────────

class _GapCallout extends StatelessWidget {
  final int gap;
  const _GapCallout({required this.gap});

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color tint;

    if (gap == 0) {
      text = "You're living in alignment here.";
      tint = MyWalkColor.sage;
    } else if (gap < 0) {
      text = "Living beyond what you value — that's also meaningful.";
      tint = MyWalkColor.sage;
    } else if (gap > 5) {
      text = "There's a meaningful gap here.";
      tint = _kRpPurple;
    } else {
      text = "Some room to grow here.";
      tint = _kRpPurple.withValues(alpha: 0.7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic),
      ),
    );
  }
}

// ── Completion view ──────────────────────────────────────────────────────────

class _CompletionView extends StatelessWidget {
  final bool hasAway;
  const _CompletionView({required this.hasAway});

  @override
  Widget build(BuildContext context) {
    final message = hasAway
        ? RecoveryModuleContent.m3InventoryCompleteMessageWithAway
        : RecoveryModuleContent.m3InventoryCompleteMessage;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
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
                    child: const Icon(Icons.anchor_rounded,
                        color: _kRpPurple, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('Values Map Saved',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.warmWhite)),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color:
                            MyWalkColor.warmWhite.withValues(alpha: 0.6),
                        height: 1.5,
                        fontStyle: FontStyle.italic),
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
