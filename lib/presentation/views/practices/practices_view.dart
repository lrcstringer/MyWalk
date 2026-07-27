import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_category_model.dart';
import '../../../domain/entities/bible_reading_plan.dart';
import '../../../domain/services/week_cycle_manager.dart';
import '../../providers/bible_reading_provider.dart';
import '../../providers/habit_category_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icons.dart';
import '../bible_reading/bible_reading_grid_view.dart';
import '../habits/add_habit_view.dart';
import '../habits/habit_detail_view.dart';
import '../memorization/memorization_router.dart';
import '../shared/appbar_actions.dart';
import '../shared/mywalk_paywall_view.dart';
import '../help/practices_help_view.dart';
import 'breaking_free_intro_screen.dart';

class PracticesView extends StatelessWidget {
  final WeekCycleManager weekCycleManager;

  const PracticesView({super.key, required this.weekCycleManager});

  static const _hiddenCategoryIds = {'fruit_of_the_spirit', 'the_beatitudes'};

  @override
  Widget build(BuildContext context) {
    final habits = context
        .watch<HabitProvider>()
        .sortedHabits
        .where((h) => !h.isBuiltIn && !h.isArchived)
        .toList();
    final categories = context
        .watch<HabitCategoryProvider>()
        .categories
        .where((c) => !_hiddenCategoryIds.contains(c.id))
        .toList();
    final isPremium = context.watch<StoreProvider>().isPremium;
    final imageHeight = MediaQuery.of(context).size.width * (2.0 / 3.0);

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            expandedHeight: imageHeight,
            pinned: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'MyWalk',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              ...standardAppBarActions(context, helpView: const PracticesHelpView()),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/progress.webp', fit: BoxFit.cover),
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
                  const Positioned(
                    left: 20,
                    right: 20,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practices',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '‘Train yourself to be godly.’',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: MyWalkColor.softGold,
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '1 Timothy 4:7',
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Your Practices (management mode) ──────────────────────
                if (habits.isNotEmpty) ...[
                  _sectionLabel('YOUR PRACTICES'),
                  const SizedBox(height: 10),
                  _ManagementCard(habits: habits),
                  const SizedBox(height: 28),
                ],

                // ── Daily Practices (discovery) ────────────────────────────
                _sectionLabel('ADD A PRACTICE'),
                const SizedBox(height: 4),
                Text(
                  'Choose a discipline to add to your daily walk.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 14),
                _CategoryDiscoveryGrid(categories: categories),
                const SizedBox(height: 12),
                const _BreakingFreeCard(),
                const SizedBox(height: 28),

                // ── Programmes divider ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 0.5,
                        color: MyWalkColor.golden.withValues(alpha: 0.18),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 11,
                              color: MyWalkColor.golden.withValues(alpha: 0.45)),
                          const SizedBox(width: 5),
                          Text(
                            'PROGRAMMES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: MyWalkColor.golden.withValues(alpha: 0.45),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.star_rounded,
                              size: 11,
                              color: MyWalkColor.golden.withValues(alpha: 0.45)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 0.5,
                        color: MyWalkColor.golden.withValues(alpha: 0.18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Bible in a Year ────────────────────────────────────────
                const _BibleInAYearCard(),
                const SizedBox(height: 12),

                // ── Scripture Memorization ─────────────────────────────────
                _MemorizationCard(isPremium: isPremium),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.4),
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Management card ───────────────────────────────────────────────────────────

class _ManagementCard extends StatelessWidget {
  final List<Habit> habits;
  const _ManagementCard({required this.habits});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: MyWalkDecorations.card,
      child: Column(
        children: habits.asMap().entries.map((entry) {
          final i = entry.key;
          final h = entry.value;
          return Column(
            children: [
              GestureDetector(
                onTap: () => _showDetail(context, h),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accentFor(h).withValues(alpha: 0.12),
                        ),
                        child: Icon(_iconFor(h),
                            size: 16, color: _accentFor(h)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: MyWalkColor.warmWhite,
                              ),
                            ),
                            if (h.subcategoryName != null &&
                                h.subcategoryName!.isNotEmpty)
                              Text(
                                h.subcategoryName!,
                                style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.white.withValues(alpha: 0.4)),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.25)),
                    ],
                  ),
                ),
              ),
              if (i < habits.length - 1)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.07),
                  indent: 62,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showDetail(BuildContext context, Habit habit) {
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
        builder: (ctx, sc) =>
            HabitDetailView(habit: habit, scrollController: sc),
      ),
    );
  }

  Color _accentFor(Habit h) =>
      h.trackingType == HabitTrackingType.abstain
          ? MyWalkColor.sage
          : MyWalkColor.golden;

  IconData _iconFor(Habit h) {
    if (h.trackingType == HabitTrackingType.abstain) return Icons.shield_rounded;
    switch (h.category) {
      case HabitCategory.gratitude:
        return Icons.auto_awesome;
      case HabitCategory.scripture:
        return Icons.menu_book;
      case HabitCategory.exercise:
        return Icons.fitness_center;
      case HabitCategory.rest:
        return Icons.bedtime;
      case HabitCategory.fasting:
        return Icons.no_food;
      case HabitCategory.study:
        return Icons.school;
      case HabitCategory.service:
        return Icons.volunteer_activism;
      case HabitCategory.connection:
        return Icons.people;
      case HabitCategory.health:
        return Icons.favorite;
      case HabitCategory.abstain:
        return Icons.shield_rounded;
      case HabitCategory.prayer:
        return Icons.self_improvement_rounded;
      case HabitCategory.custom:
        return Icons.star;
    }
  }
}

