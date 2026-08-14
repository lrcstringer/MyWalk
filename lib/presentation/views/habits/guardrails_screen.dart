import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'cue_hierarchy_screen.dart';
import 'urge_surfed_log_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Module 4 — Build Your Guardrails.
/// Three tabs: Environmental Restructuring, HRS Plans, Urge Surfing.
class GuardrailsScreen extends StatefulWidget {
  final String habitId;
  final String habitName;
  /// Optional initial tab index (0=env, 1=HRS, 2=urge surfing).
  final int initialTab;
  final Color accentColor;

  const GuardrailsScreen({
    super.key,
    required this.habitId,
    required this.habitName,
    this.initialTab = 0,
    this.accentColor = _kRpPurple,
  });

  @override
  State<GuardrailsScreen> createState() => _GuardrailsScreenState();
}

class _GuardrailsScreenState extends State<GuardrailsScreen>
    with SingleTickerProviderStateMixin {
  Color get _kRpPurple => widget.accentColor;

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
                habitName: widget.habitName,
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
  List<List<TextEditingController>> _controllers = [];
  List<String> _cueTexts = [];
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _rebuild();
    if (widget.environmentalChangesDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedChanges());
    }
  }

  @override
  void didUpdateWidget(_EnvRestructuringTab old) {
    super.didUpdateWidget(old);
    if (old.cueHierarchy != widget.cueHierarchy ||
        old.habitType != widget.habitType) {
      for (final list in _controllers) {
        for (final c in list) {
          c.dispose();
        }
      }
      _rebuild();
    }
    if (!old.environmentalChangesDone && widget.environmentalChangesDone) {
      _loadSavedChanges();
    }
  }

  TextEditingController _makeCtrl() {
    final c = TextEditingController();
    c.addListener(() => setState(() {}));
    return c;
  }

  void _rebuild() {
    final cues = widget.cueHierarchy.take(3).toList();
    _cueTexts = cues.map((c) => c['cueText'] as String? ?? '').toList();
    _controllers = List.generate(cues.length, (_) => [_makeCtrl()]);
  }

  Future<void> _loadSavedChanges() async {
    if (!mounted) return;
    final prov = context.read<RecoveryPathProvider>();
    final sessions = await prov.getSessionsByType(
      widget.habitId,
      RecoverySessionType.m4EnvironmentalRestructuring,
    );
    if (!mounted || sessions.isEmpty) return;
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final blocks = sessions.first.responseText.split('\n\n');
    for (var i = 0; i < blocks.length && i < _controllers.length; i++) {
      final block = blocks[i];
      final prefix = '${_cueTexts[i]}: ';
      if (block.startsWith(prefix)) {
        _controllers[i][0].text = block.substring(prefix.length);
      } else {
        final colonIdx = block.indexOf(': ');
        if (colonIdx >= 0) _controllers[i][0].text = block.substring(colonIdx + 2);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final list in _controllers) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  bool get _canSave =>
      _controllers.isNotEmpty &&
      _controllers.every((list) => list.any((c) => c.text.trim().isNotEmpty));

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final changes = <Map<String, dynamic>>[];
      for (int i = 0; i < _cueTexts.length; i++) {
        for (final ctrl in _controllers[i]) {
          final text = ctrl.text.trim();
          if (text.isNotEmpty) changes.add({'cue': _cueTexts[i], 'change': text});
        }
      }
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
            accentColor: MyWalkColor.bpCueMap,
          ),
        )),
      );
    }

    final alreadySaved = widget.environmentalChangesDone || _saved;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).padding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: MyWalkColor.surfaceOverlay,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: !alreadySaved,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                iconColor: _kRpPurple,
                collapsedIconColor: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                title: const Text(
                  'What changing your environment is about',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MyWalkColor.warmWhite),
                ),
                children: [
                  Text(
                    'Willpower is often weakest when you most need it. One way to change the situation is to change your environment or context so that the habit is harder and alternatives are easier. For each of the cues you identified earlier, we are going to record at least one concrete change you can make to increase the friction between cue and behaviour or more easily enable an alternative choice.',
                    style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                        height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Here are some examples to help you think of ideas:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 10),
                  _EnvExample(
                    label: 'Procrastination',
                    text: 'Work in designated spaces with minimal distraction; use website blockers during focus periods; make the first action on any task the smallest possible step (open the document; write one sentence).',
                  ),
                  _EnvExample(
                    label: 'Gambling',
                    text: 'Self-exclusion from gambling sites and physical venues; remove gambling apps; block gambling sites at the router level; give financial oversight to a trusted person during early recovery.',
                  ),
                  _EnvExample(
                    label: 'Alcohol',
                    text: 'Do not keep alcohol at home; identify two or three alcohol-free social alternatives; plan non-drinking responses for common social situations in advance.',
                  ),
                  _EnvExample(
                    label: 'Pornography',
                    text: 'Content filtering on devices, removing the habit browser from the home screen, device-free bedroom rule, support/accountability partner established.',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Let\'s now go through your cues and add concrete changes you will make.',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_cueTexts.isEmpty)
            Text('No triggers found — complete your cue map first.',
                style: TextStyle(
                    fontSize: 13,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.5)))
          else
            ...List.generate(_cueTexts.length, (i) =>
              _EnvCueSection(
                cueText: _cueTexts[i],
                controllers: _controllers[i],
                readOnly: false,
                onAdd: () => setState(() => _controllers[i].add(_makeCtrl())),
              )),
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
      ),
    );
  }
}

