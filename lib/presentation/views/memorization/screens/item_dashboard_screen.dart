import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/attempt_timeline.dart';
import '../widgets/chunk_heat_map.dart';
import '../memorization_router.dart';

class ItemDashboardScreen extends StatelessWidget {
  final MemorizationItem item;

  const ItemDashboardScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: Text(item.title),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MasteryRing(item: item),
                const SizedBox(height: 24),
                _StatRow(item: item),
                const SizedBox(height: 24),
                _SectionCard(
                  child: ChunkHeatMap(chunks: item.chunks),
                ),
                const SizedBox(height: 16),
                _AchievementsRow(item: item),
                const SizedBox(height: 16),
                _AttemptsSection(item: item),
                const SizedBox(height: 24),
                if (item.isDueNow)
                  ElevatedButton.icon(
                    style: MyWalkButtonStyle.primary(),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Review now'),
                    onPressed: () =>
                        MemorizationRouter.pushModeSelection(context, item),
                  ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryRing extends StatelessWidget {
  final MemorizationItem item;
  const _MasteryRing({required this.item});

  @override
  Widget build(BuildContext context) {
    final mastery = item.masteryPercent / 100;
    final color = mastery >= 0.8
        ? const Color(0xFF7A9E7E)
        : mastery >= 0.5
            ? MyWalkColor.golden
            : const Color(0xFFD4836B);

    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: mastery,
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.masteryPercent.toInt()}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'mastery',
                        style: TextStyle(
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (item.status == MemorizationStatus.mastered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7A9E7E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF7A9E7E).withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Hidden in your heart',
                style: TextStyle(color: Color(0xFF7A9E7E), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final MemorizationItem item;
  const _StatRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(
          label: 'Reviews',
          value: '${item.totalAttempts}',
          icon: Icons.refresh,
        ),
        _StatCell(
          label: 'Streak',
          value: '${item.streakCount}',
          icon: Icons.local_fire_department,
        ),
        _StatCell(
          label: 'Interval',
          value: '${item.intervalDays.round()}d',
          icon: Icons.schedule,
        ),
        _StatCell(
          label: 'Ease',
          value: item.easeFactor.toStringAsFixed(1),
          icon: Icons.psychology_outlined,
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: MyWalkColor.golden),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: MyWalkColor.warmWhite,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _AchievementsRow extends StatelessWidget {
  final MemorizationItem item;
  const _AchievementsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
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
                type: AchievementType.firstReview,
                unlocked: item.totalAttempts >= 1,
              ),
              AchievementBadge(
                type: AchievementType.streak7,
                unlocked: item.streakCount >= 7,
              ),
              AchievementBadge(
                type: AchievementType.streak30,
                unlocked: item.streakCount >= 30,
              ),
              AchievementBadge(
                type: AchievementType.streak100,
                unlocked: item.streakCount >= 100,
              ),
              AchievementBadge(
                type: AchievementType.mastered,
                unlocked: item.status == MemorizationStatus.mastered,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttemptsSection extends StatelessWidget {
  final MemorizationItem item;
  const _AttemptsSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: StreamBuilder<List<ReviewAttempt>>(
        stream: context
            .read<MemorizationProvider>()
            .watchAttempts(item.id),
        builder: (context, snapshot) {
          final attempts = snapshot.data ?? [];
          return AttemptTimeline(attempts: attempts);
        },
      ),
    );
  }
}
