import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/scripture.dart';
import '../../providers/habit_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import '../../../domain/entities/accountability_partnership.dart';
import '../../providers/accountability_provider.dart';
import '../../providers/recovery_path_provider.dart';
import '../../utils/partner_invite_dialog.dart';
import '../shared/fruit_tag_row.dart';
import '../shared/golden_pulse_view.dart';
import 'habit_detail_view.dart';
import 'habit_history_view.dart';
import 'thought_examination_screen.dart';
import 'guardrails_screen.dart';
import 'record_a_moment_screen.dart';
import '../../../domain/entities/recovery_path.dart';
import '../journal/journal_entry_composer.dart';
import 'my_freedom_plan_screen.dart';
import '../practices/breaking_free_intro_screen.dart';

class HabitCheckInCardView extends StatefulWidget {
  final Habit habit;
  final DateTime targetDate;
  final bool isRetroactive;

  const HabitCheckInCardView({
    super.key,
    required this.habit,
    required this.targetDate,
    this.isRetroactive = false,
  });

  @override
  State<HabitCheckInCardView> createState() => _HabitCheckInCardViewState();
}

class _HabitCheckInCardViewState extends State<HabitCheckInCardView> {
  bool _showPulse = false;
  bool _isCompleted = false;
  double _timedMinutes = 0;
  double _countValue = 0;
  Scripture? _completionVerse;

  // Write-serialization token: incremented on every timed/count update so
  // only the most-recent async write commits its post-await setState.
  int _writeToken = 0;

  int _logCount = 0;

  Habit get _habit => widget.habit;
  DateTime get _targetDate => widget.targetDate;