class _EnvExample extends StatelessWidget {
  final String label;
  final String text;
  const _EnvExample({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
              fontSize: 13,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
              height: 1.55),
          children: [
            TextSpan(
                text: '$label — ',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _kRpPurple)),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class _EnvCueSection extends StatelessWidget {
  final String cueText;
  final List<TextEditingController> controllers;
  final bool readOnly;
  final VoidCallback? onAdd;

  const _EnvCueSection({
    required this.cueText,
    required this.controllers,
    required this.readOnly,
    required this.onAdd,
  });

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
            child: Text(cueText,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kRpPurple)),
          ),
          const SizedBox(height: 10),
          const Text('What concrete change will you make?',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: MyWalkColor.warmWhite)),
          const SizedBox(height: 6),
          ...List.generate(controllers.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: controllers[i],
              readOnly: readOnly,
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
          )),
          Text(
            'Be specific — e.g. "delete the app" not "use my phone less"',
            style: TextStyle(
                fontSize: 11,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.38),
                fontStyle: FontStyle.italic),
          ),
          if (!readOnly && onAdd != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onAdd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 16, color: _kRpPurple.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'Add another concrete change',
                    style: TextStyle(
                        fontSize: 13,
                        color: _kRpPurple.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
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
        padding: EdgeInsets.fromLTRB(24, 32, 24, 32 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Build Your High Risk Situation (HRS) Coping Plans',
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
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).padding.bottom),
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
                total: _planControllers.length,
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
              icon: Icon(Icons.add_rounded, size: 17, color: _kRpPurple),
              label: const Text('Add another plan',
                  style: TextStyle(fontSize: 14, color: _kRpPurple, fontWeight: FontWeight.w600)),
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
  final int total;
  final _PlanControllers controllers;
  final VoidCallback? onRemove;

  const _PlanCard({
    required this.index,
    required this.total,
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
              Text('Plan ${widget.index + 1} of ${widget.total}',
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
              'This is a good time to consider setting up a support/accountability partner, if you haven\'t already.',
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

class _UrgeSurfingTab extends StatefulWidget {
  final String habitId;
  final String habitName;
  final bool urgeSurfingIntroSeen;

  const _UrgeSurfingTab({
    required this.habitId,
    required this.habitName,
    required this.urgeSurfingIntroSeen,
  });

  @override
  State<_UrgeSurfingTab> createState() => _UrgeSurfingTabState();
}

class _UrgeSurfingTabState extends State<_UrgeSurfingTab> {
  late Future<List<RecoverySession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _loadSessions();
  }

  Future<List<RecoverySession>> _loadSessions() =>
      context.read<RecoveryPathProvider>().getSessionsByType(
            widget.habitId,
            RecoverySessionType.m4UrgeSurfing,
          );

  void _refresh() => setState(() { _sessionsFuture = _loadSessions(); });

  Future<void> _openEntry(RecoverySession session) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => UrgeSurfedLogScreen(
        habitId: widget.habitId,
        habitName: widget.habitName,
        existingSession: session,
      ),
    ));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).padding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCollapsibleIntro(),
          const SizedBox(height: 28),
          _buildEntriesSection(),
        ],
      ),
    );
  }

  Widget _buildCollapsibleIntro() {
    return Container(
      decoration: BoxDecoration(
        color: MyWalkColor.surfaceOverlay,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: !widget.urgeSurfingIntroSeen,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: _kRpPurple,
          collapsedIconColor: MyWalkColor.warmWhite.withValues(alpha: 0.4),
          title: const Text(
            'Understand urge surfing',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite),
          ),
          children: [
            Text(
              'Urges are not commands. They are neurological events with a natural arc: they rise, peak (typically within 15–30 minutes), and subside — whether or not you act on them. Urge surfing is the practice of riding that arc rather than either acting on or suppressing the urge.',
              style: TextStyle(
                  fontSize: 13,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                  height: 1.65),
            ),
            const SizedBox(height: 12),
            Text(
              'Repeated urge surfing weakens the cue-response association over time and builds experiential confidence that urges do not require action.',
              style: TextStyle(
                  fontSize: 13,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                  height: 1.55),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: TextStyle(
                    fontSize: 13,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                    height: 1.55),
                children: [
                  const TextSpan(text: 'You can do this by tapping the \''),
                  const TextSpan(
                      text: 'Urge surfed',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(
                      text: '\' button on the practice card. You\'ll be asked to record what happened: what was the urge, how did it feel, did it rise and then decrease, and how long did that take.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'When an urge arises:',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 10),
            ...[
              ('1. Name it:', 'Say to yourself: \'I am having an urge to [behaviour].\' This is not permission — it is observation.'),
              ('2. Locate it:', 'Where in your body do you feel it? Chest, throat, stomach, hands? What is its shape and quality?'),
              ('3. Observe it:', 'Watch it intensify without acting. Notice whether it peaks and then diminishes. Track the arc.'),
              ('4. After it passes', '(or you choose to act on your coping plan): record what happened. Was the urge survivable?'),
            ].map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(item.$1,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kRpPurple.withValues(alpha: 0.9))),
                  ),
                  Expanded(
                    child: Text(item.$2,
                        style: TextStyle(
                            fontSize: 13,
                            color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                            height: 1.5)),
                  ),
                ],
              ),
            )),
            if (!widget.urgeSurfingIntroSeen) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await context
                        .read<RecoveryPathProvider>()
                        .markUrgeSurfingIntroSeen(widget.habitId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'The "Urge surfed" button will now appear on your habit card.'),
                          duration: const Duration(seconds: 3),
                          backgroundColor: _kRpPurple,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRpPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got it — I understand urge surfing',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAST SESSIONS',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
              letterSpacing: 0.8),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<RecoverySession>>(
          future: _sessionsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kRpPurple),
                ),
              );
            }
            final sessions = snap.data ?? [];
            if (sessions.isEmpty) {
              return Text(
                'No sessions logged yet. Use the "Urge surfed" button on your practice card to record one.',
                style: TextStyle(
                    fontSize: 13,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                    height: 1.5),
              );
            }
            return Column(
              children: sessions
                  .map((s) => _UrgeEntryRow(session: s, onTap: () => _openEntry(s)))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _UrgeEntryRow extends StatelessWidget {
  final RecoverySession session;
  final VoidCallback onTap;
  const _UrgeEntryRow({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(session.responseText) as Map<String, dynamic>;
    } catch (_) {}

    final trigger = (data['trigger'] as String?)?.trim() ?? '';
    final riseAndDecrease = data['riseAndDecrease'] as String?;
    final dateLabel = _formatDate(session.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: MyWalkColor.surfaceOverlay,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500),
                  ),
                  if (trigger.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      trigger,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          color: MyWalkColor.warmWhite,
                          height: 1.3),
                    ),
                  ],
                  if (riseAndDecrease != null) ...[
                    const SizedBox(height: 6),
                    _OutcomePill(outcome: riseAndDecrease),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'am' : 'pm';
    return '${dt.day} ${months[dt.month - 1]} · $hour:$minute$ampm';
  }
}

class _OutcomePill extends StatelessWidget {
  final String outcome;
  const _OutcomePill({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (outcome) {
      'faded' => ('Faded', MyWalkColor.sage),
      'still_going' => ('Still going', Colors.amber),
      _ => ('Not sure', _kRpPurple),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.9)),
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
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kRpPurple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kRpPurple.withValues(alpha: 0.18)),
      ),
      child: Text(
        'Your plans are built. When a high-risk moment arrives, you\'re executing a decision you already made — not improvising under pressure.',
        style: TextStyle(
            fontSize: 13,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
            height: 1.5),
      ),
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
                style: TextStyle(color: _kRpPurple, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
