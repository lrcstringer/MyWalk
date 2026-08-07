import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/recovery_session.dart';
import '../../../domain/services/cue_rubric_service.dart';
import '../../providers/recovery_path_provider.dart';
import '../../theme/app_theme.dart';

const _kRpPurple = Color(0xFF8B7EC8);

/// 5-stage cue hierarchy builder for the Freedom Plan.
/// Stage 0: entry welcome
/// Stage 1: review logged moments
/// Stage 2: AI candidate cues (stub in Task 7, real call in Task 8)
/// Stage 3: discovery questions from CueRubricService
/// Stage 4: rank and edit final cues
class CueHierarchyScreen extends StatefulWidget {
  final String habitId;
  final String habitName;
  final String habitType;

  const CueHierarchyScreen({
    super.key,
    required this.habitId,
    required this.habitName,
    required this.habitType,
  });

  @override
  State<CueHierarchyScreen> createState() => _CueHierarchyScreenState();
}

class _CueHierarchyScreenState extends State<CueHierarchyScreen> {
  int _stage = 0;
  bool _done = false;
  bool _saving = false;

  // Stage 1 — log review
  List<RecoverySession> _logs = [];
  bool _logsLoading = true;
  final Set<String> _expandedLogIds = {};

  // Stage 2 — AI candidates
  bool _aiLoading = false;
  bool _aiSkipped = false;
  final List<_CueCandidate> _aiCandidates = [];

  // Stage 3 — discovery questions
  List<DiscoveryQuestion> _discoveryQuestions = [];
  final Map<String, String> _discoveryAnswers = {}; // key → 'yes'|'sometimes'|'no'

  // Stage 4 — rank/edit
  final List<_CueEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();

