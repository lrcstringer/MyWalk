import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_path.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/recovery_phase_calculator.dart';
import '../../providers/habit_provider.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';
import '../habits/guardrails_screen.dart';
import '../habits/phase2_journey_screen.dart';
import '../habits/recovery_letter_screen.dart';

const _kRpPurple = Color(0xFF8B7EC8);

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
  final text = s.responseText;
  if (text.isEmpty) return '';
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      for (final v in decoded.values) {
        if (v is String && v.isNotEmpty) {
          return v.length > 80 ? '${v.substring(0, 80)}…' : v;
        }
      }
    }
  } catch (_) {}
  return text.length > 100 ? '${text.substring(0, 100)}…' : text;
}

// ── Main widget ───────────────────────────────────────────────────────────────

class FreedomJourneyTab extends StatefulWidget {
  final String habitId;
  const FreedomJourneyTab({super.key, required this.habitId});

  @override
  State<FreedomJourneyTab> createState() => _FreedomJourneyTabState();
}

class _FreedomJourneyTabState extends State<FreedomJourneyTab> {
  int _view = 0; // 0 = My Journey, 1 = My Plan
  List<RecoverySession>? _sessions;
  bool _loading = true;
  final Set<int> _expandedModules = {1};

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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _JourneyEntryCard(
        session: sessions[i],
        label: _sessionLabel(sessions[i]),
        dateLabel: _dateLabel(sessions[i].createdAt),
        snippet: _snippetFor(sessions[i]),
      ),
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

    final sessionsByModule = <int, List<RecoverySession>>{};
    for (final s in (_sessions ?? [])) {
      sessionsByModule.putIfAbsent(s.moduleNumber, () => []).add(s);
    }

    final sortedCues = List<Map<String, dynamic>>.from(path.cueHierarchy)
      ..sort((a, b) =>
          (a['rank'] as int? ?? 0).compareTo(b['rank'] as int? ?? 0));

    final modules = [
      _ModuleSection(
        number: 1,
        name: 'Know Your Pattern',
        isLocked: false,
        lockedMessage: '',
        isComplete: path.cueHierarchyDone,
        cues: sortedCues,
        counterResponses: const [],
        valuesInventory: const [],
        hrsPlan: const [],
        recoveryLetter: null,
      ),
      _ModuleSection(
        number: 2,
        name: 'Examine Your Thoughts',
        isLocked: !RecoveryPhaseCalculator.isModuleUnlocked(path, 2),
        lockedMessage: 'Unlocks when your cue map is complete.',
        isComplete: path.counterResponses.isNotEmpty,
        cues: const [],
        counterResponses: path.counterResponses,
        valuesInventory: const [],
        hrsPlan: const [],
        recoveryLetter: null,
      ),
      _ModuleSection(
        number: 3,
        name: 'Anchor to Your Values',
        isLocked: false,
        lockedMessage: '',
        isComplete: path.module3.valuesInventoryDone,
        cues: const [],
        counterResponses: const [],
        valuesInventory: path.module3.valuesInventory,
        hrsPlan: const [],
        recoveryLetter: null,
      ),
      _ModuleSection(
        number: 4,
        name: 'Build Your Guardrails',
        isLocked: !RecoveryPhaseCalculator.isModuleUnlocked(path, 4),
        lockedMessage: 'Unlocks when your cue map is complete.',
        isComplete: path.hrsPlanDone,
        cues: const [],
        counterResponses: const [],
        valuesInventory: const [],
        hrsPlan: path.module4.hrsPlan,
        recoveryLetter: null,
      ),
      _ModuleSection(
        number: 5,
        name: 'Navigate Lapses',
        isLocked: !RecoveryPhaseCalculator.isModuleUnlocked(path, 5),
        lockedMessage: 'Unlocks after 30 days or your first lapse.',
        isComplete: path.module5.recoveryLetterWritten,
        cues: const [],
        counterResponses: const [],
        valuesInventory: const [],
        hrsPlan: const [],
        recoveryLetter: path.recoveryLetterDraft,
      ),
    ];

    final phase = RecoveryPhaseCalculator.calculate(path);
    final showPhase2Card = phase == 2;

    // Count completed Phase 2 tasks for the card subtitle
    int phase2Done = 0;
    if (path.cueHierarchyDone) phase2Done++;
    if (path.counterResponses.isNotEmpty) phase2Done++;
    if (path.environmentalChangesDone) phase2Done++;
    if (path.hrsPlanDone) phase2Done++;
    if (path.module5.recoveryLetterWritten) phase2Done++;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: modules.length + (showPhase2Card ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (showPhase2Card && i == 0) {
          return _Phase2JourneyCard(
            habitId: widget.habitId,
            habitName: habitName,
            tasksComplete: phase2Done,
          );
        }
        final idx = showPhase2Card ? i - 1 : i;
        final m = modules[idx];
        final mSessions = List<RecoverySession>.from(
            sessionsByModule[m.number] ?? [])
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return _PlanSectionCard(
          data: m,
          sessions: mSessions,
          isExpanded: _expandedModules.contains(m.number),
          onToggle: () => setState(() {
            if (_expandedModules.contains(m.number)) {
              _expandedModules.remove(m.number);
            } else {
              _expandedModules.add(m.number);
            }
          }),
          habitId: widget.habitId,
          habitName: habitName,
        );
      },
    );
  }
}

// ── Phase 2 Journey card (shown in My Plan view when in Phase 2) ──────────────

class _Phase2JourneyCard extends StatelessWidget {
  final String habitId;
  final String habitName;
  final int tasksComplete;

  const _Phase2JourneyCard({
    required this.habitId,
    required this.habitName,
    required this.tasksComplete,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = tasksComplete >= 5;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Phase2JourneyScreen(
          habitId: habitId,
          habitName: habitName,
        ),
      )),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kRpPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kRpPurple.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kRpPurple.withValues(alpha: allDone ? 0.25 : 0.12),
            ),
            child: Icon(
              allDone ? Icons.check_rounded : Icons.layers_rounded,
              size: 18,
              color: _kRpPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Going Deeper — Phase 2 Tasks',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kRpPurple)),
                const SizedBox(height: 2),
                Text(
                  allDone
                      ? 'All 5 tasks complete'
                      : '$tasksComplete of 5 tasks complete',
                  style: TextStyle(
                      fontSize: 12,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.55)),
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
              Text(
                _expanded ? widget.session.responseText : widget.snippet,
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
