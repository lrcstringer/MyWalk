import 'package:flutter/material.dart';
import '../../../../presentation/theme/app_theme.dart';

// GitHub-style contribution calendar showing review activity for the last
// [_weeks] weeks. Each cell represents one day; colour intensity reflects
// the number of reviews that day.

class ReviewCalendarHeatmap extends StatelessWidget {
  final List<DateTime> reviewDates;

  static const _weeks = 12;

  const ReviewCalendarHeatmap({super.key, required this.reviewDates});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Count reviews per calendar day.
    final Map<DateTime, int> counts = {};
    for (final d in reviewDates) {
      final day = DateTime(d.year, d.month, d.day);
      counts[day] = (counts[day] ?? 0) + 1;
    }

    // Align start to Monday of the week [_weeks] weeks ago.
    final todayWeekday = today.weekday; // 1=Mon, 7=Sun
    final startOfCurrentWeek = today.subtract(Duration(days: todayWeekday - 1));
    final start = startOfCurrentWeek.subtract(Duration(days: (_weeks - 1) * 7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review activity',
          style: TextStyle(
            color: MyWalkColor.warmWhite.withValues(alpha: 0.5),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        // The grid: [_weeks] columns (weeks) × 7 rows (days Mon–Sun).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_weeks, (week) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: week < _weeks - 1 ? 3 : 0),
                child: Column(
                  children: List.generate(7, (dayOfWeek) {
                    final date = start.add(Duration(days: week * 7 + dayOfWeek));
                    final isFuture = date.isAfter(today);
                    final isToday = date == today;
                    final count = isFuture ? 0 : (counts[date] ?? 0);
                    return _DayCell(
                      count: count,
                      isFuture: isFuture,
                      isToday: isToday,
                    );
                  }),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Legend row.
        Row(
          children: [
            const Spacer(),
            Text(
              'Less ',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
            ...[0, 1, 2, 3].map((i) => Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: _LegendCell(level: i),
                )),
            Text(
              ' More',
              style: TextStyle(
                color: MyWalkColor.warmWhite.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int count;
  final bool isFuture;
  final bool isToday;

  const _DayCell({
    required this.count,
    required this.isFuture,
    required this.isToday,
  });

  Color get _color {
    if (isFuture) return Colors.transparent;
    if (count == 0) return Colors.white10;
    if (count == 1) return const Color(0xFF7A9E7E).withValues(alpha: 0.35);
    if (count == 2) return const Color(0xFF7A9E7E).withValues(alpha: 0.6);
    return const Color(0xFF7A9E7E).withValues(alpha: 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 11,
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(2),
        border: isToday
            ? Border.all(color: MyWalkColor.golden, width: 1)
            : null,
      ),
    );
  }
}

class _LegendCell extends StatelessWidget {
  final int level; // 0–3

  const _LegendCell({required this.level});

  static const _colors = [
    Colors.white10,
    Color(0xFF7A9E7E),
    Color(0xFF7A9E7E),
    Color(0xFF7A9E7E),
  ];
  static const _alphas = [1.0, 0.35, 0.6, 0.9];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _colors[level].withValues(alpha: _alphas[level]),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
