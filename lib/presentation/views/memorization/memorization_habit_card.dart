import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/memorization_provider.dart';
import '../../theme/app_theme.dart';
import 'memorization_router.dart';

class MemorizationHabitCard extends StatelessWidget {
  const MemorizationHabitCard({super.key});

  static const _purple = Color(0xFF8B7EC8);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemorizationProvider>();

    // Only surface the card once the user has at least one item.
    if (provider.items.isEmpty) return const SizedBox.shrink();

    final dueCount = provider.dueItems.length;
    final activeCount = provider.activeItems.length;
    final masteredCount = provider.masteredItems.length;

    final bool hasDue = dueCount > 0;

    String subtitle;
    if (hasDue) {
      subtitle = '$dueCount ${dueCount == 1 ? 'verse' : 'verses'} due for review today';
    } else if (activeCount > 0) {
      subtitle = '$activeCount ${activeCount == 1 ? 'verse' : 'verses'} in progress';
    } else {
      subtitle =
          '$masteredCount ${masteredCount == 1 ? 'verse' : 'verses'} hidden in your heart';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        onTap: () => MemorizationRouter.pushHome(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: MyWalkColor.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _purple.withValues(alpha: hasDue ? 0.45 : 0.2),
              width: hasDue ? 1.0 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _purple.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.psychology, color: _purple, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meditating on His Word',
                      style: TextStyle(
                        color: MyWalkColor.warmWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (hasDue)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: MyWalkColor.warmCoral,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: MyWalkColor.warmCoral.withValues(alpha: 0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: MyWalkColor.softGold.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _purple.withValues(alpha: 0.55),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
