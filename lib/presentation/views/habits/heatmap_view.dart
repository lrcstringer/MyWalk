import 'package:flutter/material.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/services/daily_score_service.dart';
import '../../theme/app_theme.dart';

/// Single-habit heatmap.
///
/// Layout: 7 fixed rows (Sun–Sat) × weekCount scrollable columns (weeks).
/// Oldest week is on the left; newest is on the right and visible by default.
/// For weekCount == 1 a simple 7-tile row is used instead.
class HeatmapView extends StatelessWidget {
  final Habit habit;
  final int weekCount;

  const HeatmapView({super.key, required this.habit, required this.weekCount});

  static final _scoreService = DailyScoreService.instance;

  static const _tileSize = 10.0;
  static const _fillTileHeight = 16.0;
  static const _gap = 2.0;
  static const _stride = _tileSize + _gap;
  static const _dayLabelWidth = 14.0;
  static const _monthRowHeight = 13.0;
  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthAbbrs = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  List<List<_HeatmapDay>> _buildWeeks() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final daysSinceSunday = today.weekday % 7;
    final currentWeekStart = todayStart.subtract(Duration(days: daysSinceSunday));

    return List.generate(weekCount, (i) {
      final weekStart = currentWeekStart.add(Duration(days: (i - (weekCount - 1)) * 7));
      return List.generate(7, (d) {
        final date = weekStart.add(Duration(days: d));
        final isFuture = date.isAfter(todayStart);
        final score = isFuture ? 0.0 : _scoreService.habitScore(habit, date);
        final tier = isFuture
            ? DayTier.nothing
            : _scoreService.tierForScore(score < 0 ? 0 : score);
        return _HeatmapDay(date: date, isFuture: isFuture, tier: tier);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();
    final isAbstain = habit.trackingType == HabitTrackingType.abstain;
    final accent = isAbstain ? MyWalkColor.sage : MyWalkColor.golden;

    // Single week: plain horizontal row, tiles fill width.
    if (weeks.length == 1) {
      return Row(
        children: weeks.first.map((day) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: AspectRatio(
              aspectRatio: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: _tileFill(day, accent),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        )).toList(),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth;
      final gridWidth = available - _dayLabelWidth;
      // Expand tiles to fill when the natural content is narrower than available.
      final naturalWidth = weeks.length * _stride;
      final fill = naturalWidth < available;
      final tileWidth = fill
          ? (gridWidth / weeks.length - _gap).clamp(_tileSize, double.infinity)
          : _tileSize;
      final tileHeight = fill ? _fillTileHeight : _tileSize;
      final hStride = tileWidth + _gap;
      final vStride = tileHeight + _gap;

      final grid = _buildGrid(weeks, accent, tileWidth, tileHeight, hStride);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: _monthRowHeight + 1),
            child: Column(
              children: List.generate(7, (i) => SizedBox(
                width: _dayLabelWidth,
                height: vStride,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _dayLabels[i],
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              )),
            ),
          ),
          Expanded(
            child: fill
                ? grid
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: grid,
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildGrid(
    List<List<_HeatmapDay>> weeks,
    Color accent,
    double tileWidth,
    double tileHeight,
    double hStride,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month markers row.
        SizedBox(
          height: _monthRowHeight,
          child: Row(
            children: List.generate(weeks.length, (i) {
              final sunday = weeks[i].first.date;
              final showMonth =
                  i == 0 || sunday.month != weeks[i - 1].first.date.month;
              return SizedBox(
                width: hStride,
                child: showMonth
                    ? Text(
                        _monthAbbrs[sunday.month - 1],
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      )
                    : null,
              );
            }),
          ),
        ),
        // 7 day rows.
        ...List.generate(7, (dayIndex) => Row(
          children: weeks.map((week) {
            final day = week[dayIndex];
            return Padding(
              padding: EdgeInsets.only(right: _gap, bottom: _gap),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: tileWidth,
                height: tileHeight,
                decoration: BoxDecoration(
                  color: _tileFill(day, accent),
                  borderRadius: BorderRadius.circular(2),
                  border: day.tier == DayTier.partial && !day.isFuture
                      ? Border.all(
                          color: accent.withValues(alpha: 0.5), width: 0.5)
                      : null,
                  boxShadow: day.tier == DayTier.full && !day.isFuture
                      ? [BoxShadow(
                          color: accent.withValues(alpha: 0.35), blurRadius: 3)]
                      : null,
                ),
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  Color _tileFill(_HeatmapDay day, Color accent) {
    if (day.isFuture) return Colors.white.withValues(alpha: 0.02);
    switch (day.tier) {
      case DayTier.nothing:
        return MyWalkColor.surfaceOverlay;
      case DayTier.partial:
        return accent.withValues(alpha: 0.30);
      case DayTier.substantial:
        return accent.withValues(alpha: 0.65);
      case DayTier.full:
        return accent.withValues(alpha: 1.0);
    }
  }
}

class _HeatmapDay {
  final DateTime date;
  final bool isFuture;
  final DayTier tier;
  const _HeatmapDay({required this.date, required this.isFuture, required this.tier});
}