    // Resume from draft if any.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final path = context.read<RecoveryPathProvider>().pathFor(widget.habitId);
      if (path != null && path.cueHierarchyDraftStage > 0) {
        setState(() => _stage = path.cueHierarchyDraftStage.clamp(0, 4));
      }
    });
  }

  Future<void> _loadLogs() async {
    try {
      final prov = context.read<RecoveryPathProvider>();
      final logs = await prov.getSessionsByType(
          widget.habitId, RecoverySessionType.m1BehaviourLog);
      if (mounted) {
        setState(() {
          _logs = logs;
          _logsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _logsLoading = false);
    }
  }

  // ── Stage transitions ─────────────────────────────────────────────────────

  void _goToStage(int stage) {
    setState(() => _stage = stage);
    context
        .read<RecoveryPathProvider>()
        .saveCueHierarchyDraft(widget.habitId, stage);
  }

  void _onEntryNext() => _goToStage(1);

  void _onLogsNext() {
    _goToStage(2);
    _runAiAnalysis();
  }

  Future<void> _runAiAnalysis() async {
    setState(() => _aiLoading = true);
    try {
      final rubric = CueRubricService.rubricFor(widget.habitType);
      final logEntries = <Map<String, dynamic>>[];
      for (final session in _logs) {
        try {
          final parsed = jsonDecode(session.responseText) as Map<String, dynamic>;
          logEntries.add({
            'date': DateFormat('yyyy-MM-dd').format(session.createdAt),
            'locationTime': parsed['locationTime'] ?? '',
            'activityBefore': parsed['activityBefore'] ?? '',
            'emotionName': parsed['emotionName'] ?? '',
            'emotionRating': parsed['emotionRating'] ?? 0,
            'thoughtArose': parsed['thoughtArose'] ?? '',
          });
        } catch (_) {}
      }

      if (logEntries.isEmpty) { _skipAi(); return; }

      final callable = FirebaseFunctions.instance.httpsCallable(
        'rpAnalyseCues',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 25)),
      );
      final result = await callable.call({
        'habitType': widget.habitType,
        'logs': logEntries,
        'primaryCues': rubric.primaryCues,
      });

      final data = result.data as Map<String, dynamic>;
      final cues = (data['cues'] as List<dynamic>?)
              ?.whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .toList() ??
          [];

      if (cues.isEmpty) { _skipAi(); return; }

      if (mounted) {
        setState(() {
          _aiLoading = false;
          _aiCandidates
              .addAll(cues.map((t) => _CueCandidate(text: t, keep: true)));
        });
      }
    } catch (_) {
      if (mounted) _skipAi();
    }
  }

  void _skipAi() {
    _setupDiscovery();
    setState(() {
      _aiLoading = false;
      _aiSkipped = true;
      _stage = 3;
    });
    context
        .read<RecoveryPathProvider>()
        .saveCueHierarchyDraft(widget.habitId, 3);
  }

  void _onAiNext() {
    _setupDiscovery();
    _goToStage(3);
  }

  void _setupDiscovery() {
    _discoveryQuestions =
        CueRubricService.discoveryQuestionsFor(widget.habitType, _logs);
  }

  void _onDiscoveryNext() {
    _buildEntries();
    _goToStage(4);
  }

  void _buildEntries() {
    _entries.clear();
    // Kept AI candidates
    for (final c in _aiCandidates) {
      if (c.keep) _entries.add(_CueEntry(text: c.text, isAi: true));
    }
    // Discovery additions
    for (final q in _discoveryQuestions) {
      final ans = _discoveryAnswers[q.key];
      if (ans == 'yes' || ans == 'sometimes') {
        _entries.add(_CueEntry(
          text: CueRubricService.cueTextFromDiscovery(widget.habitType, q.key),
          isAi: false,
        ));
      }
    }
    // Ensure at least 2 entries for Stage 4 to be valid.
    if (_entries.isEmpty) {
      _entries.add(_CueEntry(text: '', isAi: false));
      _entries.add(_CueEntry(text: '', isAi: false));
    } else if (_entries.length == 1) {
      _entries.add(_CueEntry(text: '', isAi: false));
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final cues = _entries.asMap().entries.map((e) => {
            'rank': e.key + 1,
            'cueText': e.value.controller.text.trim(),
            'isAiSuggested': e.value.isAi,
          }).toList();
      await context
          .read<RecoveryPathProvider>()
          .saveCueHierarchy(widget.habitId, cues);
      if (mounted) setState(() { _saving = false; _done = true; });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save. Check your connection.")),
        );
      }
    }
  }

  bool get _canSave =>
      _entries.length >= 2 &&
      _entries.every((e) => e.controller.text.trim().isNotEmpty);

  bool get _discoveryComplete =>
      _discoveryQuestions.every((q) => _discoveryAnswers.containsKey(q.key));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_done) return const _CompletionView();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: MyWalkColor.warmWhite,
          onPressed: () {
            if (_stage > 0) {
              setState(() => _stage--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _appBarTitle,
          style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          SafeArea(child: _buildStage()),
        ],
      ),
    );
  }

  String get _appBarTitle {
    switch (_stage) {
      case 0: return 'Your pattern map';
      case 1: return 'Your logged moments';
      case 2: return 'Finding patterns';
      case 3: return 'A few more questions';
      case 4: return 'Your pattern triggers';
      default: return '';
    }
  }

  Widget _buildStage() {
    switch (_stage) {
      case 0: return _buildEntry();
      case 1: return _buildLogs();
      case 2: return _buildAi();
      case 3: return _buildDiscovery();
      case 4: return _buildRank();
      default: return const SizedBox.shrink();
    }
  }

  // ── Stage 0 — Entry ───────────────────────────────────────────────────────

  Widget _buildEntry() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kRpPurple.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.route_rounded, color: _kRpPurple, size: 28),
          ),
          const SizedBox(height: 28),
          const Text(
            "You've been logging moments for two weeks.\nThat takes honesty and courage.",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MyWalkColor.warmWhite,
                height: 1.4),
          ),
          const SizedBox(height: 16),
          Text(
            "Now let's look at what your logs are telling you — together.",
            style: TextStyle(
                fontSize: 15,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                height: 1.5),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onEntryNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Let's go",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stage 1 — Review logs ─────────────────────────────────────────────────

  Widget _buildLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            "Read through what you've captured. Don't analyse yet — just notice.",
            style: TextStyle(
                fontSize: 14,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                height: 1.5),
          ),
        ),
        Expanded(
          child: _logsLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kRpPurple))
              : _logs.isEmpty
                  ? _emptyLogs()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _logs.length,
                      itemBuilder: (_, i) => _LogCard(
                        session: _logs[i],
                        expanded: _expandedLogIds.contains(_logs[i].id),
                        onToggle: () => setState(() {
                          if (_expandedLogIds.contains(_logs[i].id)) {
                            _expandedLogIds.remove(_logs[i].id);
                          } else {
                            _expandedLogIds.add(_logs[i].id);
                          }
                        }),
                      ),
                    ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _logsLoading ? null : _onLogsNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("I've read through them",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyLogs() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          "No moments logged yet. Come back after you've captured a few.",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.45),
              height: 1.5),
        ),
      ),
    );
  }

  // ── Stage 2 — AI candidate patterns ──────────────────────────────────────

  Widget _buildAi() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_aiLoading) ...[
            const Spacer(),
            const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kRpPurple),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Analysing your logs…',
                  style: TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.5))),
            ),
            const Spacer(),
          ] else ...[
            Text(
              'Based on your logs, here are some possible patterns.',
              style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                  height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep the ones that ring true. Remove any that don\'t fit.',
              style: TextStyle(
                  fontSize: 13,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _aiCandidates.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _CueCandidateCard(
                  candidate: _aiCandidates[i],
                  onToggle: () =>
                      setState(() => _aiCandidates[i].keep = !_aiCandidates[i].keep),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onAiNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRpPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Stage 3 — Discovery questions ────────────────────────────────────────

  Widget _buildDiscovery() {
    if (_discoveryQuestions.isEmpty) {
      // No questions to ask — proceed directly.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_stage == 3) _onDiscoveryNext();
      });
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _kRpPurple));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            _aiSkipped
                ? "Let's look at some common patterns together."
                : 'Based on what we know about this pattern, do any of these ring true?',
            style: TextStyle(
                fontSize: 14,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                height: 1.5),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _discoveryQuestions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (_, i) {
              final q = _discoveryQuestions[i];
              return _DiscoveryQuestionCard(
                question: q,
                selected: _discoveryAnswers[q.key],
                onAnswer: (ans) =>
                    setState(() => _discoveryAnswers[q.key] = ans),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _discoveryComplete ? _onDiscoveryNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRpPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kRpPurple.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Stage 4 — Rank and edit ───────────────────────────────────────────────

  Widget _buildRank() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'Edit to use your own words. Drag to rank — most triggering at the bottom.',
            style: TextStyle(
                fontSize: 14,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                height: 1.5),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _entries.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _entries.removeAt(oldIndex);
                _entries.insert(newIndex, item);
              });
            },
            itemBuilder: (_, i) {
              final e = _entries[i];
              return _RankCard(
                key: ValueKey(e),
                entry: e,
                canDelete: _entries.length > 2,
                onDelete: () => setState(() {
                  e.controller.dispose();
                  _entries.removeAt(i);
                }),
                onChanged: (_) => setState(() {}),
              );
            },
          ),
        ),
        // Add button (hidden at 6 cues)
        if (_entries.length < 6)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _entries.add(_CueEntry(text: '', isAi: false))),
              icon: const Icon(Icons.add, color: _kRpPurple, size: 18),
              label: const Text('Add your own',
                  style: TextStyle(color: _kRpPurple, fontSize: 13)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              if (!_canSave && _entries.any((e) => e.controller.text.trim().isEmpty))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Fill in all trigger descriptions before saving.',
                    style: TextStyle(
                        fontSize: 12,
                        color: MyWalkColor.warmCoral.withValues(alpha: 0.8)),
                  ),
                ),
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
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save my pattern triggers',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _CueCandidate {
  String text;
  bool keep;
  _CueCandidate({required this.text, required this.keep});
}

