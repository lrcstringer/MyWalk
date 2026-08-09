import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'weekly_compass_screen.dart';
import 'thought_examination_screen.dart';
import 'daily_check_in_screen.dart';
import 'mid_point_reflection_screen.dart';
import 'lifestyle_audit_screen.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../../domain/services/recovery_phase_calculator.dart';
import '../../providers/recovery_path_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import 'module_session_screen.dart';
import 'values_inventory_screen.dart';
import 'guardrails_screen.dart';
import 'record_a_moment_screen.dart';
import 'phase2_journey_screen.dart';
import 'recovery_letter_screen.dart';
import 'daily_check_in_modal.dart';

// Purple accent used throughout the Recovery Path UI.
const _kRpPurple = Color(0xFF8B7EC8);

class RecoveryPathHomeScreen extends StatefulWidget {
  final String habitId;
  final String habitName;

  const RecoveryPathHomeScreen({
    super.key,
    required this.habitId,
    required this.habitName,
  });

  @override
  State<RecoveryPathHomeScreen> createState() => _RecoveryPathHomeScreenState();
}

class _RecoveryPathHomeScreenState extends State<RecoveryPathHomeScreen> {
  int _logCount = 0;
  bool _checkInModalTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecoveryPathProvider>().loadPath(widget.habitId);
      _loadLogCount();
    });
  }

  void _maybeShowCheckInModal(RecoveryPathProvider prov) {
    if (_checkInModalTriggered) return;
    _checkInModalTriggered = true;
    final dayNumber = prov.dayNumberFor(widget.habitId);
    if (dayNumber % 3 != 0) return;
    if (prov.checkInDoneToday(widget.habitId)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDailyCheckInModal(
        context,
        habitId: widget.habitId,
        habitName: widget.habitName,
      );
    });
  }

  Future<void> _loadLogCount() async {
    final count = await context
        .read<RecoveryPathProvider>()
        .getBehaviourLogCount(widget.habitId);
    if (mounted) setState(() => _logCount = count);
  }

  Future<void> _begin() async {
    final prov = context.read<RecoveryPathProvider>();
    final hp = context.read<HabitProvider>();
    await prov.startPath(widget.habitId);
    if (!mounted) return;
    // Also mark habit as having a recovery path.
    final habit = hp.habits.where((h) => h.id == widget.habitId).firstOrNull;
    if (habit != null) {
      await hp.updateHabit(habit.copyWith(hasRecoveryPath: true));
    }
  }

  void _openModule(int moduleNumber) {
    final prov = context.read<RecoveryPathProvider>();
    final habitId = widget.habitId;

    switch (moduleNumber) {
      case 1:
        final checkInDone = prov.checkInDoneToday(habitId);
        if (!checkInDone) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DailyCheckInScreen(
              habitId: habitId,
              habitName: widget.habitName,
            ),
          ));
        } else {
          _showDoneSnack('Daily check-in already done — come back tomorrow.');
        }

      case 3:
        final path = prov.pathFor(habitId);
        final inventoryDone = path?.module3.valuesInventoryDone ?? false;
        final compassDone = prov.compassDoneThisWeek(habitId);

        if (!inventoryDone) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ValuesInventoryScreen(habitId: habitId),
          ));
        } else if (!compassDone) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WeeklyCompassScreen(habitId: habitId),
          ));
        } else {
          _showDoneSnack('Weekly compass done — check back next week.');
        }

      case 2:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ThoughtExaminationScreen(habitId: habitId),
        ));

      case 4:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GuardrailsScreen(
            habitId: habitId,
            habitName: widget.habitName,
          ),
        ));

      case 5:
        final path = prov.pathFor(habitId);
        final letterWritten = path?.module5.recoveryLetterWritten ?? false;
        if (!letterWritten) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RecoveryLetterScreen(habitId: habitId),
          ));
        } else {
          // Letter exists — offer quarterly review.
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ModuleSessionScreen(
              habitId: habitId,
              sessionType: RecoverySessionType.m5QuarterlyReview,
              moduleNumber: 5,
              title: RecoveryModuleContent.m5QuarterlyReviewTitle,
              prompts: RecoveryModuleContent.m5QuarterlyReviewPrompts,
              hint: RecoveryModuleContent.m5QuarterlyReviewHint,
            ),
          ));
        }
    }
  }

  void _openRecordAMoment() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RecordAMomentScreen(habitId: widget.habitId),
    ));
  }

  void _openPhase2JourneyView() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Phase2JourneyScreen(
        habitId: widget.habitId,
        habitName: widget.habitName,
      ),
    ));
  }

  void _openMidPointReflection() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MidPointReflectionScreen(habitId: widget.habitId),
    ));
  }

  void _openLifestyleAudit() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LifestyleAuditScreen(habitId: widget.habitId),
    ));
  }

  void _showDoneSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecoveryPathProvider>();
    final habitId = widget.habitId;
    final path = prov.pathFor(habitId);
    final isLoading = prov.isLoadingFor(habitId);
    final hasError = prov.errorFor(habitId) != null;
    final started = path != null;

    if (started && !isLoading) _maybeShowCheckInModal(prov);

    Widget body;
    if (isLoading) {
      body = const Center(child: CircularProgressIndicator(color: _kRpPurple));
    } else if (started) {
      body = _ActiveBody(
        habitId: habitId,
        habitName: widget.habitName,
        logCount: _logCount,
        prov: prov,
        onModuleTap: _openModule,
        onRecordAMoment: _openRecordAMoment,
        onPhase2Journey: _openPhase2JourneyView,
        onMidPointReflection: _openMidPointReflection,
        onLifestyleAudit: _openLifestyleAudit,
      );
    } else if (hasError) {
      // Load failed — show retry rather than "Begin" to prevent accidentally
      // overwriting an existing path that failed to load.
      body = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 40,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.25)),
              const SizedBox(height: 16),
              Text(
                'Couldn\'t load your Recovery Path.\nCheck your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                    height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => prov.loadPath(habitId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRpPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    } else {
      body = _BeginBody(onBegin: _begin);
    }

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Recovery Path',
          style: TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
        leading: const BackButton(color: MyWalkColor.warmWhite),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          body,
        ],
      ),
    );
  }
}

