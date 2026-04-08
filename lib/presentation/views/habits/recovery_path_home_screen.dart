import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_module_content.dart';
import '../../../domain/services/recovery_phase_calculator.dart';
import '../../providers/recovery_path_provider.dart';
import '../../providers/habit_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecoveryPathProvider>().loadPath(widget.habitId);
    });
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
            builder: (_) => ModuleSessionScreen(
              habitId: habitId,
              sessionType: RecoverySessionType.m3WeeklyCompass,
              moduleNumber: 3,
              title: RecoveryModuleContent.m3CompassTitle,
              prompts: RecoveryModuleContent.m3WeeklyCompassPrompts,
              hint: RecoveryModuleContent.m3CompassHint,
            ),
          ));
        } else {
          _showDoneSnack('Weekly compass done — check back next week.');
        }

      case 2:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ModuleSessionScreen(
            habitId: habitId,
            sessionType: RecoverySessionType.m2ThoughtExamination,
            moduleNumber: 2,
            title: RecoveryModuleContent.m2Title,
            prompts: RecoveryModuleContent.m2ThoughtExaminationPrompts,
            hint: RecoveryModuleContent.m2Hint,
            onSaved: (responseText) async {
              // Extract the last answer (counter-response) and offer to save it.
              final lastAnswer = responseText
                  .split('\n\n')
                  .lastOrNull
                  ?.split('\n')
                  .skip(1)
                  .join('\n')
                  .trim();
              if (lastAnswer == null || lastAnswer.isEmpty) return;
              if (!mounted) return;
              final save = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: MyWalkColor.cardBackground,
                  title: const Text(
                    'Save to library?',
                    style: TextStyle(
                        color: MyWalkColor.warmWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  content: Text(
                    '"$lastAnswer"',
                    style: TextStyle(
                        fontSize: 13,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text('Skip',
                          style: TextStyle(
                              color: MyWalkColor.warmWhite.withValues(alpha: 0.4))),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Save',
                          style: TextStyle(color: _kRpPurple)),
                    ),
                  ],
                ),
              );
              if (save == true && mounted) {
                await context
                    .read<RecoveryPathProvider>()
                    .addCounterResponse(habitId, lastAnswer);
              }
            },
          ),
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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LapseRecordingFlow(habitId: widget.habitId),
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
        prov: prov,
        onModuleTap: _openModule,
        onLapseTap: _openLapseFlow,
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
      body: body,
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
                isPremium: m.isPremium,
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
  final void Function(int) onModuleTap;
  final VoidCallback onLapseTap;

  const _ActiveBody({
    required this.habitId,
    required this.habitName,
    required this.prov,
    required this.onModuleTap,
    required this.onLapseTap,
  });

  @override
  Widget build(BuildContext context) {
    final path = prov.pathFor(habitId)!;
    final phase = RecoveryPhaseCalculator.calculate(path);
    final day = prov.dayNumberFor(habitId);
    final checkInDone = prov.checkInDoneToday(habitId);
    final compassDone = prov.compassDoneThisWeek(habitId);
    final inventoryDone = path.module3.valuesInventoryDone;

    // Today's focus: first thing still pending
    final String? focusLabel;
    final int? focusModule;
    if (!checkInDone) {
      focusLabel = 'Daily check-in (Module 1)';
      focusModule = 1;
    } else if (!inventoryDone) {
      focusLabel = 'Values inventory (Module 3)';
      focusModule = 3;
    } else if (!compassDone) {
      focusLabel = 'Weekly compass (Module 3)';
      focusModule = 3;
    } else {
      focusLabel = null;
      focusModule = null;
    }

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

          // Today's focus card
          if (focusLabel != null)
            GestureDetector(
              onTap: () => onModuleTap(focusModule!),
              child: Container(
                width: double.infinity,
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
                          const Text("Today's focus",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _kRpPurple,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(focusLabel,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: MyWalkColor.warmWhite)),
                        ]),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: _kRpPurple),
                ]),
              ),
            )
          else
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
            ),

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
                RecoveryPhaseCalculator.isModuleUnlocked(m.number, phase);
            return _ModuleCard(
              meta: m,
              unlocked: unlocked,
              isPremium: m.isPremium,
              checkInCount: m.number == 1
                  ? path.module1.dailyCheckInCount
                  : null,
              inventoryDone: m.number == 3 ? inventoryDone : null,
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
            label: Text(
              RecoveryModuleContent.lapseEntryLabel,
              style: TextStyle(
                  fontSize: 12,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.25)),
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
  final bool isPremium;
  final int? checkInCount;
  final bool? inventoryDone;
  final VoidCallback? onTap;

  const _ModuleCard({
    required this.meta,
    required this.unlocked,
    required this.isPremium,
    this.checkInCount,
    this.inventoryDone,
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
                  Row(children: [
                    Text(
                      'M${meta.number} — ${meta.title}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dimmed
                              ? MyWalkColor.warmWhite.withValues(alpha: 0.3)
                              : MyWalkColor.warmWhite),
                    ),
                    if (isPremium) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: MyWalkColor.golden.withValues(alpha: 0.12),
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
    if (checkInCount != null) {
      final count = checkInCount!;
      if (count < 7) return '$count/7 check-ins to unlock weekly review';
      return '$count check-ins complete';
    }
    if (inventoryDone != null) {
      return inventoryDone! ? 'Values inventory done' : 'Values inventory not yet done';
    }
    return meta.subtitle;
  }
}