class _CueEntry {
  bool isAi;
  final TextEditingController controller;
  _CueEntry({required String text, required this.isAi})
      : controller = TextEditingController(text: text);
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final RecoverySession session;
  final bool expanded;
  final VoidCallback onToggle;

  const _LogCard({
    required this.session,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('EEE d MMM').format(session.createdAt);
    // Parse what we can from the responseText JSON.
    final preview = session.responseText.length > 60
        ? '${session.responseText.substring(0, 60)}…'
        : session.responseText;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kRpPurple.withValues(alpha: 0.8))),
            const SizedBox(height: 6),
            Text(
              expanded ? session.responseText : preview,
              style: TextStyle(
                  fontSize: 13,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.65),
                  height: 1.5),
            ),
            if (!expanded && session.responseText.length > 60)
              Text('tap to expand',
                  style: TextStyle(
                      fontSize: 11,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.3))),
          ],
        ),
      ),
    );
  }
}

class _CueCandidateCard extends StatelessWidget {
  final _CueCandidate candidate;
  final VoidCallback onToggle;

  const _CueCandidateCard(
      {required this.candidate, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: candidate.keep
            ? _kRpPurple.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: candidate.keep
              ? _kRpPurple.withValues(alpha: 0.35)
              : MyWalkColor.warmWhite.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              candidate.text,
              style: TextStyle(
                  fontSize: 14,
                  color: MyWalkColor.warmWhite
                      .withValues(alpha: candidate.keep ? 0.85 : 0.4),
                  height: 1.4),
            ),
          ),
          const SizedBox(width: 12),
          _ToggleChip(
            label: candidate.keep ? 'Keep' : 'Removed',
            active: candidate.keep,
            onTap: onToggle,
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? _kRpPurple.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? _kRpPurple
                  : MyWalkColor.warmWhite.withValues(alpha: 0.12)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active
                    ? _kRpPurple
                    : MyWalkColor.warmWhite.withValues(alpha: 0.4))),
      ),
    );
  }
}

