import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/datasources/remote/auth_service.dart';
import '../../../../domain/entities/memorization_circle.dart';
import '../../../../presentation/providers/memorization_provider.dart';
import '../../../../presentation/theme/app_theme.dart';
import 'circle_leaderboard_screen.dart';
import 'create_circle_screen.dart';

class MemorizationCirclesScreen extends StatelessWidget {
  const MemorizationCirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        title: const Text('Memorization Circles'),
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MyWalkColor.golden,
        foregroundColor: MyWalkColor.charcoal,
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('New circle'),
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const CreateCircleScreen()),
        ),
      ),
      body: StreamBuilder<List<MemorizationCircle>>(
        stream: context.read<MemorizationProvider>().watchCircles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: MyWalkColor.golden));
          }

          final circles = snapshot.data ?? [];

          if (circles.isEmpty) {
            return _EmptyState(
              onCreate: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const CreateCircleScreen()),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: circles.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _CircleTile(
              circle: circles[i],
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => CircleLeaderboardScreen(circle: circles[i]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CircleTile extends StatelessWidget {
  final MemorizationCircle circle;
  final VoidCallback onTap;

  const _CircleTile({required this.circle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.shared.userId ?? '';
    final myMastery = circle.memberMastery[uid] ?? 0.0;
    final memberCount = circle.memberIds.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyWalkColor.golden.withValues(alpha: 0.12),
                border: Border.all(
                    color: MyWalkColor.golden.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.groups_2_outlined,
                  color: MyWalkColor.golden, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    circle.name,
                    style: const TextStyle(
                      color: MyWalkColor.warmWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    circle.itemTitle,
                    style: TextStyle(
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 12,
                          color:
                              MyWalkColor.warmWhite.withValues(alpha: 0.35)),
                      const SizedBox(width: 4),
                      Text(
                        '$memberCount member${memberCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.35),
                          fontSize: 11,
                        ),
                      ),
                      if (circle.targetDate != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today_outlined,
                            size: 12,
                            color:
                                MyWalkColor.warmWhite.withValues(alpha: 0.35)),
                        const SizedBox(width: 4),
                        Text(
                          _daysLabel(circle.targetDate!),
                          style: TextStyle(
                            color:
                                MyWalkColor.warmWhite.withValues(alpha: 0.35),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '${myMastery.toInt()}%',
                  style: const TextStyle(
                    color: MyWalkColor.golden,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'your mastery',
                  style: TextStyle(
                    color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  String _daysLabel(DateTime target) {
    final diff = target.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Ended';
    if (diff == 0) return 'Today';
    return '$diff days left';
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_2_outlined,
                size: 64,
                color: MyWalkColor.golden.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            Text(
              'Memorize together',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: MyWalkColor.warmWhite,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a circle to memorize scripture\nalongside your friends.',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: MyWalkButtonStyle.primary(),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Create a circle'),
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}
