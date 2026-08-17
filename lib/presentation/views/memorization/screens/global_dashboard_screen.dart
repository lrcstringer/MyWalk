import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../widgets/achievement_badge.dart';
import '../memorization_router.dart';

class GlobalDashboardScreen extends StatelessWidget {
  const GlobalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemorizationProvider>();
    final items = provider.items
        .where((i) => i.status != MemorizationStatus.archived)
        .toList();

    final totalAttempts =
        items.fold<int>(0, (sum, i) => sum + i.totalAttempts);
    final totalSuccessful =
        items.fold<int>(0, (sum, i) => sum + i.successfulAttempts);
    final overallMastery = totalAttempts == 0
        ? 0.0
        : totalSuccessful / totalAttempts * 100;
    final masteredCount =
        items.where((i) => i.status == MemorizationStatus.mastered).length;
    final maxStreak = items.fold<int>(
        0, (max, i) => i.streakCount > max ? i.streakCount : max);
    final totalWords = items.fold<int>(
        0, (sum, i) => sum + i.fullText.trim().split(RegExp(r'\s+')).length);

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: Text(
          'My Progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: MyWalkColor.warmWhite,
          ),
        ),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DeepSpaceBackground(),
            ),
          ),
          CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _OverallMasteryCard(mastery: overallMastery),
                const SizedBox(height: 16),
                _SummaryGrid(
                  itemCount: items.length,
                  totalAttempts: totalAttempts,
                  masteredCount: masteredCount,
                  maxStreak: maxStreak,
                  totalWords: totalWords,
                ),
                const SizedBox(height: 16),
                _ItemsList(items: items),
                const SizedBox(height: 16),
                _AchievementsCard(maxStreak: maxStreak, masteredCount: masteredCount),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}

class _OverallMasteryCard extends StatelessWidget {
  final double mastery;
  const _OverallMasteryCard({required this.mastery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Overall mastery',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: mastery / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      MyWalkColor.golden),
                ),
              ),
              Text(
                '${mastery.toInt()}%',
                style: const TextStyle(
                  color: MyWalkColor.golden,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"His word have I hid in mine heart…" — Psalm 119:11',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.35),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final int itemCount;
  final int totalAttempts;
  final int masteredCount;
  final int maxStreak;
  final int totalWords;

  const _SummaryGrid({
    required this.itemCount,
    required this.totalAttempts,
    required this.masteredCount,
    required this.maxStreak,
    required this.totalWords,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StatTile(label: 'Verses', value: '$itemCount'),
            const SizedBox(width: 10),
            _StatTile(label: 'Reviews', value: '$totalAttempts'),
            const SizedBox(width: 10),
            _StatTile(label: 'Mastered', value: '$masteredCount'),
            const SizedBox(width: 10),
            _StatTile(label: 'Best streak', value: '${maxStreak}d'),
          ],
        ),
        const SizedBox(height: 10),
        _StatTile(
          label: 'Words in your heart',
          value: '$totalWords',
          wide: true,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool wide;

  const _StatTile({required this.label, required this.value, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: MyWalkColor.warmWhite,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
    return wide ? container : Expanded(child: container);
  }
}

class _ItemsList extends StatelessWidget {
  final List<MemorizationItem> items;
  const _ItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final sorted = [...items]
      ..sort((a, b) => b.masteryPercent.compareTo(a.masteryPercent));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items by mastery',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map((item) => InkWell(
                onTap: () => MemorizationRouter.pushItemDashboard(context, item),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: MyWalkColor.warmWhite,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(
                        value: item.masteryPercent / 100,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item.masteryPercent >= 80
                              ? const Color(0xFF7A9E7E)
                              : item.masteryPercent >= 50
                                  ? MyWalkColor.golden
                                  : const Color(0xFFD4836B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.masteryPercent.toInt()}%',
                      style: TextStyle(
                        color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
                )),
        ],
      ),
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  final int maxStreak;
  final int masteredCount;

  const _AchievementsCard({
    required this.maxStreak,
    required this.masteredCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              AchievementBadge(
                type: AchievementType.streak7,
                unlocked: maxStreak >= 7,
              ),
              AchievementBadge(
                type: AchievementType.streak30,
                unlocked: maxStreak >= 30,
              ),
              AchievementBadge(
                type: AchievementType.streak100,
                unlocked: maxStreak >= 100,
              ),
              AchievementBadge(
                type: AchievementType.mastered,
                unlocked: masteredCount >= 1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
