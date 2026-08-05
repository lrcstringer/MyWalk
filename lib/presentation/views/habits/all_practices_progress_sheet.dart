import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/services/daily_score_service.dart';
import '../../theme/app_theme.dart';

class AllPracticesProgressSheet extends StatefulWidget {
  final List<Habit> habits;

  const AllPracticesProgressSheet({super.key, required this.habits});

  @override
  State<AllPracticesProgressSheet> createState() =>
      _AllPracticesProgressSheetState();
}

class _AllPracticesProgressSheetState
    extends State<AllPracticesProgressSheet> {
  static final _scoreService = DailyScoreService.instance;
  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _weekCount = 4;

  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.habits.map((h) => h.id).toSet();
  }

  List<Habit> get _activeHabits =>
      widget.habits.where((h) => _selectedIds.contains(h.id)).toList();

  List<List<_Day>> _buildWeeks() {
    final habits = _activeHabits;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final daysSinceSunday = today.weekday % 7;
    final currentWeekStart =
        todayStart.subtract(Duration(days: daysSinceSunday));

    return List.generate(_weekCount, (i) {
      final weekStart =
          currentWeekStart.add(Duration(days: (i - (_weekCount - 1)) * 7));
      return List.generate(7, (d) {
        final date = weekStart.add(Duration(days: d));
        final isFuture = date.isAfter(todayStart);
        final score =
            isFuture || habits.isEmpty ? 0.0 : _scoreService.dailyScore(habits, date);
        final tier = isFuture || habits.isEmpty
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
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
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
          // Heatmap card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _heatmapCard(weeks),
          ),
          const SizedBox(height: 20),
          // "PRACTICES" label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'PRACTICES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const Spacer(),
                if (_selectedIds.length < widget.habits.length)
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedIds =
                          widget.habits.map((h) => h.id).toSet();
                    }),
                    child: Text(
                      'Show All',
                      style: TextStyle(
                        fontSize: 12,
                        color: MyWalkColor.softGold.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Practice list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 24),
              itemCount: widget.habits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _practiceRow(widget.habits[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heatmapCard(List<List<_Day>> weeks) {
    final firstWeekStart = weeks.first.first.date;
    final lastDay = weeks.last.last.date;
    final fmt = DateFormat('MMM d');
    final dateRange = '${fmt.format(firstWeekStart)} – ${fmt.format(lastDay)}';

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
                dateRange,
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
          const SizedBox(height: 12),
          _legend(),
        ],
      ),
    );
  }

  Widget _legend() {
    const items = [
      (color: Color(0x0AFFFFFF), label: 'None'),
      (color: Color(0x4DD4A843), label: 'Some'),
      (color: Color(0xA6D4A843), label: 'Most'),
      (color: Color(0xFFD4A843), label: 'All'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _transposedGrid(List<List<_Day>> weeks) {
    return LayoutBuilder(builder: (context, constraints) {
      const labelWidth = 34.0;
      const gap = 3.0;
      final tileArea = constraints.maxWidth - labelWidth - gap;
      final tileSize =
          ((tileArea - gap * 6) / 7).clamp(20.0, double.infinity);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day-of-week header
          Row(
            children: [
              const SizedBox(width: labelWidth + gap),
              ...List.generate(
                7,
                (d) => Expanded(
                  child: Text(
                    _dayLabels[d],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
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

  Widget _practiceRow(Habit habit) {
    final selected = _selectedIds.contains(habit.id);
    final accent = habit.trackingType == HabitTrackingType.abstain
        ? MyWalkColor.sage
        : MyWalkColor.golden;

    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          // Don't allow deselecting the last one
          if (_selectedIds.length > 1) _selectedIds.remove(habit.id);
        } else {
          _selectedIds.add(habit.id);
        }
      }),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: selected ? 0.15 : 0.06),
              ),
              child: Icon(_iconFor(habit),
                  size: 16,
                  color: accent.withValues(alpha: selected ? 1.0 : 0.4)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? MyWalkColor.warmWhite
                          : MyWalkColor.warmWhite.withValues(alpha: 0.4),
                    ),
                  ),
                  if (habit.subcategoryName != null &&
                      habit.subcategoryName!.isNotEmpty)
                    Text(
                      habit.subcategoryName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(
                            alpha: selected ? 0.4 : 0.2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    selected ? accent : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? accent
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Icon(Icons.check,
                      size: 13, color: MyWalkColor.charcoal)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(Habit h) {
    if (h.trackingType == HabitTrackingType.abstain) {
      return Icons.shield_rounded;
    }
    switch (h.category) {
      case HabitCategory.gratitude:
        return Icons.auto_awesome;
      case HabitCategory.scripture:
        return Icons.menu_book;
      case HabitCategory.exercise:
        return Icons.fitness_center;
      case HabitCategory.rest:
        return Icons.bedtime;
      case HabitCategory.fasting:
        return Icons.no_food;
      case HabitCategory.study:
        return Icons.school;
      case HabitCategory.service:
        return Icons.volunteer_activism;
      case HabitCategory.connection:
        return Icons.people;
      case HabitCategory.health:
        return Icons.favorite;
      case HabitCategory.abstain:
        return Icons.shield_rounded;
      case HabitCategory.prayer:
        return Icons.self_improvement_rounded;
      case HabitCategory.custom:
        return Icons.star;
    }
  }
}

class _Day {
  final DateTime date;
  final bool isFuture;
  final DayTier tier;
  const _Day({required this.date, required this.isFuture, required this.tier});
}