// ── Category discovery grid ───────────────────────────────────────────────────

class _CategoryDiscoveryGrid extends StatelessWidget {
  final List<HabitCategoryModel> categories;
  const _CategoryDiscoveryGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        final catColor = _hexColor(cat.colourHex);
        return GestureDetector(
          onTap: () => _openAddPractice(context, cat),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MyWalkColor.cardBackground,
                  catColor.withValues(alpha: 0.22),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: catColor.withValues(alpha: 0.65), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: catColor.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: catColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(iconForKey(cat.iconKey),
                      size: 24, color: catColor),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.name,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MyWalkColor.warmWhite,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  void _openAddPractice(BuildContext context, HabitCategoryModel category) {
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
        minChildSize: 0.6,
        expand: false,
        builder: (ctx, sc) => AddHabitView(
          scrollController: sc,
          startCategoryModel: category,
        ),
      ),
    );
  }
}

// ── Breaking Free card ────────────────────────────────────────────────────────

class _BreakingFreeCard extends StatelessWidget {
  const _BreakingFreeCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BreakingFreeIntroScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyWalkColor.cardBackground,
              MyWalkColor.sage.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: MyWalkColor.sage.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyWalkColor.sage.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: MyWalkColor.sage, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Breaking Free',
                    style: TextStyle(
                      color: MyWalkColor.warmWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Overcome challenges with accountability and a recovery path',
                    style: TextStyle(
                      color: MyWalkColor.sage,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: MyWalkColor.sage.withValues(alpha: 0.6), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Bible in a Year card ──────────────────────────────────────────────────────

class _BibleInAYearCard extends StatelessWidget {
  const _BibleInAYearCard();

  Future<void> _confirmEndPlan(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        title: const Text('End Bible Plan?',
            style: TextStyle(color: MyWalkColor.warmWhite)),
        content: const Text(
          'Your progress will be lost and the plan will be removed. You can start again at any time.',
          style: TextStyle(color: MyWalkColor.softGold, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: MyWalkColor.softGold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Plan',
                style: TextStyle(color: MyWalkColor.warmCoral)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<BibleReadingProvider>().resetPlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BibleReadingProvider>();
    final isActive = provider.status != BibleReadingPlanStatus.notStarted;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BibleReadingGridView()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyWalkColor.cardBackground,
              MyWalkColor.golden.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: MyWalkColor.golden.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: MyWalkColor.golden.withValues(alpha: 0.10),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MyWalkColor.golden.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: MyWalkColor.golden, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bible in a Year',
                        style: TextStyle(
                          color: MyWalkColor.warmWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Daily reading plan · 52 weeks',
                        style: TextStyle(
                          color: MyWalkColor.softGold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  GestureDetector(
                    onTap: () {}, // absorb tap so card navigation doesn't fire
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'end') _confirmEndPlan(context);
                      },
                      color: MyWalkColor.cardBackground,
                      icon: Icon(Icons.more_vert,
                          color: MyWalkColor.softGold.withValues(alpha: 0.6),
                          size: 20),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'end',
                          child: Text('End Plan',
                              style: TextStyle(
                                  color: MyWalkColor.warmCoral, fontSize: 14)),
                        ),
                      ],
                    ),
                  )
                else
                  Icon(Icons.chevron_right,
                      color: MyWalkColor.softGold.withValues(alpha: 0.6),
                      size: 20),
              ],
            ),
            const SizedBox(height: 14),
            _BiblePlanBody(provider: provider),
          ],
        ),
      ),
    );
  }
}

