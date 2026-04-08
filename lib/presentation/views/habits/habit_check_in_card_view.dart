import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/scripture.dart';
import '../../providers/habit_provider.dart';
import '../../providers/store_provider.dart';
import '../../../domain/services/milestone_service.dart';
import '../../theme/app_theme.dart';
import '../../../domain/entities/accountability_partnership.dart';
import '../../providers/accountability_provider.dart';
import '../../providers/recovery_path_provider.dart';
import '../shared/fruit_tag_row.dart';
import '../shared/golden_pulse_view.dart';
import '../shared/milestone_celebration_view.dart';
import 'habit_detail_view.dart';
import '../journal/journal_entry_composer.dart';

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
  static const _milestoneService = MilestoneService.instance;

  bool _showPulse = false;
  bool _isCompleted = false;
  double _timedMinutes = 0;
  double _countValue = 0;
  Scripture? _completionVerse;
  Milestone? _celebrationMilestone;

  // Write-serialization token: incremented on every timed/count update so
  // only the most-recent async write commits its post-await setState.
  int _writeToken = 0;

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
    final previousTotal = _habit.totalCompletedDays().toDouble();
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
    if (!widget.isRetroactive) {
      final newTotal = previousTotal + 1;
      final milestone = _milestoneService.checkForNewMilestone(
        _habit,
        previousValue: previousTotal,
        newValue: newTotal,
      );
      if (milestone != null) {
        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) setState(() { _showPulse = false; _celebrationMilestone = milestone; });
        return;
      }
    }
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
            decoration: MyWalkDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(accentColor),
                const SizedBox(height: 8),
                _trackingUI(accentColor),
                if (_isCompleted && _completionVerse != null) ...[
                  const SizedBox(height: 12),
                  _verseSection(),
                ],
                if (isAbstain && !widget.isRetroactive) ...[
                  const SizedBox(height: 8),
                  _partnerStrip(context),
                  const SizedBox(height: 4),
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
        if (_celebrationMilestone != null)
          Positioned.fill(
            child: MilestoneCelebrationView(
              milestone: _celebrationMilestone!,
              trackingType: _habit.trackingType,
              onDismiss: () => setState(() => _celebrationMilestone = null),
            ),
          ),
      ],
    );
  }

  Widget _header(Color accentColor) {
    return Row(
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
          child: Icon(
            _habitIcon(),
            color: accentColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _habit.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: MyWalkColor.warmWhite,
                ),
              ),
              if (_isCompleted)
                Text(
                  _completedSubtitle(),
                  style: TextStyle(
                    fontSize: 11,
                    color: MyWalkColor.sage,
                  ),
                )
              else if (_habit.subcategoryName != null && _habit.subcategoryName!.isNotEmpty)
                Text(
                  _habit.subcategoryName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                )
              else
                Text(
                  _habit.purposeStatement,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: MyWalkColor.softGold.withValues(alpha: 0.6),
                  ),
                ),
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
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _openJournal(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: MyWalkColor.softGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: MyWalkColor.softGold.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note,
                    size: 14,
                    color: MyWalkColor.softGold.withValues(alpha: 0.75)),
                const SizedBox(width: 4),
                Text(
                  'Journal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: MyWalkColor.softGold.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (_isCompleted)
          Icon(Icons.check_circle_rounded, color: accentColor, size: 24)
        else
          Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.2), size: 16),
      ],
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
            : () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final url = await accountabilityProv.createInvite(
                    habitId: _habit.id,
                    habitName: _habit.name,
                  );
                  if (!mounted) return;
                  await Share.share(
                    'Walk with me on MyWalk — tap to become my prayer partner: $url',
                  );
                } catch (_) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Could not create invite. Try again.')),
                  );
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Icon(Icons.add_rounded, size: 12,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
            const SizedBox(width: 4),
            Text(
              accountabilityProv.isLoading ? 'Creating invite…' : 'Add a prayer partner',
              style: TextStyle(
                  fontSize: 10,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
            ),
          ]),
        ),
      );
    }

    if (partnership.status == PartnershipStatus.pending) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Icon(Icons.hourglass_top_rounded, size: 12,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.35)),
          const SizedBox(width: 4),
          Text('Waiting for partner…',
              style: TextStyle(
                  fontSize: 11,
                  color: MyWalkColor.warmWhite.withValues(alpha: 0.35))),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          const Icon(Icons.handshake_rounded, size: 12, color: MyWalkColor.sage),
          const SizedBox(width: 5),
          Text(
            'Reach out to ${partnership.partnerDisplayName ?? 'your partner'}',
            style: TextStyle(
                fontSize: 11,
                color: MyWalkColor.sage.withValues(alpha: 0.8)),
          ),
          const SizedBox(width: 3),
          Icon(Icons.chevron_right_rounded,
              size: 12, color: MyWalkColor.sage.withValues(alpha: 0.5)),
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

    void openRP() => Navigator.of(context).pushNamed(
          '/recovery-path',
          arguments: {'habitId': habitId, 'habitName': _habit.name},
        );

    // Path hasn't loaded yet but the habit knows one exists — show nothing
    // rather than the misleading "Begin" label.
    if (path == null && _habit.hasRecoveryPath) return const SizedBox.shrink();

    if (path == null) {
      return GestureDetector(
        onTap: openRP,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            const Icon(Icons.route_rounded, size: 11, color: purple),
            const SizedBox(width: 4),
            Text('Recovery Path — Begin ›',
                style: TextStyle(
                    fontSize: 10,
                    color: purple.withValues(alpha: 0.7))),
          ]),
        ),
      );
    }

    final phase = prov.phaseFor(habitId);
    final day = prov.dayNumberFor(habitId);
    final checkInPending = !prov.checkInDoneToday(habitId);

    return GestureDetector(
      onTap: openRP,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          const Icon(Icons.route_rounded, size: 11, color: purple),
          const SizedBox(width: 4),
          Text('Recovery Path · Phase $phase · Day $day',
              style: TextStyle(fontSize: 10, color: purple.withValues(alpha: 0.7))),
          if (checkInPending) ...[
            const SizedBox(width: 5),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: MyWalkColor.warmCoral,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ]),
      ),
    );
  }

  String _dayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  Widget _abstainButton() {
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
        return '${_habit.totalCompletedDays()} days total';
      case HabitTrackingType.abstain:
        return 'Clean day \u2713';
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
