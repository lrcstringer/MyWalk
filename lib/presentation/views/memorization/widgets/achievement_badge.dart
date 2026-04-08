import 'package:flutter/material.dart';
import '../../../../presentation/theme/app_theme.dart';

enum AchievementType { streak7, streak30, streak100, mastered, firstReview }

class AchievementBadge extends StatelessWidget {
  final AchievementType type;
  final bool unlocked;

  const AchievementBadge({
    super.key,
    required this.type,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _info();
    return Opacity(
      opacity: unlocked ? 1.0 : 0.25,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(
                color: unlocked ? color : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: unlocked ? color : Colors.white24, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: unlocked
                  ? MyWalkColor.warmWhite.withValues(alpha: 0.8)
                  : Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  (IconData, String, Color) _info() {
    return switch (type) {
      AchievementType.streak7 => (
          Icons.local_fire_department,
          '7-day\nstreak',
          MyWalkColor.golden,
        ),
      AchievementType.streak30 => (
          Icons.local_fire_department,
          '30-day\nstreak',
          Colors.orange.shade400,
        ),
      AchievementType.streak100 => (
          Icons.local_fire_department,
          '100-day\nstreak',
          Colors.purple.shade400,
        ),
      AchievementType.mastered => (
          Icons.auto_stories,
          'Hidden in\nyour heart',
          const Color(0xFF7A9E7E),
        ),
      AchievementType.firstReview => (
          Icons.star_outline,
          'First\nreview',
          MyWalkColor.golden,
        ),
    };
  }
}
