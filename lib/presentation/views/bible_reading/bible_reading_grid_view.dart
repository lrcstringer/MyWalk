import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/services/bible_reading_plan_data.dart';
import '../../../domain/entities/bible_reading_plan.dart';
import '../../providers/bible_reading_provider.dart';
import '../../theme/app_theme.dart';
import 'bible_reading_day_modal.dart';
import 'bible_reading_milestone_screen.dart';


class BibleReadingGridView extends StatefulWidget {
  const BibleReadingGridView({super.key});

  @override
  State<BibleReadingGridView> createState() => _BibleReadingGridViewState();
}

class _BibleReadingGridViewState extends State<BibleReadingGridView> {
  late final ScrollController _scrollController;
  final Set<int> _expanded = {};
  bool _initialScrollDone = false;
  final Map<int, GlobalKey> _weekKeys = {};
  final Set<int> _localShownMilestones = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentWeek(int weekIndex) {
    if (_initialScrollDone) return;
    _initialScrollDone = true;
    // Week 1 is already at the top — no scroll needed; the hero stays visible.
    if (weekIndex == 0) return;
    // For later weeks, delay so the hero is seen before the list scrolls down.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        final key = _weekKeys[weekIndex];
        if (key?.currentContext == null) return;
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BibleReadingProvider>();
    final currentWeek = provider.currentWeekIndex;

    if (currentWeek != null && !_expanded.contains(currentWeek)) {
      _expanded.add(currentWeek);
      _scrollToCurrentWeek(currentWeek);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkMilestone(context));

    final imageHeight = MediaQuery.of(context).size.width * 0.65;
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: DeepSpaceBackground()),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Immersive collapsing header ─────────────────────────────────
              SliverAppBar(
                expandedHeight: imageHeight,
                pinned: true,
                backgroundColor: MyWalkColor.charcoal,
                foregroundColor: MyWalkColor.warmWhite,
                title: Text(
                  'Bible in a Year',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: MyWalkColor.warmWhite,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/bibleinayear.png',
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              MyWalkColor.charcoal.withValues(alpha: 0.5),
                              MyWalkColor.charcoal,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bible in a Year',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: MyWalkColor.warmWhite,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              '"Your word is a lamp to my feet\nand a light to my path."',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: MyWalkColor.softGold,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Psalm 119:105',
                              style: TextStyle(
                                fontSize: 11,
                                color: MyWalkColor.golden,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats strip (active only) ───────────────────────────────────
              if (provider.isActive)
                SliverToBoxAdapter(
                  child: _StatsStrip(provider: provider),
                ),

              // ── Pending banner ──────────────────────────────────────────────
              if (provider.isPending)
                SliverToBoxAdapter(
                  child: _PendingBanner(provider: provider),
                ),

              // ── Main content ────────────────────────────────────────────────
              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: MyWalkColor.golden),
                  ),
                )
              else if (provider.isNotStarted)
                SliverFillRemaining(
                  child: _NotStartedView(
                    onStart: () => _startPlan(context, provider),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, w) {
                        _weekKeys[w] ??= GlobalKey();
                        return _WeekAccordion(
                          key: _weekKeys[w],
                          weekIndex: w,
                          provider: provider,
                          isExpanded: _expanded.contains(w),
                          isCurrent: w == currentWeek,
                          onToggle: () => setState(() {
                            if (_expanded.contains(w)) {
                              _expanded.remove(w);
                            } else {
                              _expanded.add(w);
                            }
                          }),
                          onDayTap: (d) => _openDayModal(context, w, d),
                        );
                      },
                      childCount: BibleReadingPlanData.weeks.length,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startPlan(BuildContext context, BibleReadingProvider provider) async {
    await provider.startPlan();
  }

  void _openDayModal(BuildContext context, int weekIndex, int dayIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BibleReadingDayModal(
        weekIndex: weekIndex,
        dayIndex: dayIndex,
      ),
    );
  }

  void _checkMilestone(BuildContext context) {
    if (!mounted) return;
    final provider = context.read<BibleReadingProvider>();
    final milestone = provider.pendingMilestone();
    if (milestone == null || _localShownMilestones.contains(milestone)) return;
    _localShownMilestones.add(milestone);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BibleReadingMilestoneScreen(weekIndex: milestone),
        fullscreenDialog: true,
      ),
    ).then((_) {
      provider.markMilestoneShown(milestone);
    });
  }
}

