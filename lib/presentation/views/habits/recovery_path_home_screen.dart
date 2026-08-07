import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'weekly_compass_screen.dart';
import 'thought_examination_screen.dart';
import 'daily_check_in_screen.dart';
import 'mid_point_reflection_screen.dart';
import 'cue_hierarchy_screen.dart';
import 'environmental_restructuring_screen.dart';
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
import 'lapse_recording_flow.dart';
import 'recovery_letter_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecoveryPathProvider>().loadPath(widget.habitId);
      _loadLogCount();
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
        final path = prov.pathFor(habitId);
        final canDoWeeklyReview = (path?.module1.dailyCheckInCount ?? 0) >= 7;

        if (!checkInDone) {
          final prompts =
              RecoveryModuleContent.dailyPromptsForDate(DateTime.now());
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ModuleSessionScreen(
              habitId: habitId,
              sessionType: RecoverySessionType.m1DailyCheckIn,
              moduleNumber: 1,
              title: RecoveryModuleContent.m1CheckInTitle,
              prompts: prompts,
              hint: RecoveryModuleContent.m1CheckInHint,
            ),
          ));
        } else if (canDoWeeklyReview) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ModuleSessionScreen(
              habitId: habitId,
              sessionType: RecoverySessionType.m1WeeklyReview,
              moduleNumber: 1,
              title: RecoveryModuleContent.m1WeeklyReviewTitle,
              prompts: RecoveryModuleContent.m1WeeklyReviewPrompts,
              hint: RecoveryModuleContent.m1CheckInHint,
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

  void _openLapseFlow() {
    final prov = context.read<RecoveryPathProvider>();
    if (!prov.isModuleUnlocked(widget.habitId, 5)) {
      prov.markModule5IntroSeen(widget.habitId).ignore();
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LapseRecordingFlow(habitId: widget.habitId),
    ));
  }

  void _openDailyCheckIn() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DailyCheckInScreen(
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

  void _openCueHierarchy() {
    final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CueHierarchyScreen(
        habitId: widget.habitId,
        habitName: widget.habitName,
        habitType: path?.habitType ?? '',
      ),
    ));
  }

  void _openEnvironmentalRestructuring() {
    final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EnvironmentalRestructuringScreen(
        habitId: widget.habitId,
        habitType: path?.habitType ?? '',
      ),
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
        onLapseTap: _openLapseFlow,
        onDailyCheckIn: _openDailyCheckIn,
        onMidPointReflection: _openMidPointReflection,
        onCueHierarchy: _openCueHierarchy,
        onEnvironmentalRestructuring: _openEnvironmentalRestructuring,
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

class _ActionCard {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _ActiveBody extends StatelessWidget {
  final String habitId;
  final String habitName;
  final int logCount;
  final RecoveryPathProvider prov;
  final void Function(int) onModuleTap;
  final VoidCallback onLapseTap;
  final VoidCallback onDailyCheckIn;
  final VoidCallback onMidPointReflection;
  final VoidCallback onCueHierarchy;
  final VoidCallback onEnvironmentalRestructuring;
  final VoidCallback onLifestyleAudit;

  const _ActiveBody({
    required this.habitId,
    required this.habitName,
    required this.logCount,
    required this.prov,
    required this.onModuleTap,
    required this.onLapseTap,
    required this.onDailyCheckIn,
    required this.onMidPointReflection,
    required this.onCueHierarchy,
    required this.onEnvironmentalRestructuring,
    required this.onLifestyleAudit,
  });

  List<_ActionCard> _pendingActions(
    RecoveryPath path,
    int day,
    bool checkInDone,
    bool compassDone,
  ) {
    final actions = <_ActionCard>[];

    if (!checkInDone) {
      actions.add(_ActionCard(
        title: 'Daily check-in',
        subtitle: 'Takes 30 seconds',
        onTap: onDailyCheckIn,
      ));
    }
    if (day >= 8 && day <= 10 && !path.midPointReflectionDone) {
      actions.add(_ActionCard(
        title: 'Mid-point reflection',
        subtitle: 'How are things going so far?',
        onTap: onMidPointReflection,
      ));
    }
    if (day >= 14 && !path.cueHierarchyDone && logCount >= 5) {
      actions.add(_ActionCard(
        title: 'Build your cue map',
        subtitle: 'Your logs are ready — this is a big step.',
        onTap: onCueHierarchy,
      ));
    }
    if (path.module3.valuesInventoryDone && !compassDone) {
      actions.add(_ActionCard(
        title: 'Weekly values compass',
        subtitle: 'A 5-minute check-in',
        onTap: () => onModuleTap(3),
      ));
    }
    if (path.cueHierarchyDone && !path.environmentalChangesDone) {
      actions.add(_ActionCard(
        title: 'Change your environment',
        subtitle: 'Use your cue map to make concrete changes',
        onTap: onEnvironmentalRestructuring,
      ));
    }
    if (path.environmentalChangesDone && !path.hrsPlanDone) {
      actions.add(_ActionCard(
        title: 'Build your coping plans',
        subtitle: 'One plan per trigger — pre-made, ready to use',
        onTap: () => onModuleTap(4),
      ));
    }
    if (RecoveryPhaseCalculator.isModuleUnlocked(path, 5) &&
        !path.module5.recoveryLetterWritten) {
      actions.add(_ActionCard(
        title: 'Write your recovery letter',
        subtitle: 'Do this while you\'re clear-headed',
        onTap: () => onModuleTap(5),
      ));
    }
    if (day >= 30 && prov.isLifestyleAuditDue(path)) {
      actions.add(_ActionCard(
        title: 'Monthly balance check',
        subtitle: 'What\'s taking from you? What\'s nourishing you?',
        onTap: onLifestyleAudit,
      ));
    }
    if (prov.isQuarterlyReviewDue(path, day)) {
      actions.add(_ActionCard(
        title: 'Quarterly review',
        subtitle: 'Reflect on how far you\'ve come',
        onTap: () => onModuleTap(5),
      ));
    }

    return actions.take(2).toList();
  }

  String? _nextStep(int moduleNumber, RecoveryPath path, int day) {
    if (moduleNumber == 1 && !path.cueHierarchyDone && logCount >= 5 && day >= 14) {
      return 'Your next step: Build your cue map';
    }
    if (moduleNumber == 3 && !path.module3.valuesInventoryDone) {
      return 'Your next step: Complete your values inventory';
    }
    if (moduleNumber == 4 && !path.environmentalChangesDone) {
      return 'Your next step: Map your environmental changes';
    }
    if (moduleNumber == 4 && path.environmentalChangesDone && !path.hrsPlanDone) {
      return 'Your next step: Build your coping plans';
    }
    if (moduleNumber == 5 && !path.module5.recoveryLetterWritten) {
      return 'Your next step: Write your recovery letter';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final path = prov.pathFor(habitId)!;
    final phase = RecoveryPhaseCalculator.calculate(path);
    final day = prov.dayNumberFor(habitId);
    final checkInDone = prov.checkInDoneToday(habitId);
    final compassDone = prov.compassDoneThisWeek(habitId);
    final inventoryDone = path.module3.valuesInventoryDone;
    final pending = _pendingActions(path, day, checkInDone, compassDone);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day/Phase header
          Text(
            'Day $day  ·  Phase $phase — ${RecoveryModuleContent.phaseLabel(phase)}',
            style: TextStyle(
                fontSize: 12,
                color: _kRpPurple.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 14),

          // Pending action cards (up to 2) or all-caught-up
          if (pending.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MyWalkColor.sage.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: MyWalkColor.sage),
                const SizedBox(width: 10),
                Text("You're all caught up today",
                    style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.7))),
              ]),
            )
          else
            ...pending.map((card) => GestureDetector(
                  onTap: card.onTap,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kRpPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _kRpPurple.withValues(alpha: 0.25), width: 0.75),
                    ),
                    child: Row(children: [
                      const Icon(Icons.wb_sunny_rounded,
                          size: 16, color: _kRpPurple),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card.title,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: MyWalkColor.warmWhite)),
                              const SizedBox(height: 2),
                              Text(card.subtitle,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: MyWalkColor.warmWhite
                                          .withValues(alpha: 0.5))),
                            ]),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: _kRpPurple),
                    ]),
                  ),
                )),

          const SizedBox(height: 22),

          // Module cards
          const Text('Modules',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.warmWhite,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),

          ...RecoveryModuleContent.modules.map((m) {
            final unlocked =
                RecoveryPhaseCalculator.isModuleUnlocked(path, m.number);
            return _ModuleCard(
              meta: m,
              unlocked: unlocked,
              checkInCount: m.number == 1 ? path.module1.dailyCheckInCount : null,
              inventoryDone: m.number == 3 ? inventoryDone : null,
              nextStep: unlocked ? _nextStep(m.number, path, day) : null,
              onTap: unlocked ? () => onModuleTap(m.number) : null,
            );
          }),

          const SizedBox(height: 8),

          // Lapse entry
          TextButton.icon(
            onPressed: onLapseTap,
            icon: Icon(Icons.refresh_rounded,
                size: 14,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.25)),
            label: const Text(
              'I had a moment',
              style: TextStyle(
                  fontSize: 12,
                  color: MyWalkColor.warmWhite),
            ),
          ),
        ],
      ),
    );
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