  @override
  void initState() {
    super.initState();
    _refreshState();
    if (_habit.trackingType == HabitTrackingType.abstain &&
        !widget.isRetroactive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<RecoveryPathProvider>().loadPath(_habit.id);
          _loadLogCount();
        }
      });
    }
  }

  @override
  void didUpdateWidget(HabitCheckInCardView old) {
    super.didUpdateWidget(old);
    if (old.targetDate != widget.targetDate) {
      _refreshState();
    }
  }

  Future<void> _loadLogCount() async {
    try {
      final count = await context.read<RecoveryPathProvider>().getBehaviourLogCount(_habit.id);
      if (mounted) setState(() => _logCount = count);
    } catch (_) {
      // Silently ignore — count stays at 0 if sessions can't be read yet
      // (e.g. recovery_paths document hasn't synced to Firestore server).
    }
  }

  void _refreshState() {
    final entry = _habit.entryFor(_targetDate);
    _isCompleted = entry?.isCompleted ?? false;
    _timedMinutes = entry?.value ?? 0;
    _countValue = entry?.value ?? 0;
    if (_isCompleted) {
      // isPremium read deferred to build time to avoid context-in-initState issues
      _completionVerse = ScriptureLibrary.completionVerse(_habit.category, _targetDate, isPremium: false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isCompleted) {
      final isPremium = context.read<StoreProvider>().isPremium;
      _completionVerse = ScriptureLibrary.completionVerse(_habit.category, _targetDate, isPremium: isPremium);
    }
  }


  Future<void> _checkIn() async {
    final provider = context.read<HabitProvider>();
    final storeProvider = context.read<StoreProvider>();
    setState(() {
      _showPulse = true;
      _isCompleted = true;
    });
    await provider.checkInHabit(_habit, date: _targetDate, retroactive: widget.isRetroactive);
    if (!mounted) return;
    final isPremium = storeProvider.isPremium;
    setState(() {
      _completionVerse = ScriptureLibrary.completionVerse(_habit.category, _targetDate, isPremium: isPremium);
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _showPulse = false);
  }

  Future<void> _updateTimed(double delta) async {
    final provider = context.read<HabitProvider>();
    final newVal = (_timedMinutes + delta).clamp(0, 999).toDouble();
    // Optimistic UI update is always immediate and correct.
    setState(() => _timedMinutes = newVal);
    // Stamp a token before the await so rapid taps only commit the last write.
    final token = ++_writeToken;
    await provider.updateTimedEntry(_habit, newVal, date: _targetDate);
    if (!mounted || token != _writeToken) return;
    setState(() => _isCompleted =
        _habit.entryFor(_targetDate)?.isCompleted ?? newVal >= _habit.dailyTarget);
  }

  Future<void> _updateCount(double delta) async {
    final provider = context.read<HabitProvider>();
    final newVal = (_countValue + delta).clamp(0, 9999).toDouble();
    setState(() => _countValue = newVal);
    final token = ++_writeToken;
    await provider.updateCountEntry(_habit, newVal, date: _targetDate);
    if (!mounted || token != _writeToken) return;
    setState(() => _isCompleted =
        _habit.entryFor(_targetDate)?.isCompleted ?? newVal >= _habit.dailyTarget);
  }

  @override
  Widget build(BuildContext context) {
    final isPulse = context.select<HabitProvider, bool>(
      (p) => p.checkInPulseHabitId == _habit.id,
    );
    final isAbstain = _habit.trackingType == HabitTrackingType.abstain;
    final accentColor = isAbstain ? MyWalkColor.sage : MyWalkColor.golden;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showDetail(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MyWalkColor.cardBackground,
                  accentColor.withValues(alpha: _isCompleted ? 0.10 : 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(
                    alpha: _isCompleted ? 0.30 : 0.18),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(accentColor),
                const SizedBox(height: 8),
                _trackingUI(accentColor),
                if (_habit.category == HabitCategory.gratitude) ...[
                  const SizedBox(height: 12),
                  _gratitudeVersesSection(),
                ] else if (_isCompleted && _completionVerse != null) ...[
                  const SizedBox(height: 12),
                  _verseSection(),
                ],
                if (isAbstain && !widget.isRetroactive) ...[
                  if (_habit.subcategoryId == 'breaking_habits' ||
                      _habit.hasRecoveryPath) ...[
                    const SizedBox(height: 10),
                    _recordAMomentButton(context),
                    const SizedBox(height: 8),
                    _breakingHabitsChips(context),
                  ],
                  const SizedBox(height: 12),
                  _partnerStrip(context),
                  const SizedBox(height: 8),
                  _rpStrip(context),
                ],
              ],
            ),
          ),
        ),
        if (_showPulse || isPulse)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: GoldenPulseView(onComplete: () {
                  if (mounted) setState(() => _showPulse = false);
                }),
              ),
            ),
          ),
      ],
    );
  }

  Widget _header(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: _isCompleted ? 0.3 : 0.12),
                    accentColor.withValues(alpha: _isCompleted ? 0.1 : 0.03),
                  ],
                ),
              ),
              child: Icon(_habitIcon(), color: accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _habit.subcategoryId == 'breaking_habits'
                        ? 'Breaking Patterns: ${_habit.displayName}'
                        : _habit.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: MyWalkColor.warmWhite,
                    ),
                  ),
                  if (_isCompleted)
                    Text(
                      _completedSubtitle(),
                      style: const TextStyle(fontSize: 11, color: MyWalkColor.sage),
                    )
                  else if (_habit.subcategoryId != 'breaking_habits') ...[
                    if (_habit.subcategoryName != null &&
                        _habit.subcategoryName!.isNotEmpty)
                      Text(
                        _habit.subcategoryName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.4)),
                      )
                    else
                      Text(
                        _habit.purposeStatement,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            color: MyWalkColor.softGold.withValues(alpha: 0.6)),
                      ),
                  ],
                  if (_habit.fruitTags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    FruitTagRow(
                      fruitTags: _habit.fruitTags,
                      purposeStatement: _habit.fruitPurposeStatement,
                    ),
                  ],
                ],
              ),
            ),
            if (_isCompleted)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle_rounded, color: accentColor, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Action pills row
        Row(
          children: [
            _actionPill(
              label: 'Show History',
              icon: Icons.bar_chart_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              background: Colors.white.withValues(alpha: 0.05),
              border: Colors.white.withValues(alpha: 0.15),
              onTap: () => _showHistory(context),
            ),
            const SizedBox(width: 6),
            _actionPill(
              label: 'Create Journal',
              icon: Icons.edit_note,
              color: MyWalkColor.softGold.withValues(alpha: 0.75),
              background: MyWalkColor.softGold.withValues(alpha: 0.08),
              border: MyWalkColor.softGold.withValues(alpha: 0.2),
              onTap: () => _openJournal(context),
            ),
            const SizedBox(width: 6),
            _actionPill(
              label: 'Practice Details',
              icon: Icons.open_in_new_rounded,
              color: accentColor.withValues(alpha: 0.7),
              background: accentColor.withValues(alpha: 0.07),
              border: accentColor.withValues(alpha: 0.2),
              onTap: () => _showDetail(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionPill({
    required String label,
    required IconData icon,
    required Color color,
    required Color background,
    required Color border,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _trackingUI(Color accentColor) {
    switch (_habit.trackingType) {
      case HabitTrackingType.checkIn:
        return _checkInButton(accentColor);
      case HabitTrackingType.abstain:
        return _abstainButton();
      case HabitTrackingType.timed:
        return _timedUI(accentColor);
      case HabitTrackingType.count:
        return _countUI(accentColor);
    }
  }

  Widget _checkInButton(Color accentColor) {
    if (_isCompleted) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _checkIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: MyWalkColor.charcoal,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Check In', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _partnerStrip(BuildContext context) {
    final partnership = context
        .watch<AccountabilityProvider>()
        .partnershipForHabit(_habit.id);

    if (partnership == null) {
      final accountabilityProv = context.watch<AccountabilityProvider>();
      return GestureDetector(
        onTap: accountabilityProv.isLoading
            ? null
            : () => showPartnerInviteDialog(
                  context,
                  habitId: _habit.id,
                  habitName: _habit.name,
                  habitLabel: _habit.subcategoryId == 'breaking_habits'
                      ? 'Breaking Patterns: ${_habit.displayName}'
                      : null,
                ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.add_rounded, size: 14,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.55)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                accountabilityProv.isLoading ? 'Creating invite…' : 'Add a support/prayer partner',
                style: TextStyle(
                    fontSize: 12,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.55)),
              ),
            ),
          ]),
        ),
      );
    }

    if (partnership.status == PartnershipStatus.pending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: MyWalkColor.warmWhite.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(Icons.hourglass_top_rounded, size: 14,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.45)),
          const SizedBox(width: 5),
          Expanded(
            child: Text('Waiting for partner…',
                style: TextStyle(
                    fontSize: 12,
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.45))),
          ),
        ]),
      );
    }

    // Active partnership — navigate to message thread
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        '/partnership-detail',
        arguments: partnership,
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: MyWalkColor.warmWhite.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          const Icon(Icons.handshake_rounded, size: 14, color: MyWalkColor.sage),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Reach out to ${partnership.partnerDisplayName ?? 'your partner'}',
              style: TextStyle(fontSize: 12, color: MyWalkColor.sage.withValues(alpha: 0.9)),
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 14, color: MyWalkColor.sage.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }

  Widget _rpStrip(BuildContext context) {
    final prov = context.watch<RecoveryPathProvider>();
    final habitId = _habit.id;

    // If the habit has a recovery path that hasn't been loaded yet, trigger
    // a load so the strip shows the correct active state rather than "Begin".
    if (_habit.hasRecoveryPath &&
        prov.pathFor(habitId) == null &&
        !prov.isLoadingFor(habitId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<RecoveryPathProvider>().loadPath(habitId);
      });
    }

    if (prov.isLoadingFor(habitId)) return const SizedBox.shrink();

    final path = prov.pathFor(habitId);
    const purple = Color(0xFF8B7EC8);

    // Path hasn't loaded yet but the habit knows one exists — show nothing.
    if (path == null && _habit.hasRecoveryPath) return const SizedBox.shrink();

    // No path yet — "Begin" opens the intro/setup flow (same as Add Practice).
    if (path == null) {
      return GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BreakingFreeIntroScreen(
            habitId: habitId,
            habitName: _habit.name,
          ),
        )),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.route_rounded, size: 14, color: purple),
            const SizedBox(width: 5),
            Expanded(
              child: Text('Freedom Plan — Begin',
                  style: TextStyle(
                      fontSize: 12,
                      color: purple.withValues(alpha: 0.85))),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 14, color: purple.withValues(alpha: 0.5)),
          ]),
        ),
      );
    }

    final phase = prov.phaseFor(habitId);
    final day = prov.dayNumberFor(habitId);
    final checkInPending = !prov.checkInDoneToday(habitId);
    final nextTask = phase == 2 ? _nextPhase2Task(path) : null;
    final label = nextTask != null
        ? 'Freedom Plan · Next: $nextTask'
        : 'Freedom Plan · Phase $phase · Day $day';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MyFreedomPlanScreen(
          habitId: habitId,
          habitName: _habit.name,
        ),
      )),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: purple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          const Icon(Icons.route_rounded, size: 14, color: purple),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: purple.withValues(alpha: 0.85)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (checkInPending || _hasPendingAction(path))
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: MyWalkColor.warmCoral,
                shape: BoxShape.circle,
              ),
            )
          else
            Icon(Icons.chevron_right_rounded,
                size: 14, color: purple.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }

  String? _nextPhase2Task(RecoveryPath path) {
    if (!path.cueHierarchyDone) return 'Map your pattern cues';
    if (path.counterResponses.isEmpty) return 'Examine your thoughts';
    if (!path.environmentalChangesDone) return 'Change your environment';
    if (!path.hrsPlanDone) return 'Build your coping plans';
    if (!path.module5.recoveryLetterWritten) return 'Write your recovery letter';
    return null;
  }

  String _dayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  Widget _abstainButton() {
    if ((_habit.subcategoryId == 'breaking_habits' || _habit.hasRecoveryPath) &&
        !widget.isRetroactive) {
      return const SizedBox.shrink();
    }
    if (_isCompleted) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _checkIn,
        icon: const Icon(Icons.shield_rounded, size: 16),
        label: Text(widget.isRetroactive
            ? 'Were you strong on ${_dayName(widget.targetDate)}?'
            : 'Stayed strong today?'),
        style: ElevatedButton.styleFrom(
          backgroundColor: MyWalkColor.sage,
          foregroundColor: MyWalkColor.charcoal,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _recordAMomentButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RecordAMomentScreen(habitId: _habit.id),
        )),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B7EC8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Record a moment',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  Widget _breakingHabitsChips(BuildContext context) {
    final prov = context.read<RecoveryPathProvider>();
    final path = prov.pathFor(_habit.id);
    if (path == null) return const SizedBox.shrink();

    final dbg = prov.debugChipsEnabled(_habit.id);
    final thoughtExamDone = path.counterResponses.isNotEmpty || dbg;
    final urgeSurfingShown = path.urgeSurfingIntroSeen || dbg;
    final counterResponsesShown = path.counterResponses.isNotEmpty || dbg;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        if (thoughtExamDone) ...[
          _habitActionChip(
            label: 'Examine a thought',
            subtitle: '~5 min',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ThoughtExaminationScreen(habitId: _habit.id),
            )),
          ),
        ],
        if (urgeSurfingShown) ...[
          if (thoughtExamDone) const SizedBox(width: 6),
          _habitActionChip(
            label: 'Urge surfed',
            subtitle: 'Log a surfed urge',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GuardrailsScreen(
                habitId: _habit.id,
                habitName: _habit.name,
                initialTab: 2,
              ),
            )),
          ),
        ],
        if (counterResponsesShown) ...[
          if (thoughtExamDone || urgeSurfingShown) const SizedBox(width: 6),
          _habitActionChip(
            label: 'My counter-responses',
            subtitle: 'Your saved responses',
            onTap: () => _openCounterResponseLibrary(context, path),
          ),
        ],
      ]),
    );
  }

  Widget _habitActionChip({
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: MyWalkColor.softGold.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: MyWalkColor.softGold.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: MyWalkColor.softGold.withValues(alpha: 0.8),
              ),
            ),
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: MyWalkColor.softGold.withValues(alpha: 0.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openCounterResponseLibrary(BuildContext context, RecoveryPath path) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _CounterResponseLibrary(responses: path.counterResponses),
    );
  }

  bool _hasPendingAction(RecoveryPath path) {
    final prov = context.read<RecoveryPathProvider>();
    final day = prov.dayNumberFor(_habit.id);
    return (day >= 8 && day <= 10 && !path.midPointReflectionDone) ||
        (day >= 14 && !path.cueHierarchyDone && _logCount >= 5) ||
        (path.module3.valuesInventoryDone &&
            !prov.compassDoneThisWeek(_habit.id));
  }

  Widget _timedUI(Color accentColor) {
    final target = _habit.dailyTarget;
    final ratio = target > 0 ? (_timedMinutes / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: ratio,
                strokeWidth: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(accentColor),
              ),
            ),
            Text(
              '${_timedMinutes.toInt()}m',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _timedButton('-5', () => _updateTimed(-5)),
            const SizedBox(width: 8),
            _timedButton('+5', () => _updateTimed(5)),
            const SizedBox(width: 8),
            _timedButton('+15', () => _updateTimed(15)),
            const SizedBox(width: 8),
            _timedButton('+30', () => _updateTimed(30)),
          ],
        ),
        if (target > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Goal: ${target.toInt()} min',
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ],
    );
  }

  Widget _timedButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: MyWalkColor.surfaceOverlay,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.softGold),
        ),
      ),
    );
  }

  Widget _countUI(Color accentColor) {
    final target = _habit.dailyTarget;
    final unit = _habit.targetUnit.isEmpty ? '' : ' ${_habit.targetUnit}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _countButton(Icons.remove, () => _updateCount(-1)),
        const SizedBox(width: 16),
        Column(
          children: [
            Text(
              '${_countValue.toInt()}$unit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _isCompleted ? accentColor : MyWalkColor.warmWhite,
              ),
            ),
            if (target > 0)
              Text(
                'of ${target.toInt()}$unit',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3)),
              ),
          ],
        ),
        const SizedBox(width: 16),
        _countButton(Icons.add, () => _updateCount(1)),
      ],
    );
  }

  Widget _countButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MyWalkColor.surfaceOverlay,
        ),
        child: Icon(icon, size: 18, color: MyWalkColor.softGold),
      ),
    );
  }

  Widget _gratitudeVersesSection() {
    const verses = [
      ('The joy of the Lord is my strength', 'Nehemiah 8:10'),
      ('I can do all things through Christ who strengthens me', 'Philippians 4:13'),
      ('Rejoice in the Lord always and again I say rejoice', 'Philippians 4:4'),
    ];
    return Column(
      children: [
        for (int i = 0; i < verses.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Text(
            '\u201C${verses[i].$1}\u201D',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: MyWalkColor.softGold.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            verses[i].$2,
            style: TextStyle(
                fontSize: 10, color: MyWalkColor.golden.withValues(alpha: 0.4)),
          ),
        ],
      ],
    );
  }

  Widget _verseSection() {
    final verse = _completionVerse!;
    return Column(
      children: [
        Text(
          '\u201C${verse.text}\u201D',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: MyWalkColor.softGold.withValues(alpha: 0.55),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          verse.reference,
          style: TextStyle(fontSize: 10, color: MyWalkColor.golden.withValues(alpha: 0.4)),
        ),
      ],
    );
  }

  String _completedSubtitle() {
    switch (_habit.trackingType) {
      case HabitTrackingType.timed:
        return '${_timedMinutes.toInt()} min given';
      case HabitTrackingType.count:
        final unit = _habit.targetUnit.isEmpty ? '' : ' ${_habit.targetUnit}';
        return '${_countValue.toInt()}$unit completed';
      case HabitTrackingType.checkIn:
        return 'Completed today';
      case HabitTrackingType.abstain:
        return 'I walked freely today \u2713';
    }
  }

  IconData _habitIcon() {
    if (_habit.trackingType == HabitTrackingType.abstain) return Icons.shield_rounded;
    switch (_habit.category) {
      case HabitCategory.gratitude: return Icons.auto_awesome;
      case HabitCategory.scripture: return Icons.menu_book;
      case HabitCategory.exercise: return Icons.fitness_center;
      case HabitCategory.rest: return Icons.bedtime;
      case HabitCategory.fasting: return Icons.no_food;
      case HabitCategory.study: return Icons.school;
      case HabitCategory.service: return Icons.volunteer_activism;
      case HabitCategory.connection: return Icons.people;
      case HabitCategory.health: return Icons.favorite;
      case HabitCategory.abstain: return Icons.shield_rounded;
      case HabitCategory.prayer: return Icons.self_improvement_rounded;
      case HabitCategory.custom: return Icons.star;
    }
  }

  void _openJournal(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntryComposer(
          habitId: _habit.id,
          habitName: _habit.name,
          fruitTag: _habit.fruitTags.firstOrNull,
          sourceType: 'habit',
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => HabitHistoryView(habit: _habit),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, sc) => HabitDetailView(habit: _habit, scrollController: sc),
      ),
    );
  }
}

// ── Counter-response library bottom sheet ─────────────────────────────────────

class _CounterResponseLibrary extends StatelessWidget {
  final List<Map<String, dynamic>> responses;
  const _CounterResponseLibrary({required this.responses});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('My Counter-Responses',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: MyWalkColor.warmWhite)),
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: responses.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('No counter-responses saved yet.',
                      style: TextStyle(
                          fontSize: 13,
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.5))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: responses.length,
                  separatorBuilder: (_, _) => Divider(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.07),
                    height: 1,
                  ),
                  itemBuilder: (_, i) {
                    final r = responses[i];
                    final thought = r['thought'] as String? ?? '';
                    final alternative = r['alternative'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (thought.isNotEmpty) ...[
                            Text('"$thought"',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: MyWalkColor.warmWhite
                                        .withValues(alpha: 0.45))),
                            const SizedBox(height: 4),
                          ],
                          Text(alternative,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: MyWalkColor.warmWhite)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
