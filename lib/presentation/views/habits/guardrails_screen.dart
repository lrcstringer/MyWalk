import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'module_session_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// Module 4 — Build Your Guardrails.
/// Three tabs: Environmental Checklist, HRS Plans, Urge Surfing.
class GuardrailsScreen extends StatefulWidget {
  final String habitId;
  final String habitName;

  const GuardrailsScreen({
    super.key,
    required this.habitId,
    required this.habitName,
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
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = context.watch<RecoveryPathProvider>().pathFor(widget.habitId);

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
            Tab(text: 'Guardrails'),
            Tab(text: 'HRS Plans'),
            Tab(text: 'Urge Surfing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ChecklistTab(
            habitId: widget.habitId,
            habitName: widget.habitName,
            done: path?.module4.environmentalChecklistDone ?? false,
          ),
          _HrsPlanTab(
            habitId: widget.habitId,
            existingPlans: path?.module4.hrsPlan ?? [],
          ),
          _UrgeSurfingTab(habitId: widget.habitId),
        ],
      ),
    );
  }
}

// ── Checklist tab ─────────────────────────────────────────────────────────────

class _ChecklistTab extends StatefulWidget {
  final String habitId;
  final String habitName;
  final bool done;

  const _ChecklistTab({
    required this.habitId,
    required this.habitName,
    required this.done,
  });

  @override
  State<_ChecklistTab> createState() => _ChecklistTabState();
}

class _ChecklistTabState extends State<_ChecklistTab> {
  late List<String> _items;
  late List<bool> _checked;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = RecoveryModuleContent.environmentalChecklistFor(widget.habitName);
    _checked = List.filled(_items.length, false);
  }

  int get _doneCount => _checked.where((v) => v).length;

  Future<void> _save() async {
    setState(() => _saving = true);
    await context
        .read<RecoveryPathProvider>()
        .markEnvironmentalChecklistDone(widget.habitId);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guardrails saved.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.done)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: MyWalkColor.sage.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: MyWalkColor.sage),
                const SizedBox(width: 8),
                Text('Guardrails marked as done.',
                    style: TextStyle(
                        fontSize: 12,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.7))),
              ]),
            ),
          Text(
            RecoveryModuleContent.m4ChecklistBody,
            style: TextStyle(
                fontSize: 13,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                height: 1.5),
          ),
          const SizedBox(height: 20),
          ..._items.asMap().entries.map((e) {
            return CheckboxListTile(
              value: _checked[e.key],
              onChanged: (v) => setState(() => _checked[e.key] = v ?? false),
              title: Text(e.value,
                  style: const TextStyle(
                      fontSize: 13, color: MyWalkColor.warmWhite)),
              activeColor: _kRpPurple,
              checkColor: Colors.white,
              side: BorderSide(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.2)),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_doneCount >= 2 && !_saving && !widget.done)
                  ? _save
                  : null,
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
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _doneCount < 2
                          ? 'Check at least 2 items to continue'
                          : widget.done
                              ? 'Already saved'
                              : 'Mark guardrails as done',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HRS Plan tab ──────────────────────────────────────────────────────────────

class _HrsPlanTab extends StatefulWidget {
  final String habitId;
  final List<HrsPlan> existingPlans;

  const _HrsPlanTab({
    required this.habitId,
    required this.existingPlans,
  });

  @override
  State<_HrsPlanTab> createState() => _HrsPlanTabState();
}

class _HrsPlanTabState extends State<_HrsPlanTab> {
  late List<_PlanControllers> _planControllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Seed from existing plans, always show at least one blank.
    _planControllers = widget.existingPlans.isEmpty
        ? [_PlanControllers.blank()]
        : widget.existingPlans.map(_PlanControllers.fromPlan).toList();
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
    await context.read<RecoveryPathProvider>().saveHrsPlan(widget.habitId, plans);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plans saved.'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    ? () => setState(() => _planControllers.removeAt(e.key))
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
                      width: 18, height: 18,
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

class _PlanCard extends StatelessWidget {
  final int index;
  final _PlanControllers controllers;
  final VoidCallback? onRemove;

  const _PlanCard({
    required this.index,
    required this.controllers,
    this.onRemove,
  });

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
              Text('Plan ${index + 1}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kRpPurple.withValues(alpha: 0.8))),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(Icons.close_rounded,
                      size: 16,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _PlanField(
            label: RecoveryModuleContent.m4SituationLabel,
            controller: controllers.situation,
          ),
          _PlanField(
            label: RecoveryModuleContent.m4EarlyWarningsLabel,
            controller: controllers.earlyWarnings,
          ),
          _PlanField(
            label: RecoveryModuleContent.m4FirstResponseLabel,
            controller: controllers.firstResponse,
          ),
          _PlanField(
            label: RecoveryModuleContent.m4ContactNameLabel,
            controller: controllers.contactName,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _PlanField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool last;

  const _PlanField({
    required this.label,
    required this.controller,
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
            style: const TextStyle(
                color: MyWalkColor.warmWhite, fontSize: 13),
            maxLines: 2,
            decoration: InputDecoration(
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

// ── Urge Surfing tab ──────────────────────────────────────────────────────────

class _UrgeSurfingTab extends StatelessWidget {
  final String habitId;
  const _UrgeSurfingTab({required this.habitId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Urges are waves. They peak and pass — usually within 20 minutes. '
            'Use this guided session to ride the wave without acting on it.',
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