// ── Begin state ──────────────────────────────────────────────────────────────

class _BeginBody extends StatefulWidget {
  final Future<void> Function() onBegin;
  const _BeginBody({required this.onBegin});

  @override
  State<_BeginBody> createState() => _BeginBodyState();
}

class _BeginBodyState extends State<_BeginBody> {
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final userIsPremium = context.read<StoreProvider>().isPremium;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purple icon + title
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kRpPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.route_rounded, color: _kRpPurple, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            RecoveryModuleContent.homeBeginTitle,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.3),
          ),
          const SizedBox(height: 10),
          Text(
            RecoveryModuleContent.homeBeginBody,
            style: TextStyle(
                fontSize: 14,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                height: 1.5),
          ),
          const SizedBox(height: 28),

          // Module preview list
          ...RecoveryModuleContent.modules.map((m) => _ModulePreviewRow(
                meta: m,
                unlocked: true, // All shown as available before start
                isPremium: m.isPremium && !userIsPremium,
              )),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _starting
                  ? null
                  : () async {
                      setState(() => _starting = true);
                      try {
                        await widget.onBegin();
                      } catch (_) {
                        if (mounted) setState(() => _starting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _starting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      RecoveryModuleContent.homeBeginButton,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active state ─────────────────────────────────────────────────────────────

class _ActiveBody extends StatelessWidget {
  final String habitId;
  final String habitName;
  final int logCount;
  final RecoveryPathProvider prov;
  final void Function(int) onModuleTap;
  final VoidCallback onRecordAMoment;
  final VoidCallback onPhase2Journey;
  final VoidCallback onMidPointReflection;
  final VoidCallback onLifestyleAudit;

  const _ActiveBody({
    required this.habitId,
    required this.habitName,
    required this.logCount,
    required this.prov,
    required this.onModuleTap,
    required this.onRecordAMoment,
    required this.onPhase2Journey,
    required this.onMidPointReflection,
    required this.onLifestyleAudit,
  });

  // Phase 2 task helpers
  bool _phase2AllTasksDone(RecoveryPath path) =>
      path.cueHierarchyDone &&
      path.counterResponses.isNotEmpty &&
      path.environmentalChangesDone &&
      path.hrsPlanDone &&
      path.module5.recoveryLetterWritten;

  bool _phase2TaskInProgress(RecoveryPath path) =>
      (path.cueHierarchyDraftStage > 0 && !path.cueHierarchyDone) ||
      (path.thoughtExaminationDraftStep > 0 && path.counterResponses.isEmpty) ||
      (path.recoveryLetterDraft != null &&
          path.recoveryLetterDraft!.trim().isNotEmpty &&
          !path.module5.recoveryLetterWritten);

  String _currentPhase2TaskName(RecoveryPath path) {
    if (!path.cueHierarchyDone) return 'Map your cues';
    if (path.counterResponses.isEmpty) return 'Examine your thoughts';
    if (!path.environmentalChangesDone) return 'Change your environment';
    if (!path.hrsPlanDone) return 'Build your coping plans';
    return 'Write your recovery letter';
  }

  @override
  Widget build(BuildContext context) {
    final path = prov.pathFor(habitId)!;
    final phase = RecoveryPhaseCalculator.calculate(path);
    final day = prov.dayNumberFor(habitId);
    final compassDone = prov.compassDoneThisWeek(habitId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day / Phase header
          Text(
            'Day $day  ·  Phase $phase — ${RecoveryModuleContent.phaseLabel(phase)}',
            style: TextStyle(
                fontSize: 12,
                color: _kRpPurple.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 20),

          if (phase == 1) ..._buildPhase1(path, day),
          if (phase == 2) ..._buildPhase2(path, day, compassDone),
          if (phase == 3) ..._buildPhase3(path, day, compassDone),
          if (phase >= 4) ..._buildPhase4(path, day, compassDone),
        ],
      ),
    );
  }

  // ── Phase 1 ─────────────────────────────────────────────────────────────────

  List<Widget> _buildPhase1(RecoveryPath path, int day) => [
        _PrimaryButton(label: 'Record a moment', onTap: onRecordAMoment),
        if (day >= 8 && day <= 10 && !path.midPointReflectionDone) ...[
          const SizedBox(height: 10),
          _PillButton(
            label: 'Mid-Point Reflection',
            subtitle: 'Day 8–10 check-in',
            onTap: onMidPointReflection,
          ),
        ],
        if (logCount == 0 && day >= 5) ...[
          const SizedBox(height: 16),
          _NudgeCard(
            text: 'It\'s been a few days — how\'s it going? Have you had any moments to record?',
            buttonLabel: 'Record one now',
            onTap: onRecordAMoment,
          ),
        ],
      ];

  // ── Phase 2 ─────────────────────────────────────────────────────────────────

  List<Widget> _buildPhase2(RecoveryPath path, int day, bool compassDone) {
    final allDone = _phase2AllTasksDone(path);
    final inProgress = _phase2TaskInProgress(path);
    final taskName = _currentPhase2TaskName(path);
    return [
      if (!allDone)
        _PrimaryButton(
          label: inProgress ? 'Resume: $taskName' : 'Complete next task',
          onTap: onPhase2Journey,
        )
      else
        _QuietIndicator(label: 'Phase 3 begins at Day 30'),
      const SizedBox(height: 10),
      _PrimaryButton(
        label: 'Record a moment',
        onTap: onRecordAMoment,
        secondary: true,
      ),
      if (day >= 21 && !compassDone) ...[
        const SizedBox(height: 10),
        _PillButton(
          label: 'Values Compass',
          subtitle: 'Weekly check-in',
          onTap: () => onModuleTap(3),
        ),
      ],
    ];
  }

  // ── Phase 3 ─────────────────────────────────────────────────────────────────

  List<Widget> _buildPhase3(RecoveryPath path, int day, bool compassDone) {
    final letterWritten = path.module5.recoveryLetterWritten;
    final auditDue = prov.isLifestyleAuditDue(path);
    final weekNumber = day ~/ 7;
    final isReflectionWeek = day >= 14 && day % 14 == 0;
    return [
      if (!compassDone) ...[
        _PillButton(
          label: 'Values Compass',
          subtitle: 'Weekly',
          onTap: () => onModuleTap(3),
        ),
        const SizedBox(height: 10),
      ],
      if (auditDue) ...[
        _PillButton(
          label: 'Monthly Balance Check',
          subtitle: 'Monthly reflection',
          onTap: onLifestyleAudit,
        ),
        const SizedBox(height: 10),
      ],
      _PrimaryButton(label: 'Record a moment', onTap: onRecordAMoment, secondary: true),
      const SizedBox(height: 16),
      _EncouragementCard(weekNumber: weekNumber),
      if (isReflectionWeek) ...[
        const SizedBox(height: 10),
        _ReflectionPromptCard(day: day),
      ],
      const SizedBox(height: 10),
      _PlanAtAGlanceCard(
        phase: RecoveryPhaseCalculator.calculate(path),
        day: day,
        letterWritten: letterWritten,
        compassDone: compassDone,
      ),
    ];
  }

  // ── Phase 4 ─────────────────────────────────────────────────────────────────

  List<Widget> _buildPhase4(RecoveryPath path, int day, bool compassDone) {
    final quarterlyDue = prov.isQuarterlyReviewDue(path, day);
    return [
      ..._buildPhase3(path, day, compassDone),
      if (quarterlyDue) ...[
        const SizedBox(height: 10),
        _PillButton(
          label: 'Quarterly Review',
          subtitle: 'Every 90 days',
          onTap: () => onModuleTap(5),
        ),
      ],
    ];
  }
}

// ── Module preview row (begin state) ─────────────────────────────────────────

class _ModulePreviewRow extends StatelessWidget {
  final ModuleMeta meta;
  final bool unlocked;
  final bool isPremium;

  const _ModulePreviewRow({
    required this.meta,
    required this.unlocked,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(meta.icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(meta.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MyWalkColor.warmWhite)),
              if (isPremium) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: MyWalkColor.golden.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('PREMIUM',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.golden,
                          letterSpacing: 0.5)),
                ),
              ],
            ]),
            Text(meta.subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.45))),
          ]),
        ),
      ]),
    );
  }
}

