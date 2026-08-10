import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import 'cue_hierarchy_screen.dart';
import 'environmental_restructuring_screen.dart';
import 'guardrails_screen.dart';
import 'recovery_letter_screen.dart';
import 'thought_examination_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

class Phase2JourneyScreen extends StatelessWidget {
  final String habitId;
  final String habitName;

  const Phase2JourneyScreen({
    super.key,
    required this.habitId,
    required this.habitName,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecoveryPathProvider>();
    final path = prov.pathFor(habitId);

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Going Deeper',
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
              child: IgnorePointer(child: DeepSpaceBackground())),
          if (path == null)
            const Center(child: CircularProgressIndicator(color: _kRpPurple))
          else
            _JourneyBody(
              path: path,
              habitId: habitId,
              habitName: habitName,
            ),
        ],
      ),
    );
  }
}

class _JourneyBody extends StatelessWidget {
  final RecoveryPath path;
  final String habitId;
  final String habitName;

  const _JourneyBody({
    required this.path,
    required this.habitId,
    required this.habitName,
  });

  static const _taskTitles = [
    'Map your pattern cues',
    'Examine your thoughts',
    'Change your environment',
    'Build your coping plans',
    'Write your recovery letter',
  ];

  static const _taskDescriptions = [
    'Identify what triggers your pattern — in your own words.',
    'Slow down the thoughts that drive the urge.',
    'Restructure your environment to make it harder to slip.',
    'Build plans for every high-risk situation.',
    'A letter from your future self for when things get hard.',
  ];

  bool _isTaskDone(int i) {
    switch (i) {
      case 0: return path.cueHierarchyDone;
      case 1: return path.counterResponses.isNotEmpty;
      case 2: return path.environmentalChangesDone;
      case 3: return path.hrsPlanDone;
      case 4: return path.module5.recoveryLetterWritten;
      default: return false;
    }
  }

  bool _isUnlocked(int i) {
    switch (i) {
      case 0: return true;
      case 1: return true;
      case 2: return path.cueHierarchyDone;
      case 3: return path.cueHierarchyDone;
      case 4:
        return path.cueHierarchyDone &&
            path.counterResponses.isNotEmpty &&
            path.environmentalChangesDone &&
            path.hrsPlanDone;
      default: return false;
    }
  }

  bool _isInProgress(int i) {
    switch (i) {
      case 0: return (path.cueHierarchyDraftStage > 0) && !path.cueHierarchyDone;
      case 1: return path.thoughtExaminationDraftStep > 0;
      case 2: return false;
      case 3: return false;
      case 4:
        return (path.recoveryLetterDraft != null &&
                path.recoveryLetterDraft!.trim().isNotEmpty) &&
            !path.module5.recoveryLetterWritten;
      default: return false;
    }
  }

  void _openTask(BuildContext context, int i) {
    switch (i) {
      case 0:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CueHierarchyScreen(
            habitId: habitId,
            habitName: habitName,
            habitType: path.habitType,
          ),
        ));
      case 1:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ThoughtExaminationScreen(habitId: habitId),
        ));
      case 2:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EnvironmentalRestructuringScreen(
            habitId: habitId,
            habitType: path.habitType,
          ),
        ));
      case 3:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GuardrailsScreen(
            habitId: habitId,
            habitName: habitName,
            initialTab: 0,
          ),
        ));
      case 4:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RecoveryLetterScreen(habitId: habitId),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Week 3–4 · Complete each section in order',
            style: TextStyle(
                fontSize: 12,
                color: _kRpPurple.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (i) {
            final done = _isTaskDone(i);
            final inProgress = _isInProgress(i) && !done;
            final unlocked = _isUnlocked(i);
            return _TaskCard(
              index: i,
              title: _taskTitles[i],
              description: _taskDescriptions[i],
              isDone: done,
              isInProgress: inProgress,
              isUnlocked: unlocked,
              onTap: (unlocked || done) ? () => _openTask(context, i) : null,
            );
          }),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final bool isDone;
  final bool isInProgress;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const _TaskCard({
    required this.index,
    required this.title,
    required this.description,
    required this.isDone,
    required this.isInProgress,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color bgColor;
    final Color titleColor;

    if (isDone) {
      borderColor = _kRpPurple.withValues(alpha: 0.25);
      bgColor = _kRpPurple.withValues(alpha: 0.06);
      titleColor = _kRpPurple.withValues(alpha: 0.7);
    } else if (isInProgress) {
      borderColor = _kRpPurple.withValues(alpha: 0.5);
      bgColor = _kRpPurple.withValues(alpha: 0.1);
      titleColor = MyWalkColor.warmWhite;
    } else if (isUnlocked) {
      borderColor = _kRpPurple.withValues(alpha: 0.2);
      bgColor = MyWalkColor.cardBackground;
      titleColor = MyWalkColor.warmWhite;
    } else {
      borderColor = MyWalkColor.warmWhite.withValues(alpha: 0.08);
      bgColor = MyWalkColor.cardBackground;
      titleColor = MyWalkColor.warmWhite.withValues(alpha: 0.3);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.75),
        ),
        child: Row(
          children: [
            _StatusIcon(
              isDone: isDone,
              isInProgress: isInProgress,
              isUnlocked: isUnlocked,
              index: index,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor),
                  ),
                  const SizedBox(height: 2),
                  if (isDone)
                    Text('Tappable to review',
                        style: TextStyle(
                            fontSize: 11,
                            color: _kRpPurple.withValues(alpha: 0.55)))
                  else if (isInProgress)
                    Text('In progress',
                        style: TextStyle(
                            fontSize: 11,
                            color: _kRpPurple.withValues(alpha: 0.8)))
                  else if (!isUnlocked)
                    Text(_lockCondition(index),
                        style: TextStyle(
                            fontSize: 11,
                            color: MyWalkColor.warmWhite.withValues(alpha: 0.25)))
                  else
                    Text(description,
                        style: TextStyle(
                            fontSize: 11,
                            color: MyWalkColor.warmWhite.withValues(alpha: 0.45))),
                ],
              ),
            ),
            if (isDone)
              Icon(Icons.check_circle_rounded,
                  size: 16, color: _kRpPurple.withValues(alpha: 0.6))
            else if (isInProgress)
              Text('Resume →',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kRpPurple))
            else if (isUnlocked)
              Text('Start →',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _kRpPurple.withValues(alpha: 0.7)))
            else
              Icon(Icons.lock_rounded,
                  size: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }

  String _lockCondition(int i) {
    if (i == 2) return 'Unlocks once your cue map is complete';
    if (i == 3) return 'Unlocks once your cue map is complete';
    if (i == 4) return 'Unlocks once tasks 1–4 are complete';
    return '';
  }
}

class _StatusIcon extends StatelessWidget {
  final bool isDone;
  final bool isInProgress;
  final bool isUnlocked;
  final int index;

  const _StatusIcon({
    required this.isDone,
    required this.isInProgress,
    required this.isUnlocked,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kRpPurple.withValues(alpha: 0.15),
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: _kRpPurple),
      );
    }
    if (isInProgress) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kRpPurple.withValues(alpha: 0.12),
          border: Border.all(
              color: _kRpPurple.withValues(alpha: 0.6), width: 1.5),
        ),
        child: const Center(
          child: Icon(Icons.arrow_forward_rounded,
              size: 14, color: _kRpPurple),
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isUnlocked
              ? _kRpPurple.withValues(alpha: 0.3)
              : MyWalkColor.warmWhite.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUnlocked
                  ? _kRpPurple.withValues(alpha: 0.6)
                  : MyWalkColor.warmWhite.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}
