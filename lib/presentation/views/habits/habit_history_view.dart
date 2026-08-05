import 'package:flutter/material.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_entry.dart';
import '../../theme/app_theme.dart';
import 'heatmap_view.dart';

enum _HistoryRange { week, month }

class HabitHistoryView extends StatefulWidget {
  final Habit habit;

  const HabitHistoryView({super.key, required this.habit});

  @override
  State<HabitHistoryView> createState() => _HabitHistoryViewState();
}

class _HabitHistoryViewState extends State<HabitHistoryView> {
  _HistoryRange _range = _HistoryRange.week;

  Habit get _habit => widget.habit;

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  List<DateTime> _currentWeekDates() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final daysSinceSunday = today.weekday % 7;
    final weekStart = todayStart.subtract(Duration(days: daysSinceSunday));
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final isAbstain = _habit.trackingType == HabitTrackingType.abstain;
    final accentColor = isAbstain ? MyWalkColor.sage : MyWalkColor.golden;

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
                Text(
                  _habit.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: MyWalkColor.warmWhite,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.4), size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                _pill('Week', _range == _HistoryRange.week, accentColor,
                    () => setState(() => _range = _HistoryRange.week)),
                const SizedBox(width: 8),
                _pill('Month', _range == _HistoryRange.month, accentColor,
                    () => setState(() => _range = _HistoryRange.month)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _range == _HistoryRange.week
                ? _weekContent(accentColor)
                : _monthContent(),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ],
      ),
    );
  }

  Widget _pill(String label, bool selected, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? accent : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _weekContent(Color accentColor) {
    final dates = _currentWeekDates();
    final todayStart = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MyWalkDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.softGold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: dates.asMap().entries.map((e) {
              final date = e.value;
              final isToday = date.year == todayStart.year &&
                  date.month == todayStart.month &&
                  date.day == todayStart.day;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      _dayLabels[e.key],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday
                            ? MyWalkColor.golden
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _weekDayVisual(date),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _weekDayVisual(DateTime date) {
    final todayStart = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final isFuture = date.isAfter(todayStart);
    final isActive = _habit.isActive(date);
    final entry = _habit.entryFor(date);

    switch (_habit.trackingType) {
      case HabitTrackingType.timed:
        return _timedDayBar(entry, isFuture, isActive);
      case HabitTrackingType.count:
        return _countDayVisual(entry, isFuture, isActive);
      case HabitTrackingType.checkIn:
        return _checkInDayCircle(entry, isFuture, isActive);
      case HabitTrackingType.abstain:
        return _abstainDayShield(entry, isFuture, isActive);
    }
  }

  Widget _timedDayBar(HabitEntry? entry, bool isFuture, bool isActive) {
    final value = entry?.value ?? 0.0;
    final target = _habit.dailyTarget;
    final ratio = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    final completed = entry?.isCompleted ?? false;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 16,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (!isFuture && isActive)
              Container(
                width: 16,
                height: (40 * ratio).clamp(2.0, 40.0).toDouble(),
                decoration: BoxDecoration(
                  color: completed ? MyWalkColor.golden : MyWalkColor.mutedSage,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          (!isFuture && isActive && value > 0) ? '${value.toInt()}' : ' ',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: completed
                ? MyWalkColor.golden
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _countDayVisual(HabitEntry? entry, bool isFuture, bool isActive) {
    final value = entry?.value ?? 0.0;
    final completed = entry?.isCompleted ?? false;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (!isFuture && isActive && value > 0)
                ? (completed
                    ? MyWalkColor.golden.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04))
                : Colors.white.withValues(
                    alpha: isFuture || !isActive ? 0.02 : 0.04),
          ),
          child: (!isFuture && isActive && value > 0)
              ? Center(
                  child: Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: completed
                          ? MyWalkColor.golden
                          : MyWalkColor.softGold.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 4),
        const Text(' ', style: TextStyle(fontSize: 9)),
      ],
    );
  }

  Widget _checkInDayCircle(HabitEntry? entry, bool isFuture, bool isActive) {
    final completed = entry?.isCompleted ?? false;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? MyWalkColor.golden
                : Colors.white.withValues(
                    alpha: isFuture || !isActive ? 0.02 : 0.04),
          ),
          child: completed
              ? const Icon(Icons.check, size: 14, color: MyWalkColor.charcoal)
              : null,
        ),
        const SizedBox(height: 4),
        const Text(' ', style: TextStyle(fontSize: 9)),
      ],
    );
  }

  Widget _abstainDayShield(HabitEntry? entry, bool isFuture, bool isActive) {
    final confirmed = entry?.isCompleted ?? false;

    return Column(
      children: [
        Icon(
          confirmed ? Icons.shield_rounded : Icons.shield_outlined,
          size: 24,
          color: confirmed
              ? MyWalkColor.sage
              : Colors.white.withValues(
                  alpha: isFuture || !isActive ? 0.08 : 0.2),
        ),
        const SizedBox(height: 4),
        const Text(' ', style: TextStyle(fontSize: 9)),
      ],
    );
  }

  Widget _monthContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MyWalkDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 4 Weeks',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MyWalkColor.softGold,
            ),
          ),
          const SizedBox(height: 12),
          HeatmapView(habit: _habit, weekCount: 4),
        ],
      ),
    );
  }
}
