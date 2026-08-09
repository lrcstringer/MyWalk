import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import '../../../domain/entities/recovery_path.dart';
import '../journal/freedom_journey_tab.dart';

class MyFreedomPlanScreen extends StatelessWidget {
  final String habitId;
  final String habitName;

  const MyFreedomPlanScreen({
    super.key,
    required this.habitId,
    required this.habitName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        elevation: 0,
        title: const Text(
          'My Freedom Plan',
          style: TextStyle(
            color: MyWalkColor.warmWhite,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _PhaseDashboard(habitId: habitId),
          Expanded(
            child: FreedomJourneyTab(habitId: habitId),
          ),
        ],
      ),
    );
  }
}

// ── Phase dashboard ───────────────────────────────────────────────────────────

class _PhaseDashboard extends StatelessWidget {
  final String habitId;
  const _PhaseDashboard({required this.habitId});

  static const _phases = [
    _PhaseInfo('Setup', 0, Color(0xFF6B7A8D)),
    _PhaseInfo('Getting Started', 1, Color(0xFFD4A017)),
    _PhaseInfo('Going Deeper', 2, Color(0xFF8B7EC8)),
    _PhaseInfo('Sustained Practice', 3, Color(0xFF4CAF82)),
    _PhaseInfo('Maintenance', 4, Color(0xFF5B8DB8)),
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecoveryPathProvider>();
    final currentPhase = prov.phaseFor(habitId);
    final path = prov.pathFor(habitId);

    return Container(
      color: MyWalkColor.charcoal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: _phases.map((p) {
                final isActive = p.phase == currentPhase;
                final isDone = p.phase < currentPhase;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PhasePill(
                    info: p,
                    isActive: isActive,
                    isDone: isDone,
                  ),
                );
              }).toList(),
            ),
          ),
          if (currentPhase == 2 && path != null)
            _Phase2SubSteps(path: path),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        ],
      ),
    );
  }
}

class _PhaseInfo {
  final String label;
  final int phase;
  final Color color;
  const _PhaseInfo(this.label, this.phase, this.color);
}

class _PhasePill extends StatelessWidget {
  final _PhaseInfo info;
  final bool isActive;
  final bool isDone;

  const _PhasePill({
    required this.info,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final color = info.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.8)
              : isDone
                  ? color.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.12),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDone) ...[
            Icon(Icons.check_circle_rounded,
                size: 11, color: color.withValues(alpha: 0.55)),
            const SizedBox(width: 4),
          ],
          Text(
            info.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? color
                  : isDone
                      ? color.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _Phase2SubSteps extends StatelessWidget {
  final RecoveryPath path;
  const _Phase2SubSteps({required this.path});

  static const _purple = Color(0xFF8B7EC8);

  @override
  Widget build(BuildContext context) {
    final steps = [
      (label: 'Cue map', done: path.cueHierarchyDone),
      (label: 'Thoughts', done: path.counterResponses.isNotEmpty),
      (label: 'Environment', done: path.environmentalChangesDone),
      (label: 'Guardrails', done: path.hrsPlanDone),
      (label: 'Letter', done: path.module5.recoveryLetterWritten),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: steps.map((s) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.done
                          ? _purple
                          : Colors.transparent,
                      border: s.done
                          ? null
                          : Border.all(
                              color: _purple.withValues(alpha: 0.35),
                              width: 1,
                            ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: s.done
                          ? _purple.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