class _BiblePlanBody extends StatelessWidget {
  final BibleReadingProvider provider;
  const _BiblePlanBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    switch (provider.status) {
      case BibleReadingPlanStatus.notStarted:
        return Text(
          'Read through all 66 books in one year — Psalms, New Testament, Torah, Historical, Prophetic, and Wisdom literature. Tap to begin.',
          style: TextStyle(
            color: MyWalkColor.softGold.withValues(alpha: 0.75),
            fontSize: 12,
            height: 1.5,
          ),
        );
      case BibleReadingPlanStatus.pending:
        final days = provider.daysUntilLive ?? 0;
        return Row(children: [
          const Icon(Icons.schedule, color: MyWalkColor.golden, size: 14),
          const SizedBox(width: 6),
          Text(
            days == 0
                ? 'Begins this Sunday'
                : 'Begins in $days ${days == 1 ? 'day' : 'days'}',
            style:
                const TextStyle(color: MyWalkColor.softGold, fontSize: 12),
          ),
        ]);
      case BibleReadingPlanStatus.active:
        final daysRead = provider.totalDaysRead;
        final progress = (daysRead / 364.0).clamp(0.0, 1.0);
        final streak = provider.state?.streakDays ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor:
                    const AlwaysStoppedAnimation(MyWalkColor.golden),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text(
                '$daysRead of 364 days read',
                style: TextStyle(
                    fontSize: 11,
                    color: MyWalkColor.softGold.withValues(alpha: 0.7)),
              ),
              if (streak > 1) ...[
                const Spacer(),
                const Icon(Icons.local_fire_department,
                    size: 11, color: MyWalkColor.golden),
                const SizedBox(width: 3),
                Text('$streak day streak',
                    style: const TextStyle(
                        fontSize: 11, color: MyWalkColor.golden)),
              ],
            ]),
          ],
        );
    }
  }
}

// ── Scripture Memorization card ───────────────────────────────────────────────

class _MemorizationCard extends StatelessWidget {
  final bool isPremium;
  const _MemorizationCard({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isPremium) {
          MemorizationRouter.pushHome(context);
        } else {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: MyWalkColor.charcoal,
            builder: (_) => const MyWalkPaywallView(),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyWalkColor.cardBackground,
              isPremium
                  ? MyWalkColor.golden.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPremium
                ? MyWalkColor.golden.withValues(alpha: 0.35)
                : MyWalkColor.cardBorder,
            width: isPremium ? 1.5 : 0.5,
          ),
          boxShadow: isPremium
              ? [
                  BoxShadow(
                    color: MyWalkColor.golden.withValues(alpha: 0.10),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPremium
                    ? MyWalkColor.golden.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.psychology,
                color: isPremium
                    ? MyWalkColor.golden
                    : Colors.white.withValues(alpha: 0.3),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scripture Memorization',
                    style: TextStyle(
                      color: isPremium
                          ? MyWalkColor.warmWhite
                          : MyWalkColor.warmWhite.withValues(alpha: 0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Hide His word in your heart',
                    style: TextStyle(
                      color: isPremium
                          ? MyWalkColor.softGold
                          : Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!isPremium)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MyWalkColor.golden.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Icon(Icons.workspace_premium,
                      size: 10, color: MyWalkColor.golden),
                  SizedBox(width: 3),
                  Text('PRO',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: MyWalkColor.golden)),
                ]),
              )
            else
              Icon(Icons.chevron_right,
                  color: MyWalkColor.softGold.withValues(alpha: 0.6),
                  size: 20),
          ],
        ),
      ),
    );
  }
}
