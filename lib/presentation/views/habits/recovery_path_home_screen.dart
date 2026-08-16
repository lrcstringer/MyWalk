import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mid_point_reflection_screen.dart';
import 'lifestyle_audit_screen.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../../domain/services/recovery_phase_calculator.dart';
import '../../providers/recovery_path_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import 'module_session_screen.dart';
import 'values_inventory_screen.dart';
import 'record_a_moment_screen.dart';
import 'my_freedom_plan_screen.dart';
import 'phase_transition_screen.dart';
import 'daily_check_in_modal.dart';
import '../journal/freedom_journey_tab.dart';

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
  // -1 = not yet loaded (sentinel so we don't queue dialogs before async data arrives)
  int _daysSinceLastLog = -1;
  bool _dialogsQueued = false;
  bool _phaseTransitionDispatched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecoveryPathProvider>().loadPath(widget.habitId);
      _loadDaysSinceLastLog();
    });
  }

  // ── Dialog queue ─────────────────────────────────────────────────────────────

  /// Collects every due prompt for this session and shows them sequentially.
  /// Runs at most once per screen load (guarded by [_dialogsQueued]).
  /// Only called after [_daysSinceLastLog] has been resolved (>= 0).
  void _maybeQueueDialogs(
      RecoveryPathProvider prov, RecoveryPath path, int phase) {
    if (_dialogsQueued) return;
    _dialogsQueued = true;

    final day = prov.dayNumberFor(widget.habitId);
    final queue = <Future<void> Function()>[];

    // 1. Daily check-in (every 3rd day)
    if (day % 3 == 0 && !prov.checkInDoneToday(widget.habitId)) {
      queue.add(() => showDailyCheckInDialog(
            context,
            habitId: widget.habitId,
            habitName: widget.habitName,
          ));
    }

    // 2. Mid-point reflection (phase 1, days 8–10)
    if (phase == 1 && day >= 8 && day <= 10 && !path.midPointReflectionDone) {
      queue.add(() => _showRpDialog(
            title: 'Mid-Point Reflection',
            body: 'You\'re around day 8–10 of your path. A good moment to step back and reflect on what\'s been coming up so far.',
            actionLabel: 'Reflect now',
            onAction: _openMidPointReflection,
          ));
    }

    // 3. 5-day no-log nudge (phase 1)
    if (phase == 1 && _daysSinceLastLog >= 5) {
      queue.add(() => _showRpDialog(
            title: 'How\'s it going?',
            body: 'It\'s been a few days since you recorded a moment. If you\'ve had any situations come up, now is a good time to capture them.',
            actionLabel: 'Record one now',
            dismissLabel: 'Skip',
            onAction: _openRecordAMoment,
          ));
    }

    // 4. Monthly balance check (phase 3+, every 30 days)
    if (phase >= 3 && prov.isLifestyleAuditDue(path)) {
      queue.add(() => _showRpDialog(
            title: 'Monthly Balance Check',
            body: 'It\'s time for your monthly check-in on the broader picture — sleep, relationships, stress, and the areas of life beyond the pattern.',
            actionLabel: 'Begin check-in',
            onAction: _openLifestyleAudit,
          ));
    }

    // 5. Fortnightly reflection (phase 3+, every 14 days from day 14)
    if (phase >= 3 && day >= 14 && day % 14 == 0) {
      final prompts = RecoveryModuleContent.phase3ReflectionPrompts;
      final prompt = prompts[(day ~/ 14) % prompts.length];
      queue.add(() => _showRpDialog(
            title: 'Fortnightly Reflection',
            body: prompt,
            actionLabel: 'Open Freedom Journey',
            dismissLabel: 'Skip',
            onAction: _openFreedomJourneyTab,
          ));
    }

    // 6. Quarterly review (phase 4, at days 90 / 180 / 270 / 360)
    if (phase >= 4 && prov.isQuarterlyReviewDue(path, day)) {
      queue.add(() => _showRpDialog(
            title: 'Quarterly Review',
            body: 'Every 90 days, it\'s worth sitting with your recovery letter and reflecting on where you are now. This is a considered reflection, not a quick check-in.',
            actionLabel: 'Begin review',
            onAction: _openQuarterlyReview,
          ));
    }

    if (queue.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final show in queue) {
        if (!mounted) return;
        await show();
      }
    });
  }

  /// Shared styled dialog for all announcement-style prompts.
  Future<void> _showRpDialog({
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
    String dismissLabel = 'Later',
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: MyWalkColor.warmWhite,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      dismissLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onAction();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRpPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Phase transitions ────────────────────────────────────────────────────────

  void _maybeShowPhaseTransition(
      RecoveryPathProvider prov, RecoveryPath path, int phase) {
    if (_phaseTransitionDispatched) return;

    if (phase == 2 && !path.phase2TransitionShown) {
      _phaseTransitionDispatched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await prov.markPhase2TransitionShown(widget.habitId);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PhaseTransitionScreen(
            fromPhase: 1,
            toPhase: 2,
            habitId: widget.habitId,
            habitName: widget.habitName,
          ),
        ));
      });
    } else if (phase >= 4 && !path.phase4TransitionShown) {
      _phaseTransitionDispatched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await prov.markPhase4TransitionShown(widget.habitId);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PhaseTransitionScreen(
            fromPhase: 3,
            toPhase: 4,
            habitId: widget.habitId,
            habitName: widget.habitName,
          ),
        ));
      });
    }
  }

  // ── Navigation helpers ───────────────────────────────────────────────────────

  void _openFreedomJourneyTab() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: MyWalkColor.charcoal,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Freedom Journey',
            style: TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 17,
                fontWeight: FontWeight.w600),
          ),
          leading: const BackButton(color: MyWalkColor.warmWhite),
        ),
        body: Stack(children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          FreedomJourneyTab(habitId: widget.habitId),
        ]),
      ),
    ));
  }

  Future<void> _loadDaysSinceLastLog() async {
    final lastDate = await context
        .read<RecoveryPathProvider>()
        .getLastBehaviourLogDate(widget.habitId);
    if (!mounted) return;
    final days = lastDate == null
        ? 999
        : DateTime.now().difference(lastDate).inDays;
    setState(() => _daysSinceLastLog = days);
  }

  Future<void> _begin() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ValuesInventoryScreen(
          habitId: widget.habitId,
          habitName: widget.habitName,
          setupMode: true,
          wantsRecoveryPath: true,
          accentColor: MyWalkColor.bpValues,
        ),
      ),
    );
  }

  void _openQuarterlyReview() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ModuleSessionScreen(
        habitId: widget.habitId,
        sessionType: RecoverySessionType.m5QuarterlyReview,
        moduleNumber: 5,
        title: RecoveryModuleContent.m5QuarterlyReviewTitle,
        prompts: RecoveryModuleContent.m5QuarterlyReviewPrompts,
        hint: RecoveryModuleContent.m5QuarterlyReviewHint,
      ),
    ));
  }

  void _openRecordAMoment() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RecordAMomentScreen(habitId: widget.habitId),
    ));
  }

  void _openPhase2JourneyView() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MyFreedomPlanScreen(
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

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecoveryPathProvider>();
    final habitId = widget.habitId;
    final path = prov.pathFor(habitId);
    final isLoading = prov.isLoadingFor(habitId);
    final hasError = prov.errorFor(habitId) != null;
    final started = path != null && path.planActive;

    if (started && !isLoading && _daysSinceLastLog >= 0) {
      final phase = RecoveryPhaseCalculator.calculate(path);
      _maybeQueueDialogs(prov, path, phase);
      _maybeShowPhaseTransition(prov, path, phase);
    }

    Widget body;
    if (isLoading) {
      body = const Center(child: CircularProgressIndicator(color: _kRpPurple));
    } else if (started) {
      body = _ActiveBody(
        habitId: habitId,
        habitName: widget.habitName,
        prov: prov,
        onRecordAMoment: _openRecordAMoment,
        onPhase2Journey: _openPhase2JourneyView,
        onFreedomJourney: _openFreedomJourneyTab,
      );
    } else if (hasError) {
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
      padding: EdgeInsets.fromLTRB(20, 8, 20, 40 + MediaQuery.of(context).padding.bottom),
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
                unlocked: true,
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
  final RecoveryPathProvider prov;
  final VoidCallback onRecordAMoment;
  final VoidCallback onPhase2Journey;
  final VoidCallback onFreedomJourney;

  const _ActiveBody({
    required this.habitId,
    required this.habitName,
    required this.prov,
    required this.onRecordAMoment,
    required this.onPhase2Journey,
    required this.onFreedomJourney,
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
      padding: EdgeInsets.fromLTRB(20, 16, 20, 40 + MediaQuery.of(context).padding.bottom),
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

          if (phase == 1) ..._buildPhase1(path),
          if (phase == 2) ..._buildPhase2(path),
          if (phase == 3) ..._buildPhase3(path, day, compassDone),
          if (phase >= 4) ..._buildPhase4(path, day, compassDone),
        ],
      ),
    );
  }

  // ── Phase 1 ─────────────────────────────────────────────────────────────────

  List<Widget> _buildPhase1(RecoveryPath path) => [
        _PrimaryButton(label: 'Record a moment', onTap: onRecordAMoment),
      ];

  // ── Phase 2 ─────────────────────────────────────────────────────────────────

  List<Widget> _buildPhase2(RecoveryPath path) {
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
    ];
  }

  // ── Phase 3 ─────────────────────────────────────────────────────────────────

  List<Widget> _buildPhase3(RecoveryPath path, int day, bool compassDone) {
    final letterWritten = path.module5.recoveryLetterWritten;
    final weekNumber = day ~/ 7;
    return [
      _PrimaryButton(label: 'Record a moment', onTap: onRecordAMoment, secondary: true),
      const SizedBox(height: 16),
      _EncouragementCard(weekNumber: weekNumber),
      const SizedBox(height: 10),
      _PlanAtAGlanceCard(
        phase: RecoveryPhaseCalculator.calculate(path),
        day: day,
        letterWritten: letterWritten,
        compassDone: compassDone,
        onTap: onFreedomJourney,
      ),
    ];
  }

  // ── Phase 4 ─────────────────────────────────────────────────────────────────

  List<Widget> _buildPhase4(RecoveryPath path, int day, bool compassDone) {
    return [
      ..._buildPhase3(path, day, compassDone),
      const SizedBox(height: 10),
      _ReviewJourneyCard(onTap: onFreedomJourney),
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

// ── Shared UI widgets ────────────────────────────────────────────────────────

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

class _PlanAtAGlanceCard extends StatelessWidget {
  final int phase;
  final int day;
  final bool letterWritten;
  final bool compassDone;
  final VoidCallback onTap;

  const _PlanAtAGlanceCard({
    required this.phase,
    required this.day,
    required this.letterWritten,
    required this.compassDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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

class _ReviewJourneyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ReviewJourneyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kRpPurple.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kRpPurple.withValues(alpha: 0.2), width: 0.75),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tap to review your journey',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kRpPurple)),
                const SizedBox(height: 2),
                Text(
                  'Freedom Journey tab · persistent',
                  style: TextStyle(
                      fontSize: 11,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.4)),
                ),
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
