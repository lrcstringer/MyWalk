import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../providers/habit_provider.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import '../habits/cue_hierarchy_screen.dart';
import '../habits/guardrails_screen.dart';
import '../habits/recovery_letter_screen.dart';
import '../habits/thought_examination_screen.dart';
import '../habits/values_inventory_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

// Per-task accent colours — sourced from MyWalkColor so other files can share them
const _kAccentValues     = MyWalkColor.bpValues;
const _kAccentCueMap     = MyWalkColor.bpCueMap;
const _kAccentThoughts   = MyWalkColor.bpThoughts;
const _kAccentGuardrails = MyWalkColor.bpGuardrails;
const _kAccentLetter     = MyWalkColor.bpLetter;

const Map<String, String> _kSessionLabels = {
  'm1DailyCheckIn': 'Daily Check-In',
  'm1WeeklyReview': 'Weekly Review',
  'm1BehaviourLog': 'Moment Logged',
  'm1MidPointReflection': 'Mid-Point Reflection',
  'm1CueHierarchy': 'Pattern Triggers Built',
  'm2ThoughtExamination': 'Thought Examined',
  'm3ValuesInventory': 'Values Mapped',
  'm3WeeklyCompass': 'Weekly Compass',
  'm4UrgeSurfing': 'Urge Surfed',
  'm4EnvironmentalRestructuring': 'Environment Changed',
  'm4LifestyleAudit': 'Balance Check',
  'm5RecoveryLetter': 'Recovery Letter Written',
  'm5QuarterlyReview': 'Quarterly Review',
  'm5AveEducation': 'Lapse Education Read',
  'm5LapseResponse': 'Back on Track',
  'lapseRecord': 'Setback Recorded',
};

String _sessionLabel(RecoverySession s) =>
    _kSessionLabels[s.sessionType.value] ?? s.sessionType.value;

String _dateLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}';
}

String _snippetFor(RecoverySession s) {
  if (s.sessionType == RecoverySessionType.m3ValuesInventory) {
    final values = _parseValuesText(s.responseText);
    return values.isEmpty ? '' : '${values.length} domains mapped';
  }
  final text = s.responseText;
  if (text.isEmpty) return '';
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      for (final entry in decoded.entries) {
        if (_kSkipFields.contains(entry.key)) continue;
        final v = entry.value;
        if (v is String && v.isNotEmpty) {
          return v.length > 80 ? '${v.substring(0, 80)}…' : v;
        }
      }
    }
  } catch (_) {}
  return text.length > 100 ? '${text.substring(0, 100)}…' : text;
}

const _kSkipFields = {'branch', 'copingPlanUpdated', 'emotionRating'};

const _kFieldLabels = <String, String>{
  'locationTime':       'Where were you? What time of day was it?',
  'activityBefore':     'What were you doing immediately before?',
  'emotionalState':     'How were you feeling emotionally?',
  'emotionName':        'How were you feeling emotionally?',
  'thoughtArose':       'What thought arose just before?',
  'selfCompassion':     'What would you say to a good friend?',
  'forensicGap':        'Where did your coping plan not hold?',
  'copingPlanGap':      'What would need to be different next time?',
  'recommittedValue':   'Which Values matter most going forward?',
  'whatHappened':       'What happened?',
  'nextStep':           'Immediate next step',
};

List<Map<String, String>> _expandedPairs(RecoverySession s) {
  final text = s.responseText;
  if (text.isEmpty) return [];
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      final pairs = <Map<String, String>>[];
      for (final entry in decoded.entries) {
        final key = entry.key as String;
        if (_kSkipFields.contains(key)) continue;
        final value = entry.value;
        if (value == null || value == false) continue;
        final valueStr = value.toString().trim();
        if (valueStr.isEmpty || valueStr == 'false') continue;
        final label = _kFieldLabels[key] ?? key;
        pairs.add({'label': label, 'value': valueStr});
      }
      if (pairs.isNotEmpty) return pairs;
    }
  } catch (_) {}
  return [{'label': '', 'value': text}];
}

class _ParsedValue {
  final String domain;
  final String importance;
  final String alignment;
  final String compassDirection;
  final String reflection;
  const _ParsedValue({
    required this.domain,
    required this.importance,
    required this.alignment,
    required this.compassDirection,
    required this.reflection,
  });
}

