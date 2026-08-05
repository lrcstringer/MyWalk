import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/services/daily_score_service.dart';
import '../../theme/app_theme.dart';

class AllPracticesProgressSheet extends StatelessWidget {
  final List<Habit> habits;

  const AllPracticesProgressSheet({super.key, required this.habits});

  static final _scoreService = DailyScoreService.instance;
  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _weekCount = 4;

  List<List<_Day>> _buildWeeks() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final daysSinceSunday = today.weekday % 7;
    final currentWeekStart = todayStart.subtract(Duration(days: daysSinceSunday));

    return List.generate(_weekCount, (i) {
      final weekStart = currentWeekStart
          .add(Duration(days: (i - (_weekCount - 1)) * 7));
      return List.generate(7, (d) {
        final date = weekStart.add(Duration(days: d));
        final isFuture = date.isAfter(todayStart);
        final score =
            isFuture ? 0.0 : _scoreService.dailyScore(habits, date);
        final tier = isFuture
            ? DayTier.nothing
            : _scoreService.tierForScore(score);
        return _Day(date: date, isFuture: isFuture, tier: tier);
      });
    });
  }

  Color _tileFill(_Day day) {
    if (day.isFuture) return Colors.white.withValues(alpha: 0.03);
    switch (day.tier) {
      case DayTier.nothing:
        return MyWalkColor.surfaceOverlay;
      case DayTier.partial:
        return MyWalkColor.golden.withValues(alpha: 0.30);
      case DayTier.substantial:
        return MyWalkColor.golden.withValues(alpha: 0.65);
      case DayTier.full:
        return MyWalkColor.golden.withValues(alpha: 1.0);
    }
  }

  Border? _tileBorder(_Day day) {
    if (!day.isFuture && day.tier == DayTier.partial) {
      return Border.all(
          color: MyWalkColor.golden.withValues(alpha: 0.50), width: 0.5);
    }
    return null;
  }

  List<BoxShadow>? _tileShadow(_Day day) {
    if (!day.isFuture && day.tier == DayTier.full) {
      return [
        BoxShadow(
          color: MyWalkColor.golden.withValues(alpha: 0.40),
          blurRadius: 6,
        )
      ];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();

    return Container(
      decoration: const BoxDecoration(
        color: MyWalkColor.charcoal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'All Practices',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: MyWalkColor.warmWhite,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close,
                      color: Colors.white.withValues(alpha: 0.4), size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _heatmapCard(weeks),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ],
      ),
    );
  }

  Widget _heatmapCard(List<List<_Day>> weeks) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C2823),
            Color.lerp(const Color(0xFF221F1B), MyWalkColor.golden, 0.07)!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: MyWalkColor.golden.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Last 4 Weeks',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MyWalkColor.softGold,
                ),
              ),
              const Spacer(),
              Text(
                _dateRange(weeks),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            color: MyWalkColor.golden.withValues(alpha: 0.18),
            thickness: 0.5,
            height: 1,
          ),
          const SizedBox(height: 12),
          _transposedGrid(weeks),
        ],
      ),
    );
  }

  Widget _transposedGrid(List<List<_Day>> weeks) {
    return LayoutBuilder(builder: (context, constraints) {
      const labelWidth = 34.0;
      const gap = 3.0;
      final tileArea = constraints.maxWidth - labelWidth - gap;
      final tileSize = ((tileArea - gap * 6) / 7).clamp(20.0, double.infinity);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day-of-week header
          Row(
            children: [
              const SizedBox(width: labelWidth + gap),
              ...List.generate(7, (d) => _expandedLabel(_dayLabels[d])),
            ],
          ),
          const SizedBox(height: 4),
          // One row per week
          ...weeks.map((week) {
            final sunday = week.first.date;
            return Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: Row(
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Text(
                      DateFormat('MMM d').format(sunday),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: gap),
                  ...week.map((day) => Padding(
                        padding: const EdgeInsets.only(right: gap),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: tileSize,
                          height: tileSize,
                          decoration: BoxDecoration(
                            color: _tileFill(day),
                            borderRadius: BorderRadius.circular(4),
                            border: _tileBorder(day),
                            boxShadow: _tileShadow(day),
                          ),
                        ),
                      )),
                ],
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _expandedLabel(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          color: Colors.white.withValues(alpha: 0.35),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _dateRange(List<List<_Day>> weeks) {
    final start = weeks.first.first.date;
    final end = weeks.last.last.date;
    final fmt = DateFormat('MMM d');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }
}

class _Day {
  final DateTime date;
  final bool isFuture;
  final DayTier tier;
  const _Day({required this.date, required this.isFuture, required this.tier});
}