// ── Phase-based Today card sub-widgets ────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool secondary;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary
              ? _kRpPurple.withValues(alpha: 0.18)
              : _kRpPurple,
          foregroundColor: MyWalkColor.warmWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kRpPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kRpPurple.withValues(alpha: 0.2), width: 0.75),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kRpPurple)),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 11,
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.4))),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 16, color: _kRpPurple.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }
}

class _NudgeCard extends StatelessWidget {
  final String text;
  final String buttonLabel;
  final VoidCallback onTap;

  const _NudgeCard({
    required this.text,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: MyWalkColor.warmCoral.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: MyWalkColor.warmCoral.withValues(alpha: 0.2), width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                  height: 1.5)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Text(buttonLabel,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kRpPurple.withValues(alpha: 0.9))),
          ),
        ],
      ),
    );
  }
}

class _QuietIndicator extends StatelessWidget {
  final String label;
  const _QuietIndicator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MyWalkColor.sage.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(Icons.check_circle_rounded,
            size: 14, color: MyWalkColor.sage.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.55))),
      ]),
    );
  }
}

class _EncouragementCard extends StatelessWidget {
  final int weekNumber;
  const _EncouragementCard({required this.weekNumber});

  @override
  Widget build(BuildContext context) {
    final messages = RecoveryModuleContent.phase3EncouragementMessages;
    final msg = messages[weekNumber % messages.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kRpPurple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRpPurple.withValues(alpha: 0.15), width: 0.75),
      ),
      child: Text(
        msg,
        style: TextStyle(
            fontSize: 13,
            color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
            height: 1.55,
            fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _ReflectionPromptCard extends StatelessWidget {
  final int day;
  const _ReflectionPromptCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final prompts = RecoveryModuleContent.phase3ReflectionPrompts;
    final prompt = prompts[(day ~/ 14) % prompts.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyWalkColor.sage.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyWalkColor.sage.withValues(alpha: 0.18), width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fortnightly reflection',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.sage.withValues(alpha: 0.8),
                  letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Text(prompt,
              style: TextStyle(
                  fontSize: 13,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                  height: 1.5)),
        ],
      ),
    );
  }
}

class _PlanAtAGlanceCard extends StatelessWidget {
  final int phase;
  final int day;
  final bool letterWritten;
  final bool compassDone;

  const _PlanAtAGlanceCard({
    required this.phase,
    required this.day,
    required this.letterWritten,
    required this.compassDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyWalkColor.cardBorder, width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your plan at a glance',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kRpPurple.withValues(alpha: 0.8),
                  letterSpacing: 0.3)),
          const SizedBox(height: 8),
          _GlanceRow(
              label: 'Phase',
              value: 'Phase $phase — ${RecoveryModuleContent.phaseLabel(phase)}'),
          _GlanceRow(label: 'Day', value: 'Day $day'),
          _GlanceRow(
              label: 'Recovery letter',
              value: letterWritten ? 'Written' : 'Not yet written'),
          _GlanceRow(
              label: 'Compass this week',
              value: compassDone ? 'Done' : 'Not yet'),
        ],
      ),
    );
  }
}

class _GlanceRow extends StatelessWidget {
  final String label;
  final String value;
  const _GlanceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.4))),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.7))),
        ),
      ]),
    );
  }
}