class _DiscoveryQuestionCard extends StatelessWidget {
  final DiscoveryQuestion question;
  final String? selected;
  final ValueChanged<String> onAnswer;

  const _DiscoveryQuestionCard({
    required this.question,
    required this.selected,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.questionText,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: MyWalkColor.warmWhite,
                  height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              _AnswerChip(
                  label: 'Yes, this rings true',
                  value: 'yes',
                  selected: selected,
                  onTap: onAnswer),
              const SizedBox(width: 8),
              _AnswerChip(
                  label: 'Sometimes',
                  value: 'sometimes',
                  selected: selected,
                  onTap: onAnswer),
              const SizedBox(width: 8),
              _AnswerChip(
                  label: 'Not really',
                  value: 'no',
                  selected: selected,
                  onTap: onAnswer),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  final String label;
  final String value;
  final String? selected;
  final ValueChanged<String> onTap;

  const _AnswerChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _kRpPurple.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? _kRpPurple
                  : MyWalkColor.warmWhite.withValues(alpha: 0.12),
              width: isSelected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? _kRpPurple
                    : MyWalkColor.warmWhite.withValues(alpha: 0.55))),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final _CueEntry entry;
  final bool canDelete;
  final VoidCallback onDelete;
  final ValueChanged<String> onChanged;

  const _RankCard({
    super.key,
    required this.entry,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle_rounded,
              color: Color(0x55FFFFFF), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: entry.controller,
              onChanged: onChanged,
              maxLines: null,
              style: const TextStyle(
                  color: MyWalkColor.warmWhite, fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Describe the trigger situation…',
                hintStyle: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.28),
                    fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (canDelete)
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.close_rounded,
                  size: 18,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }
}

// ── Completion view ───────────────────────────────────────────────────────────

class _CompletionView extends StatelessWidget {
  const _CompletionView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: DeepSpaceBackground())),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _kRpPurple.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.map_outlined,
                        color: _kRpPurple, size: 32),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "You've just done something most people never do — looked honestly at your own patterns.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: MyWalkColor.warmWhite,
                        height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This list is the map. Everything that comes next uses it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.55),
                        height: 1.6),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRpPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back to my plan',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
