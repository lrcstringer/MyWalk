import 'package:flutter/material.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';

class MemorizationListTile extends StatelessWidget {
  final MemorizationItem item;
  final VoidCallback onTap;
  final VoidCallback onReview;
  final VoidCallback onArchive;

  const MemorizationListTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onReview,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final isDue = item.isDueNow;
    final mastery = item.masteryPercent / 100;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.archive_outlined, color: Colors.white),
            SizedBox(height: 4),
            Text('Archive', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: MyWalkColor.cardBackground,
            title: const Text('Archive item?'),
            content: Text('Archive "${item.title}"? You can unarchive it later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Archive', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onArchive(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: MyWalkDecorations.card,
          child: Row(
            children: [
              // Mastery ring
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: mastery,
                      strokeWidth: 4,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(_masteryColor(mastery)),
                    ),
                    Center(
                      child: Text(
                        '${item.masteryPercent.toInt()}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Title + due date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: MyWalkColor.warmWhite,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _DueChip(item: item),
                        if (item.streakCount > 0) ...[
                          const SizedBox(width: 8),
                          _StreakBadge(count: item.streakCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Review button (only if due)
              if (isDue)
                FilledButton(
                  onPressed: onReview,
                  style: FilledButton.styleFrom(
                    backgroundColor: MyWalkColor.golden,
                    foregroundColor: MyWalkColor.charcoal,
                    minimumSize: const Size(72, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                )
              else
                Icon(Icons.chevron_right, color: MyWalkColor.warmWhite.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Color _masteryColor(double mastery) {
    if (mastery >= 0.80) return const Color(0xFF7A9E7E); // sage green
    if (mastery >= 0.50) return const Color(0xFFD4A843); // golden amber
    return const Color(0xFFD4836B); // warm coral
  }
}

class _DueChip extends StatelessWidget {
  final MemorizationItem item;
  const _DueChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = item.nextReviewDate.difference(now);
    String label;
    Color color;

    if (item.status == MemorizationStatus.mastered) {
      label = 'Hidden in your heart';
      color = const Color(0xFF7A9E7E);
    } else if (diff.isNegative) {
      final hours = diff.inHours.abs();
      label = hours < 24 ? 'Due ${hours}h ago' : 'Due ${diff.inDays.abs()}d ago';
      color = Colors.red.shade400;
    } else if (diff.inHours < 1) {
      label = 'Due in ${diff.inMinutes}m';
      color = MyWalkColor.golden;
    } else if (diff.inHours < 24) {
      label = 'Due in ${diff.inHours}h';
      color = MyWalkColor.golden;
    } else {
      label = 'Due in ${diff.inDays}d';
      color = MyWalkColor.warmWhite.withValues(alpha: 0.5);
    }

    return Text(label, style: TextStyle(fontSize: 12, color: color));
  }
}

class _StreakBadge extends StatelessWidget {
  final int count;
  const _StreakBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (count >= 100) {
      color = Colors.purple.shade400;
    } else if (count >= 30) {
      color = Colors.orange.shade400;
    } else if (count >= 7) {
      color = MyWalkColor.golden;
    } else {
      color = MyWalkColor.warmWhite.withValues(alpha: 0.4);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, size: 13, color: color),
        Text('$count', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
