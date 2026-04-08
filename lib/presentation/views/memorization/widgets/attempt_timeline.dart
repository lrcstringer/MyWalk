import 'package:flutter/material.dart';
import '../../../../domain/entities/memorization_item.dart';
import '../../../../presentation/theme/app_theme.dart';

class AttemptTimeline extends StatelessWidget {
  final List<ReviewAttempt> attempts;

  const AttemptTimeline({super.key, required this.attempts});

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) {
      return Text(
        'No reviews yet',
        style: TextStyle(
          color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
          fontSize: 13,
        ),
      );
    }

    final sorted = [...attempts]
      ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    final recent = sorted.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent reviews',
          style: TextStyle(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) => _AttemptDot(attempt: recent[i]),
          ),
        ),
      ],
    );
  }
}

class _AttemptDot extends StatelessWidget {
  final ReviewAttempt attempt;
  const _AttemptDot({required this.attempt});

  Color get _color {
    if (attempt.qualityScore >= 4) return const Color(0xFF7A9E7E);
    if (attempt.qualityScore >= 3) return MyWalkColor.golden;
    return Colors.red.shade400;
  }

  String get _modeLabel {
    return switch (attempt.mode) {
      ReviewMode.flipCard => 'Flip',
      ReviewMode.cloze => 'Fill',
      ReviewMode.progressive => 'Step',
      ReviewMode.typing => 'Type',
      ReviewMode.recitation => 'Speak',
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(attempt.attemptedAt);
    final String dateLabel;
    if (diff.inDays == 0) {
      dateLabel = 'Today';
    } else if (diff.inDays == 1) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = '${diff.inDays}d ago';
    }

    return Tooltip(
      message: '${attempt.mode.name} · q=${attempt.qualityScore} · $dateLabel',
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.15),
              border: Border.all(color: _color.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                '${attempt.qualityScore}',
                style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _modeLabel,
            style: TextStyle(
              color: MyWalkColor.warmWhite.withValues(alpha: 0.35),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