// ── Stats strip ────────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final BibleReadingProvider provider;
  const _StatsStrip({required this.provider});

  @override
  Widget build(BuildContext context) {
    final streak = provider.state?.streakDays ?? 0;
    final daysRead = provider.totalDaysRead;
    final pct = (daysRead / 364 * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          _StatCell(emoji: '🔥', value: '$streak', label: 'day streak'),
          _StatDivider(),
          _StatCell(emoji: '📖', value: '$daysRead', label: 'days read'),
          _StatDivider(),
          _StatCell(emoji: '✝', value: '$pct%', label: 'complete'),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatCell(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(text: '$emoji ', style: const TextStyle(fontSize: 13)),
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: MyWalkColor.warmWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: MyWalkColor.softGold.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 28, color: MyWalkColor.cardBorder);
}

// ── Pending banner ─────────────────────────────────────────────────────────────

class _PendingBanner extends StatelessWidget {
  final BibleReadingProvider provider;
  const _PendingBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final state = provider.state!;
    final liveDate = state.liveDate!;
    final days = provider.daysUntilLive ?? 0;
    final dateStr = DateFormat('MMMM d').format(liveDate);
    final countdown = days == 0
        ? 'Your plan begins this Sunday.'
        : 'Your plan begins Sunday, $dateStr — $days ${days == 1 ? 'day' : 'days'} away.';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MyWalkColor.golden.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: MyWalkColor.golden.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: MyWalkColor.golden, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              countdown,
              style: const TextStyle(color: MyWalkColor.softGold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Not started ────────────────────────────────────────────────────────────────

class _NotStartedView extends StatelessWidget {
  final VoidCallback onStart;
  const _NotStartedView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded, color: MyWalkColor.golden, size: 48),
            const SizedBox(height: 20),
            Text(
              'Bible in a Year',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: MyWalkColor.warmWhite,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A balanced daily reading plan covering all 66 books — Psalms, New Testament, Torah, Historical, Prophetic, and Wisdom literature.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MyWalkColor.softGold.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Plan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Week accordion ─────────────────────────────────────────────────────────────

class _WeekAccordion extends StatelessWidget {
  final int weekIndex;
  final BibleReadingProvider provider;
  final bool isExpanded;
  final bool isCurrent;
  final VoidCallback onToggle;
  final void Function(int) onDayTap;

  const _WeekAccordion({
    super.key,
    required this.weekIndex,
    required this.provider,
    required this.isExpanded,
    required this.isCurrent,
    required this.onToggle,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = provider.state;
    final weekDays = BibleReadingPlanData.weeks[weekIndex];
    final daysComplete = state == null
        ? 0
        : weekDays.asMap().entries
            .where((e) => state.isDayDone(weekIndex, e.key, e.value))
            .length;
    final isWeekDone = daysComplete == weekDays.length;
    final summary = _weekSummary(weekIndex);
    final progress = daysComplete / weekDays.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWeekDone
              ? [const Color(0xFF2C3B2E), const Color(0xFF232E26)]
              : [const Color(0xFF3A342D), const Color(0xFF2E2923)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? MyWalkColor.golden.withValues(alpha: 0.5)
              : isWeekDone
                  ? const Color(0xFF7A9E7E).withValues(alpha: 0.3)
                  : const Color(0x20D4A843),
          width: isCurrent ? 1.0 : 0.5,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: MyWalkColor.golden.withValues(alpha: 0.18),
                  blurRadius: 14,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Circular progress ring
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3.5,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isWeekDone
                                  ? const Color(0xFF7A9E7E)
                                  : isCurrent
                                      ? MyWalkColor.golden
                                      : const Color(0x60D4A843),
                            ),
                          ),
                          Center(
                            child: isWeekDone
                                ? const Icon(Icons.check,
                                    color: Color(0xFF7A9E7E), size: 18)
                                : Text(
                                    '${weekIndex + 1}',
                                    style: TextStyle(
                                      color: isCurrent
                                          ? MyWalkColor.golden
                                          : MyWalkColor.softGold,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Week ${weekIndex + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? MyWalkColor.warmWhite
                                  : MyWalkColor.softGold,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (summary.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              summary,
                              style: TextStyle(
                                color: MyWalkColor.softGold.withValues(alpha: 0.55),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$daysComplete/7',
                        style: TextStyle(
                          color: isWeekDone
                              ? const Color(0xFF7A9E7E)
                              : MyWalkColor.softGold.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: MyWalkColor.softGold.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            // Day rows
            if (isExpanded)
              Column(
                children: [
                  Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08)),
                  ...List.generate(weekDays.length, (d) {
                    return _DayRow(
                      weekIndex: weekIndex,
                      dayIndex: d,
                      provider: provider,
                      onTap: () => onDayTap(d),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _weekSummary(int w) {
    final days = BibleReadingPlanData.weeks[w];
    final books = <String>{};
    for (final day in days) {
      for (final s in BibleReadingSection.ordered) {
        final refs = day.refsForSection(s);
        if (refs.isNotEmpty) {
          final label = refs.first.label;
          final space = label.indexOf(' ');
          if (space > 0) books.add(label.substring(0, space));
          if (books.length >= 4) break;
        }
      }
      if (books.length >= 4) break;
    }
    return books.join(' · ');
  }
}

// ── Day row ────────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final int weekIndex;
  final int dayIndex;
  final BibleReadingProvider provider;
  final VoidCallback onTap;

  const _DayRow({
    required this.weekIndex,
    required this.dayIndex,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = provider.state;
    final dayPlan = BibleReadingPlanData.weeks[weekIndex][dayIndex];
    final isDone = state?.isDayDone(weekIndex, dayIndex, dayPlan) ?? false;
    final isCurrent = provider.currentWeekIndex == weekIndex &&
        provider.currentDayIndex == dayIndex;
    final dayName = BibleReadingPlanData.dayNames[dayIndex];
    final activeSections = dayPlan.activeSections;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isDone
              ? MyWalkColor.sage.withValues(alpha: 0.07)
              : isCurrent
                  ? MyWalkColor.golden.withValues(alpha: 0.04)
                  : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: MyWalkColor.cardBorder, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Done / current indicator
            SizedBox(
              width: 20,
              child: isDone
                  ? const Icon(Icons.check_circle,
                      color: MyWalkColor.sage, size: 16)
                  : isCurrent
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: MyWalkColor.golden,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
            ),
            const SizedBox(width: 6),
            // Day name
            SizedBox(
              width: 30,
              child: Text(
                dayName,
                style: TextStyle(
                  color: isCurrent ? MyWalkColor.warmWhite : MyWalkColor.softGold,
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Reading count
            Text(
              '${activeSections.length} readings',
              style: TextStyle(
                color: isDone
                    ? MyWalkColor.sage.withValues(alpha: 0.7)
                    : MyWalkColor.softGold.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
            const Icon(Icons.chevron_right,
                color: MyWalkColor.softGold, size: 14),
          ],
        ),
      ),
    );
  }
}