List<_ParsedValue> _parseValuesText(String text) {
  final result = <_ParsedValue>[];
  for (final p in text.split('\n\n').where((p) => p.trim().isNotEmpty)) {
    final colonIdx = p.indexOf(': ');
    if (colonIdx == -1) continue;
    final domain = p.substring(0, colonIdx).trim();
    final rest = p.substring(colonIdx + 2);
    final importanceMatch = RegExp(r'importance=(\d+)').firstMatch(rest);
    final alignmentMatch = RegExp(r'alignment=(\d+)').firstMatch(rest);
    final compassMatch = RegExp(r'compassDirection=(\w+)').firstMatch(rest);
    final reflIdx = rest.indexOf('reflection=');
    result.add(_ParsedValue(
      domain: domain,
      importance: importanceMatch?.group(1) ?? '5',
      alignment: alignmentMatch?.group(1) ?? '5',
      compassDirection: compassMatch?.group(1) ?? 'neutral',
      reflection: reflIdx >= 0 ? rest.substring(reflIdx + 'reflection='.length).trim() : '',
    ));
  }
  return result;
}

// ── Main widget ───────────────────────────────────────────────────────────────

class FreedomJourneyTab extends StatefulWidget {
  final String habitId;
  const FreedomJourneyTab({super.key, required this.habitId});

  @override
  State<FreedomJourneyTab> createState() => _FreedomJourneyTabState();
}

class _FreedomJourneyTabState extends State<FreedomJourneyTab> {
  int _view = 1; // 0 = My Journey, 1 = My Plan
  List<RecoverySession>? _sessions;
  bool _loading = true;
  // Last Week and Earlier start collapsed; Today and This Week start open.
  final Set<String> _collapsedGroups = {'Last Week', 'Earlier'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSessions());
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;
    try {
      final sessions = await context
          .read<RecoveryPathProvider>()
          .getAllSessions(widget.habitId);
      if (mounted) setState(() { _sessions = sessions; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _sessions = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RecoveryPathProvider>();
    final path = prov.pathFor(widget.habitId);

    return Container(
      color: MyWalkColor.charcoal,
      child: Column(
        children: [
          _buildSegmentedButton(),
          Expanded(
            child: _view == 0
                ? _buildJourneyView()
                : _buildPlanView(prov, path),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('My Journey')),
          ButtonSegment(value: 1, label: Text('My Plan')),
        ],
        selected: {_view},
        onSelectionChanged: (s) => setState(() => _view = s.first),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _kRpPurple;
            return MyWalkColor.surfaceOverlay;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return MyWalkColor.warmWhite.withValues(alpha: 0.7);
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: _kRpPurple.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }

  // ── My Journey ────────────────────────────────────────────────────────────

  Widget _buildJourneyView() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _kRpPurple, strokeWidth: 2),
      );
    }
    final sessions = _sessions ?? [];
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timeline_outlined,
                size: 44,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'Your journey entries will appear here as you work through your plan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

    String bucket(DateTime dt) {
      final d = DateTime(dt.year, dt.month, dt.day);
      if (!d.isBefore(today)) return 'Today';
      if (!d.isBefore(startOfThisWeek)) return 'This Week';
      if (!d.isBefore(startOfLastWeek)) return 'Last Week';
      return 'Earlier';
    }

    const bucketOrder = ['Today', 'This Week', 'Last Week', 'Earlier'];
    final buckets = <String, List<RecoverySession>>{};
    for (final s in sessions) {
      buckets.putIfAbsent(bucket(s.createdAt), () => []).add(s);
    }

    final items = <Widget>[];
    for (final key in bucketOrder) {
      final group = buckets[key];
      if (group == null) continue;
      final isExpanded = !_collapsedGroups.contains(key);
      items.add(_JourneyGroupHeader(
        label: key,
        count: group.length,
        isExpanded: isExpanded,
        onToggle: () => setState(() {
          if (_collapsedGroups.contains(key)) {
            _collapsedGroups.remove(key);
          } else {
            _collapsedGroups.add(key);
          }
        }),
      ));
      if (isExpanded) {
        for (final s in group) {
          items.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _JourneyEntryCard(
              session: s,
              label: _sessionLabel(s),
              dateLabel: _dateLabel(s.createdAt),
              snippet: _snippetFor(s),
            ),
          ));
        }
      }
      items.add(const SizedBox(height: 4));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: items,
    );
  }

  // ── My Plan ───────────────────────────────────────────────────────────────

  Widget _buildPlanView(RecoveryPathProvider prov, RecoveryPath? path) {
    if (path == null) {
      return const Center(
        child: CircularProgressIndicator(color: _kRpPurple, strokeWidth: 2),
      );
    }

    final habits = context.read<HabitProvider>().habits;
    String habitName = '';
    for (final h in habits) {
      if (h.id == widget.habitId) { habitName = h.name; break; }
    }

    final phase = prov.phaseFor(widget.habitId);
    final showPhase2Tasks = phase >= 2;

    final bool thoughtExamDone =
        path.thoughtExaminationResult != null || path.counterResponses.isNotEmpty;
    final bool letterLocked = !path.cueHierarchyDone ||
        !thoughtExamDone ||
        !path.hrsPlanDone ||
        !path.environmentalChangesDone ||
        !path.urgeSurfingIntroSeen;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        _PlanTaskCard(
          title: 'Anchor to Your Values',
          accent: _kAccentValues,
          isDone: path.module3.valuesInventoryDone,
          isLocked: false,
          hasDraft: path.valuesInventoryDraftStep > 0 &&
              !path.module3.valuesInventoryDone,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ValuesInventoryScreen(
              habitId: widget.habitId,
              habitName: habitName,
              accentColor: _kAccentValues,
            ),
          )),
        ),
        if (showPhase2Tasks) ...[
          const SizedBox(height: 10),
          _PlanTaskCard(
            title: 'Map Your Pattern Cues',
            accent: _kAccentCueMap,
            isDone: path.cueHierarchyDone,
            isLocked: false,
            hasDraft: path.cueHierarchyDraftStage > 0 && !path.cueHierarchyDone,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CueHierarchyScreen(
                habitId: widget.habitId,
                habitName: habitName,
                habitType: path.habitType ?? '',
                accentColor: _kAccentCueMap,
              ),
            )),
          ),
          const SizedBox(height: 10),
          _PlanTaskCard(
            title: 'Examine Your Thoughts',
            accent: _kAccentThoughts,
            isDone: thoughtExamDone,
            isLocked: false,
            hasDraft: path.thoughtExaminationDraftStep > 0,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ThoughtExaminationScreen(
                habitId: widget.habitId,
                accentColor: _kAccentThoughts,
              ),
            )),
          ),
          const SizedBox(height: 10),
          _GuardrailsPlanCard(
            habitId: widget.habitId,
            habitName: habitName,
            path: path,
            isLocked: !path.cueHierarchyDone,
          ),
          const SizedBox(height: 10),
          _PlanTaskCard(
            title: 'Write Your Recovery Letter',
            accent: _kAccentLetter,
            isDone: path.module5.recoveryLetterWritten,
            isLocked: letterLocked,
            lockedMessage: 'Complete all previous tasks first.',
            hasDraft: path.recoveryLetterDraft != null &&
                !path.module5.recoveryLetterWritten,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RecoveryLetterScreen(
                habitId: widget.habitId,
                accentColor: _kAccentLetter,
              ),
            )),
          ),
        ],
      ],
    );
  }
}

