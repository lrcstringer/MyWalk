import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/cue_rubric_service.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'cue_hierarchy_screen.dart';
import 'module_session_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Module 4 — Build Your Guardrails.
/// Three tabs: Environmental Restructuring, HRS Plans, Urge Surfing.
class GuardrailsScreen extends StatefulWidget {
  final String habitId;
  final String habitName;
  /// Optional initial tab index (0=env, 1=HRS, 2=urge surfing).
  final int initialTab;

  const GuardrailsScreen({
    super.key,
    required this.habitId,
    required this.habitName,
    this.initialTab = 0,
  });

  @override
  State<GuardrailsScreen> createState() => _GuardrailsScreenState();
}

class _GuardrailsScreenState extends State<GuardrailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecoveryPathProvider>();
    final path = prov.pathFor(widget.habitId);

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Build Your Guardrails',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: const BackButton(color: MyWalkColor.warmWhite),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kRpPurple,
          unselectedLabelColor: MyWalkColor.warmWhite.withValues(alpha: 0.4),
          indicatorColor: _kRpPurple,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Environment'),
            Tab(text: 'HRS Plans'),
            Tab(text: 'Urge Surfing'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          TabBarView(
            controller: _tabs,
            children: [
              _EnvRestructuringTab(
                habitId: widget.habitId,
                habitName: widget.habitName,
                habitType: path?.habitType ?? '',
                cueHierarchyDone: path?.cueHierarchyDone ?? false,
                environmentalChangesDone:
                    path?.environmentalChangesDone ?? false,
                cueHierarchy: path?.cueHierarchy ?? [],
              ),
              _HrsPlanTab(
                habitId: widget.habitId,
                existingPlans: path?.module4.hrsPlan ?? [],
                hrsPlanDone: path?.hrsPlanDone ?? false,
                cueHierarchy: path?.cueHierarchy ?? [],
              ),
              _UrgeSurfingTab(
                habitId: widget.habitId,
                urgeSurfingIntroSeen: path?.urgeSurfingIntroSeen ?? false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab 1 — Environmental Restructuring ───────────────────────────────────────

class _EnvRestructuringTab extends StatefulWidget {
  final String habitId;
  final String habitName;
  final String habitType;
  final bool cueHierarchyDone;
  final bool environmentalChangesDone;
  final List<Map<String, dynamic>> cueHierarchy;

  const _EnvRestructuringTab({
    required this.habitId,
    required this.habitName,
    required this.habitType,
    required this.cueHierarchyDone,
    required this.environmentalChangesDone,
    required this.cueHierarchy,
  });

  @override
  State<_EnvRestructuringTab> createState() => _EnvRestructuringTabState();
}

class _EnvRestructuringTabState extends State<_EnvRestructuringTab> {
  List<TextEditingController> _controllers = [];
  List<String> _cueTexts = [];
  List<List<String>> _suggestions = [];
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(_EnvRestructuringTab old) {
    super.didUpdateWidget(old);
    if (old.cueHierarchy != widget.cueHierarchy ||
        old.habitType != widget.habitType) {
      for (final c in _controllers) {
        c.dispose();
      }
      _rebuild();
    }
  }

  void _rebuild() {
    final cues = widget.cueHierarchy.take(3).toList();
    _cueTexts = cues.map((c) => c['cueText'] as String? ?? '').toList();
    _controllers = List.generate(cues.length, (_) => TextEditingController());
    _suggestions = _cueTexts.map((t) =>
      CueRubricService.environmentalSuggestionsFor(widget.habitType, t)).toList();
    for (final c in _controllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSave =>
      _controllers.isNotEmpty &&
      _controllers.every((c) => c.text.trim().isNotEmpty);

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final changes = List.generate(_cueTexts.length, (i) => {
        'cue': _cueTexts[i],
        'change': _controllers[i].text.trim(),
      });
      await context
          .read<RecoveryPathProvider>()
          .markEnvironmentalChangesDone(widget.habitId, changes);
      if (mounted) setState(() { _saving = false; _saved = true; });
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
    if (!widget.cueHierarchyDone) {
      return _GateView(
        message: 'Complete your cue map first — your guardrails will be built from it.',
        buttonLabel: 'Build my cue map',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CueHierarchyScreen(
            habitId: widget.habitId,
            habitName: widget.habitName,
            habitType: widget.habitType,
          ),
        )),
      );
    }

    final alreadySaved = widget.environmentalChangesDone || _saved;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alreadySaved)
            _DoneBanner(label: 'Environmental changes saved.'),
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: _kRpPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kRpPurple.withValues(alpha: 0.18)),
            ),
            child: Text(
              'Willpower works worst exactly when you need it most. '
              'Making concrete changes to your environment is more effective '
              'than relying on willpower in the moment.',
              style: TextStyle(
                  fontSize: 13,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                  height: 1.5),
            ),
          ),
          if (_cueTexts.isEmpty)
            Text('No triggers found — complete your cue map first.',
                style: TextStyle(
                    fontSize: 13,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.5)))
          else
            ...List.generate(_cueTexts.length, (i) =>
              _EnvCueSection(
                cueText: _cueTexts[i],
                controller: _controllers[i],
                suggestions: _suggestions[i],
                readOnly: alreadySaved,
              )),
          if (!alreadySaved) ...[
            const SizedBox(height: 8),
            SizedBox(
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
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save my changes',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EnvCueSection extends StatefulWidget {
  final String cueText;
  final TextEditingController controller;
  final List<String> suggestions;
  final bool readOnly;

  const _EnvCueSection({
    required this.cueText,
    required this.controller,
    required this.suggestions,
    required this.readOnly,
  });

  @override
  State<_EnvCueSection> createState() => _EnvCueSectionState();
}

class _EnvCueSectionState extends State<_EnvCueSection> {
  final Set<int> _dismissed = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kRpPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(widget.cueText,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kRpPurple)),
          ),
          const SizedBox(height: 10),
          const Text('What one concrete change will you make?',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: MyWalkColor.warmWhite)),
          const SizedBox(height: 6),
          TextField(
            controller: widget.controller,
            readOnly: widget.readOnly,
            minLines: 2,
            maxLines: null,
            style: const TextStyle(
                color: MyWalkColor.warmWhite, fontSize: 13, height: 1.5),
            decoration: InputDecoration(
              hintText: 'e.g. Move my phone charger to the hallway before 9pm',
              hintStyle: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.28),
                  fontSize: 12),
              filled: true,
              fillColor: MyWalkColor.surfaceOverlay,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Be specific — e.g. "delete the app" not "use my phone less"',
              style: TextStyle(
                  fontSize: 11,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.38),
                  fontStyle: FontStyle.italic),
            ),
          ),
          if (!widget.readOnly) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.suggestions
                  .asMap()
                  .entries
                  .where((e) => !_dismissed.contains(e.key))
                  .map((e) => _SuggestionChip(
                        label: e.value,
                        onTap: () =>
                            widget.controller.text = e.value,
                        onDismiss: () =>
                            setState(() => _dismissed.add(e.key)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _SuggestionChip(
      {required this.label, required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.6))),
            ),
            const SizedBox(width: 3),
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.close_rounded,
                  size: 12,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 2 — HRS Plans ─────────────────────────────────────────────────────────

class _HrsPlanTab extends StatefulWidget {
  final String habitId;
  final List<HrsPlan> existingPlans;
  final bool hrsPlanDone;
  final List<Map<String, dynamic>> cueHierarchy;

  const _HrsPlanTab({
    required this.habitId,
    required this.existingPlans,
    required this.hrsPlanDone,
    required this.cueHierarchy,
  });

  @override
  State<_HrsPlanTab> createState() => _HrsPlanTabState();
}

class _HrsPlanTabState extends State<_HrsPlanTab> {
  late List<_PlanControllers> _planControllers;
  bool _saving = false;
  bool _showHrsIntro = true;

  @override
  void initState() {
    super.initState();
    if (widget.hrsPlanDone) _showHrsIntro = false;
    if (widget.existingPlans.isNotEmpty) {
      _planControllers =
          widget.existingPlans.map(_PlanControllers.fromPlan).toList();
    } else if (widget.cueHierarchy.isNotEmpty && !widget.hrsPlanDone) {
      // Seed situation fields from cue hierarchy (up to 5 cues → 5 plan slots).
      _planControllers = widget.cueHierarchy
          .take(5)
          .map((c) => _PlanControllers.seeded(c['cueText'] as String? ?? ''))
          .toList();
    } else {
      _planControllers = [_PlanControllers.blank()];
    }
  }

  @override
  void dispose() {
    for (final p in _planControllers) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final plans = _planControllers
        .where((p) => p.situation.text.trim().isNotEmpty)
        .map((p) => HrsPlan(
              situation: p.situation.text.trim(),
              earlyWarnings: p.earlyWarnings.text.trim(),
              firstResponse: p.firstResponse.text.trim(),
              contactName: p.contactName.text.trim(),
            ))
        .toList();
    final prov = context.read<RecoveryPathProvider>();
    await prov.saveHrsPlan(widget.habitId, plans);
    if (!widget.hrsPlanDone) {
      await prov.markHrsPlanDone(widget.habitId);
    }
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Plans saved.'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showHrsIntro) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Build Your Coping Plans',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite,
                  height: 1.3),
            ),
            const SizedBox(height: 16),
            Text(
              'When a high-risk situation arrives, the best time to decide what to do was before it happened. '
              'You\'re going to write a specific plan for each of your triggers — so when the moment comes, '
              'you\'re executing a decision you already made.',
              style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                  height: 1.7),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _showHrsIntro = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRpPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Build my plans',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.hrsPlanDone) _DonesBanner(),
          Text(
            RecoveryModuleContent.m4HrsPlanSubtitle,
            style: TextStyle(
                fontSize: 13,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                height: 1.5),
          ),
          const SizedBox(height: 20),
          ..._planControllers.asMap().entries.map((e) => _PlanCard(
                index: e.key,
                controllers: e.value,
                onRemove: _planControllers.length > 1
                    ? () =>
                        setState(() => _planControllers.removeAt(e.key))
                    : null,
              )),
          if (_planControllers.length < 5)
            TextButton.icon(
              onPressed: () =>
                  setState(() => _planControllers.add(_PlanControllers.blank())),
              icon: const Icon(Icons.add_rounded, size: 16, color: _kRpPurple),
              label: const Text('Add another plan',
                  style: TextStyle(fontSize: 13, color: _kRpPurple)),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.25),
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
                  : const Text('Save plans',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  final int index;
  final _PlanControllers controllers;
  final VoidCallback? onRemove;

  const _PlanCard({
    required this.index,
    required this.controllers,
    this.onRemove,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  @override
  void initState() {
    super.initState();
    widget.controllers.firstResponse.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _kRpPurple.withValues(alpha: 0.15), width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Plan ${widget.index + 1}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kRpPurple.withValues(alpha: 0.8))),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Icon(Icons.close_rounded,
                      size: 16,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _PlanField(
              label: RecoveryModuleContent.m4SituationLabel,
              controller: widget.controllers.situation),
          _PlanField(
              label: RecoveryModuleContent.m4EarlyWarningsLabel,
              controller: widget.controllers.earlyWarnings),
          _PlanField(
              label: RecoveryModuleContent.m4FirstResponseLabel,
              controller: widget.controllers.firstResponse,
              hint: 'Be specific — a concrete action, not a mindset'),
          _PlanField(
              label: '${RecoveryModuleContent.m4ContactNameLabel} (optional)',
              controller: widget.controllers.contactName,
              hint: 'Name and contact, or a note to yourself',
              last: true),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'This is a good moment to consider setting up a support partner.',
              style: TextStyle(
                  fontSize: 11,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.38),
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool last;

  const _PlanField({
    required this.label,
    required this.controller,
    this.hint,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.5))),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            style:
                const TextStyle(color: MyWalkColor.warmWhite, fontSize: 13),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: hint != null
                  ? TextStyle(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.25),
                      fontSize: 12,
                      fontStyle: FontStyle.italic)
                  : null,
              filled: true,
              fillColor: MyWalkColor.surfaceOverlay,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanControllers {
  final TextEditingController situation;
  final TextEditingController earlyWarnings;
  final TextEditingController firstResponse;
  final TextEditingController contactName;

  _PlanControllers({
    required this.situation,
    required this.earlyWarnings,
    required this.firstResponse,
    required this.contactName,
  });

  factory _PlanControllers.blank() => _PlanControllers(
        situation: TextEditingController(),
        earlyWarnings: TextEditingController(),
        firstResponse: TextEditingController(),
        contactName: TextEditingController(),
      );

  factory _PlanControllers.seeded(String cueText) => _PlanControllers(
        situation: TextEditingController(text: cueText),
        earlyWarnings: TextEditingController(),
        firstResponse: TextEditingController(),
        contactName: TextEditingController(),
      );

  factory _PlanControllers.fromPlan(HrsPlan plan) => _PlanControllers(
        situation: TextEditingController(text: plan.situation),
        earlyWarnings: TextEditingController(text: plan.earlyWarnings),
        firstResponse: TextEditingController(text: plan.firstResponse),
        contactName: TextEditingController(text: plan.contactName),
      );

  void dispose() {
    situation.dispose();
    earlyWarnings.dispose();
    firstResponse.dispose();
    contactName.dispose();
  }
}

// ── Tab 3 — Urge Surfing ──────────────────────────────────────────────────────

class _UrgeSurfingTab extends StatelessWidget {
  final String habitId;
  final bool urgeSurfingIntroSeen;

  const _UrgeSurfingTab({
    required this.habitId,
    required this.urgeSurfingIntroSeen,
  });

  @override
  Widget build(BuildContext context) {
    if (!urgeSurfingIntroSeen) {
      return _UrgeSurfingIntro(habitId: habitId);
    }
    return _UrgeSurfingSession(habitId: habitId);
  }
}

class _UrgeSurfingIntro extends StatelessWidget {
  final String habitId;
  const _UrgeSurfingIntro({required this.habitId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('A different option',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite)),
          const SizedBox(height: 16),
          Text(
            "You don't have to fight an urge or give in to it. There's a third option — you can just watch it.\n\n"
            "Urges aren't commands. They're neurological events with a natural shape — they rise, peak, and pass, usually within 15–30 minutes, whether or not you act on them. Urge surfing is the practice of riding that arc rather than reacting to it.\n\n"
            "The more you practise this, the weaker the urge becomes over time.",
            style: TextStyle(
                fontSize: 14,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                height: 1.65),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await context
                    .read<RecoveryPathProvider>()
                    .markUrgeSurfingIntroSeen(habitId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'The "Urge surfed" button will now appear on your habit card.'),
                      duration: const Duration(seconds: 3),
                      backgroundColor: const Color(0xFF8B7EC8),
                    ),
                  );
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ModuleSessionScreen(
                      habitId: habitId,
                      sessionType: RecoverySessionType.m4UrgeSurfing,
                      moduleNumber: 4,
                      title: RecoveryModuleContent.m4UrgeSurfingTitle,
                      prompts: RecoveryModuleContent.m4UrgeSurfingPrompts,
                      hint: RecoveryModuleContent.m4UrgeSurfingHint,
                    ),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start my first urge surfing session',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgeSurfingSession extends StatelessWidget {
  final String habitId;
  const _UrgeSurfingSession({required this.habitId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            RecoveryModuleContent.m4UrgeSurfingHint,
            style: TextStyle(
                fontSize: 13,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ModuleSessionScreen(
                    habitId: habitId,
                    sessionType: RecoverySessionType.m4UrgeSurfing,
                    moduleNumber: 4,
                    title: RecoveryModuleContent.m4UrgeSurfingTitle,
                    prompts: RecoveryModuleContent.m4UrgeSurfingPrompts,
                    hint: RecoveryModuleContent.m4UrgeSurfingHint,
                  ),
                ),
              ),
              icon: const Icon(Icons.waves_rounded, size: 16),
              label: const Text('Start urge surfing session',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _DonesBanner extends StatelessWidget {
  const _DonesBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: MyWalkColor.sage.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, size: 14, color: MyWalkColor.sage),
        const SizedBox(width: 8),
        Text('Plans already saved.',
            style: TextStyle(
                fontSize: 12,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.7))),
      ]),
    );
  }
}

class _DoneBanner extends StatelessWidget {
  final String label;
  const _DoneBanner({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: MyWalkColor.sage.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, size: 14, color: MyWalkColor.sage),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.7))),
      ]),
    );
  }
}

class _GateView extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onTap;

  const _GateView({
    required this.message,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                height: 1.5),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onTap,
            child: Text(buttonLabel,
                style: const TextStyle(color: _kRpPurple, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