// ── Module card (active state) ────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final ModuleMeta meta;
  final bool unlocked;
  final int? checkInCount;
  final bool? inventoryDone;
  final String? nextStep;
  final VoidCallback? onTap;

  const _ModuleCard({
    required this.meta,
    required this.unlocked,
    this.checkInCount,
    this.inventoryDone,
    this.nextStep,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dimmed = !unlocked;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: unlocked
                  ? _kRpPurple.withValues(alpha: 0.2)
                  : MyWalkColor.cardBorder,
              width: 0.75),
        ),
        child: Row(children: [
          Text(meta.icon,
              style: TextStyle(
                  fontSize: 20,
                  color: dimmed ? Colors.white24 : null)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: dimmed
                            ? MyWalkColor.warmWhite.withValues(alpha: 0.3)
                            : MyWalkColor.warmWhite),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(),
                    style: TextStyle(
                        fontSize: 11,
                        color: dimmed
                            ? MyWalkColor.warmWhite.withValues(alpha: 0.2)
                            : MyWalkColor.warmWhite.withValues(alpha: 0.5)),
                  ),
                ]),
          ),
          if (!unlocked)
            Icon(Icons.lock_rounded,
                size: 14,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.2))
          else
            Icon(Icons.chevron_right_rounded,
                size: 16,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
        ]),
      ),
    );
  }

  String _subtitle() {
    if (!unlocked) return meta.subtitle;
    if (nextStep != null) return nextStep!;
    if (checkInCount != null) return '${checkInCount!} check-ins logged';
    if (inventoryDone != null) {
      return inventoryDone! ? 'Values inventory done' : 'Values inventory not yet done';
    }
    return meta.subtitle;
  }
}
