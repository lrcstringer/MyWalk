import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/bible_reading_plan.dart';
import '../../providers/bible_reading_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import '../bible_reading/bible_reading_grid_view.dart';
import '../habits/add_habit_view.dart';
import '../habits/habit_detail_view.dart';
import '../memorization/memorization_router.dart';
import '../shared/appbar_actions.dart';
import '../shared/mywalk_paywall_view.dart';
import '../help/practices_help_view.dart';

class PracticesView extends StatelessWidget {
  const PracticesView({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = context
        .watch<HabitProvider>()
        .sortedHabits
        .where((h) => !h.isBuiltIn && !h.isArchived)
        .toList();
    final imageHeight = MediaQuery.of(context).size.width * (2.0 / 3.0);

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: Stack(children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: DeepSpaceBackground(),
          ),
        ),
        CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: MyWalkColor.charcoal,
            foregroundColor: MyWalkColor.warmWhite,
            expandedHeight: imageHeight,
            pinned: true,
            automaticallyImplyLeading: false,
            title: Text(
              'MyWalk',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20, color: MyWalkColor.warmWhite,
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
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practices',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: MyWalkColor.warmWhite, height: 1.1,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "'Train yourself to be godly.'",
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Action pills ───────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.add_rounded,
                      label: 'Add a Practice',
                      color: const Color(0xFF90EE90),
                      onTap: () => _openAddPractice(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.apps_rounded,
                      label: 'Mini-Apps',
                      color: const Color(0xFFE8A87C),
                      onTap: () => _openMiniApps(context),
                    ),
                  ),
                ]),

                // ── Your Practices ─────────────────────────────────────────
                if (habits.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _sectionLabel('YOUR PRACTICES'),
                  const SizedBox(height: 10),
                  _ManagementCard(habits: habits),
                ],
              ]),
            ),
          ),
        ],
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: IgnorePointer(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  MyWalkColor.charcoal.withValues(alpha: 0),
                  MyWalkColor.charcoal,
                ],
              ),
            ),
          ),
        ),
      ),
    ]),
    );
  }

  void _openAddPractice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, sc) => AddHabitView(scrollController: sc),
      ),
    );
  }

  void _openMiniApps(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, sc) => _MiniAppsSheet(scrollController: sc),
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

// ── Action pill ───────────────────────────────────────────────────────────────

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionPill({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyWalkColor.cardBackground,
              color.withValues(alpha: 0.22),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.65), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.warmWhite,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Mini-Apps sheet ───────────────────────────────────────────────────────────

class _MiniAppsSheet extends StatelessWidget {
  final ScrollController? scrollController;
  const _MiniAppsSheet({this.scrollController});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<StoreProvider>().isPremium;
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 8, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: MyWalkColor.warmWhite),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Mini-Apps',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 17, color: MyWalkColor.warmWhite,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: MyWalkColor.softGold.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Content ─────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              const _BibleInAYearCard(),
              const SizedBox(height: 12),
              _MemorizationCard(isPremium: isPremium),
            ],
          ),
        ),
      ],
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
              const Color(0xFF74B3CE).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF74B3CE).withValues(alpha: 0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF74B3CE).withValues(alpha: 0.15),
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
                    color: const Color(0xFF74B3CE).withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: Color(0xFF74B3CE), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bible in a Year',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16, color: MyWalkColor.warmWhite,
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
                      color: const Color(0xFF74B3CE).withValues(alpha: 0.7),
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
          const Icon(Icons.schedule, color: Color(0xFF74B3CE), size: 14),
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
                    const AlwaysStoppedAnimation(Color(0xFF74B3CE)),
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
                    size: 11, color: Color(0xFF74B3CE)),
                const SizedBox(width: 3),
                Text('$streak day streak',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF74B3CE))),
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
                  ? const Color(0xFF8B7EC8).withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPremium
                ? const Color(0xFF8B7EC8).withValues(alpha: 0.45)
                : MyWalkColor.cardBorder,
            width: isPremium ? 1.5 : 0.5,
          ),
          boxShadow: isPremium
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B7EC8).withValues(alpha: 0.15),
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
                    ? const Color(0xFF8B7EC8).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.psychology,
                color: isPremium
                    ? const Color(0xFF8B7EC8)
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isPremium
                          ? MyWalkColor.warmWhite
                          : MyWalkColor.warmWhite.withValues(alpha: 0.5),
                      fontSize: 16,
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
                  color: const Color(0xFF8B7EC8).withValues(alpha: 0.8),
                  size: 20),
          ],
        ),
      ),
    );
  }
}