// ── My Plan task cards ────────────────────────────────────────────────────────

class _PlanTaskCard extends StatelessWidget {
  final String title;
  final Color accent;
  final bool isDone;
  final bool isLocked;
  final String lockedMessage;
  final bool hasDraft;
  final VoidCallback? onTap;

  const _PlanTaskCard({
    required this.title,
    required this.accent,
    required this.isDone,
    this.isLocked = false,
    this.lockedMessage = '',
    this.hasDraft = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent.withValues(alpha: 0.2)),
                Expanded(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.03),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                      child: Row(
                        children: [
                          _CompletionDot(isDone: false, isLocked: true, accent: accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: MyWalkColor.warmWhite.withValues(alpha: 0.28),
                                  ),
                                ),
                                if (lockedMessage.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    lockedMessage,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: MyWalkColor.warmWhite.withValues(alpha: 0.2),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            offset: const Offset(0, -1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: accent.withValues(alpha: isDone ? 0.28 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              color: isDone ? accent : accent.withValues(alpha: 0.55),
            ),
            Expanded(
              child: Container(
                color: MyWalkColor.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Row(
                    children: [
                      _CompletionDot(isDone: isDone, isLocked: false, accent: accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? MyWalkColor.warmWhite.withValues(alpha: 0.7)
                                : MyWalkColor.warmWhite.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TaskActionButton(
                        isDone: isDone,
                        hasDraft: hasDraft,
                        onTap: onTap,
                        accent: accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _CompletionDot extends StatelessWidget {
  final bool isDone;
  final bool isLocked;
  final Color accent;
  const _CompletionDot({required this.isDone, required this.isLocked, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? accent : Colors.transparent,
        border: Border.all(
          color: isLocked
              ? Colors.white.withValues(alpha: 0.15)
              : isDone
                  ? accent
                  : accent.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: isDone
            ? [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 8, spreadRadius: -1)]
            : null,
      ),
      child: isDone
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : isLocked
              ? Icon(Icons.lock_outline_rounded,
                  size: 12, color: Colors.white.withValues(alpha: 0.25))
              : null,
    );
  }
}

class _TaskActionButton extends StatelessWidget {
  final bool isDone;
  final bool hasDraft;
  final VoidCallback? onTap;
  final Color accent;
  const _TaskActionButton(
      {required this.isDone, required this.hasDraft, required this.accent, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String label = isDone ? 'Edit' : hasDraft ? 'Resume' : 'Start';
    final Color bg = isDone
        ? Colors.transparent
        : hasDraft
            ? MyWalkColor.golden.withValues(alpha: 0.18)
            : accent.withValues(alpha: 0.18);
    final Color fg = isDone
        ? MyWalkColor.warmWhite.withValues(alpha: 0.45)
        : hasDraft
            ? MyWalkColor.golden
            : accent;
    final Color border = isDone
        ? MyWalkColor.warmWhite.withValues(alpha: 0.15)
        : hasDraft
            ? MyWalkColor.golden.withValues(alpha: 0.5)
            : accent.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}

class _GuardrailsPlanCard extends StatelessWidget {
  final String habitId;
  final String habitName;
  final RecoveryPath path;
  final bool isLocked;

  const _GuardrailsPlanCard({
    required this.habitId,
    required this.habitName,
    required this.path,
    required this.isLocked,
  });

  void _openTab(BuildContext context, int tab) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GuardrailsScreen(
        habitId: habitId,
        habitName: habitName,
        initialTab: tab,
        accentColor: _kAccentGuardrails,
      ),
    ));
  }

  int get _firstIncompleteTab {
    if (!path.hrsPlanDone) return 1;
    if (!path.environmentalChangesDone) return 0;
    if (!path.urgeSurfingIntroSeen) return 2;
    return 0;
  }

  bool get _allDone =>
      path.hrsPlanDone &&
      path.environmentalChangesDone &&
      path.urgeSurfingIntroSeen;

  @override
  Widget build(BuildContext context) {
    final bool done = _allDone;
    const accent = _kAccentGuardrails;

    if (isLocked) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent.withValues(alpha: 0.2)),
                Expanded(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.03),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                      child: Row(
                        children: [
                          _CompletionDot(isDone: false, isLocked: true, accent: accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Build Your Guardrails',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: MyWalkColor.warmWhite.withValues(alpha: 0.28),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Unlocks when your cue map is complete.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: MyWalkColor.warmWhite.withValues(alpha: 0.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            offset: const Offset(0, -1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: accent.withValues(alpha: done ? 0.28 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: done ? accent : accent.withValues(alpha: 0.55),
              ),
            Expanded(
              child: Container(
                color: MyWalkColor.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CompletionDot(isDone: done, isLocked: false, accent: accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Build Your Guardrails',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: done
                                    ? MyWalkColor.warmWhite.withValues(alpha: 0.7)
                                    : MyWalkColor.warmWhite.withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TaskActionButton(
                            isDone: done,
                            hasDraft: false,
                            accent: accent,
                            onTap: () => _openTab(context, _firstIncompleteTab),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _GuardrailsPill(
                            label: 'High-Risk Plan',
                            isDone: path.hrsPlanDone,
                            accent: accent,
                            onTap: () => _openTab(context, 1),
                          ),
                          _GuardrailsPill(
                            label: 'Change Your Environment',
                            isDone: path.environmentalChangesDone,
                            accent: accent,
                            onTap: () => _openTab(context, 0),
                          ),
                          _GuardrailsPill(
                            label: 'Urge Surfing',
                            isDone: path.urgeSurfingIntroSeen,
                            accent: accent,
                            onTap: () => _openTab(context, 2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _GuardrailsPill extends StatelessWidget {
  final String label;
  final bool isDone;
  final VoidCallback onTap;
  final Color accent;

  const _GuardrailsPill({
    required this.label,
    required this.isDone,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDone ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone
                ? accent.withValues(alpha: 0.45)
                : MyWalkColor.warmWhite.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDone) ...[
              Icon(Icons.check_circle_rounded, size: 11, color: accent),
              const SizedBox(width: 4),
            ] else ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                color: isDone
                    ? accent
                    : MyWalkColor.warmWhite.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Journey group header ──────────────────────────────────────────────────────

class _JourneyGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _JourneyGroupHeader({
    required this.label,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kRpPurple.withValues(alpha: 0.75),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
              ),
            ),
            const Spacer(),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: _kRpPurple.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Journey entry card ────────────────────────────────────────────────────────

class _JourneyEntryCard extends StatefulWidget {
  final RecoverySession session;
  final String label;
  final String dateLabel;
  final String snippet;

  const _JourneyEntryCard({
    required this.session,
    required this.label,
    required this.dateLabel,
    required this.snippet,
  });

  @override
  State<_JourneyEntryCard> createState() => _JourneyEntryCardState();
}

class _JourneyEntryCardState extends State<_JourneyEntryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kRpPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.dateLabel,
                    style: const TextStyle(
                      color: _kRpPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.snippet.isNotEmpty)
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                  ),
              ],
            ),
            if (widget.snippet.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (_expanded)
                widget.session.sessionType == RecoverySessionType.m3ValuesInventory
                    ? _buildValuesExpanded()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _expandedPairs(widget.session).map((pair) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (pair['label']!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      pair['label']!,
                                      style: TextStyle(
                                        color: MyWalkColor.warmWhite.withValues(alpha: 0.38),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                Text(
                                  pair['value']!,
                                  style: TextStyle(
                                    color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
              else
                Text(
                  widget.snippet,
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValuesExpanded() {
    final values = _parseValuesText(widget.session.responseText);
    if (values.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: values.map((v) {
        final compassIcon = v.compassDirection == 'toward'
            ? Icons.arrow_upward
            : v.compassDirection == 'away'
                ? Icons.arrow_downward
                : Icons.remove;
        final compassColor = v.compassDirection == 'toward'
            ? MyWalkColor.sage
            : v.compassDirection == 'away'
                ? MyWalkColor.warmCoral
                : MyWalkColor.warmWhite.withValues(alpha: 0.3);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      v.domain,
                      style: TextStyle(
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(compassIcon, size: 14, color: compassColor),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'importance = ${v.importance}   alignment = ${v.alignment}',
                style: TextStyle(
                  color: _kRpPurple.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (v.reflection.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  v.reflection,
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Plan section card data ────────────────────────────────────────────────────

class _ModuleSection {
  final int number;
  final String name;
  final bool isLocked;
  final String lockedMessage;
  final bool isComplete;
  final List<Map<String, dynamic>> cues;
  final List<Map<String, dynamic>> counterResponses;
  final List<ValuesInventoryEntry> valuesInventory;
  final List<HrsPlan> hrsPlan;
  final String? recoveryLetter;

  const _ModuleSection({
    required this.number,
    required this.name,
    required this.isLocked,
    required this.lockedMessage,
    required this.isComplete,
    required this.cues,
    required this.counterResponses,
    required this.valuesInventory,
    required this.hrsPlan,
    required this.recoveryLetter,
  });
}

// ── Plan section card ─────────────────────────────────────────────────────────

class _PlanSectionCard extends StatelessWidget {
  final _ModuleSection data;
  final List<RecoverySession> sessions;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String habitId;
  final String habitName;

  const _PlanSectionCard({
    required this.data,
    required this.sessions,
    required this.isExpanded,
    required this.onToggle,
    required this.habitId,
    required this.habitName,
  });

  @override
  Widget build(BuildContext context) {
    return data.isLocked ? _buildLocked() : _buildUnlocked(context);
  }

  Widget _buildLocked() {
    return Opacity(
      opacity: 0.4,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.cardBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      color: MyWalkColor.warmWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.lockedMessage,
                    style: TextStyle(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlocked(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: data.isComplete
              ? _kRpPurple.withValues(alpha: 0.35)
              : MyWalkColor.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          InkWell(
            onTap: onToggle,
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.isComplete ? _kRpPurple : Colors.transparent,
                      border: Border.all(
                        color: data.isComplete
                            ? _kRpPurple
                            : MyWalkColor.warmWhite.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: data.isComplete
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.name,
                      style: const TextStyle(
                        color: MyWalkColor.warmWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded) ...[
            Divider(height: 1, color: MyWalkColor.cardBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Living documents
                  ..._buildLivingDocs(context),
                  // Session entries
                  ..._buildSessionEntries(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildLivingDocs(BuildContext context) {
    final widgets = <Widget>[];

    if (data.number == 1 && data.cues.isNotEmpty) {
      widgets.add(_sectionLabel('My Pattern Triggers'));
      widgets.add(const SizedBox(height: 8));
      for (final cue in data.cues) {
        widgets.add(_cueRow(cue));
      }
      widgets.add(const SizedBox(height: 16));
    }

    if (data.number == 2 && data.counterResponses.isNotEmpty) {
      widgets.add(_sectionLabel('My Counter-Responses'));
      widgets.add(const SizedBox(height: 8));
      for (final cr in data.counterResponses.take(4)) {
        widgets.add(_counterResponseRow(cr));
      }
      widgets.add(const SizedBox(height: 16));
    }

    if (data.number == 3 && data.valuesInventory.isNotEmpty) {
      widgets.add(_sectionLabel('My Values'));
      widgets.add(const SizedBox(height: 8));
      for (final e in data.valuesInventory) {
        widgets.add(_valueRow(e));
      }
      widgets.add(const SizedBox(height: 16));
    }

    if (data.number == 4 && data.hrsPlan.isNotEmpty) {
      widgets.add(_sectionLabel('My Coping Plans'));
      widgets.add(const SizedBox(height: 8));
      for (final p in data.hrsPlan.take(3)) {
        widgets.add(_hrsPlanRow(p));
      }
      widgets.add(
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GuardrailsScreen(habitId: habitId, habitName: habitName),
          )),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Edit plans →',
              style: TextStyle(
                color: _kRpPurple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    if (data.number == 5 && data.recoveryLetter != null) {
      widgets.add(_sectionLabel('My Recovery Letter'));
      widgets.add(const SizedBox(height: 8));
      widgets.add(_recoveryLetterCard(context));
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  List<Widget> _buildSessionEntries() {
    if (sessions.isEmpty) {
      return [
        Text(
          'No entries yet — start working through this module to see them here.',
          style: TextStyle(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.35),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ];
    }
    final shown = sessions.take(5).toList();
    return [
      _sectionLabel('${sessions.length} ${sessions.length == 1 ? 'entry' : 'entries'}'),
      const SizedBox(height: 8),
      ...shown.map(_sessionRow),
    ];
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: _kRpPurple.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _cueRow(Map<String, dynamic> cue) {
    final text = cue['cueText'] as String? ?? '';
    final rank = cue['rank'] as int? ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$rank.',
            style: TextStyle(
              color: _kRpPurple.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterResponseRow(Map<String, dynamic> cr) {
    final thought = cr['thought'] as String? ?? '';
    final alternative = cr['alternative'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thought.isNotEmpty)
            Text(
              '"$thought"',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (alternative.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: thought.isNotEmpty ? 2 : 0),
              child: Text(
                alternative,
                style: TextStyle(
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _valueRow(ValuesInventoryEntry e) {
    final compassIcon = e.compassDirection == 'toward'
        ? Icons.arrow_upward
        : e.compassDirection == 'away'
            ? Icons.arrow_downward
            : Icons.remove;
    final compassColor = e.compassDirection == 'toward'
        ? MyWalkColor.sage
        : e.compassDirection == 'away'
            ? MyWalkColor.warmCoral
            : MyWalkColor.warmWhite.withValues(alpha: 0.3);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              e.domain,
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
          Icon(compassIcon, size: 14, color: compassColor),
        ],
      ),
    );
  }

  Widget _hrsPlanRow(HrsPlan plan) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.situation,
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (plan.firstResponse.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              plan.firstResponse,
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _recoveryLetterCard(BuildContext context) {
    final letter = data.recoveryLetter!;
    final preview = letter.length > 150 ? '${letter.substring(0, 150)}…' : letter;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kRpPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kRpPurple.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview,
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.7),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RecoveryLetterScreen(habitId: habitId),
            )),
            child: Text(
              'Edit letter →',
              style: TextStyle(
                color: _kRpPurple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionRow(RecoverySession s) {
    final label = _kSessionLabels[s.sessionType.value] ?? s.sessionType.value;
    final dateStr = _dateLabel(s.createdAt);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(
            dateStr,
            style: TextStyle(
              color: _kRpPurple.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
