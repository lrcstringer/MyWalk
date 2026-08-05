import 'package:flutter/material.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_entry.dart';
import '../../theme/app_theme.dart';

class HabitWeekCard extends StatelessWidget {
  final Habit habit;

  const HabitWeekCard({super.key, required this.habit});

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  Color get _accent => habit.trackingType == HabitTrackingType.abstain
      ? MyWalkColor.sage
      : MyWalkColor.golden;

  List<DateTime> _weekDates() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final weekStart = todayStart.subtract(Duration(days: today.weekday % 7));
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final dates = _weekDates();
    final todayStart = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Summary stats: active days elapsed so far this week
    final pastActive = dates
        .where((d) => !d.isAfter(todayStart) && habit.isActive(d))
        .toList();
    final completedCount =
        pastActive.where((d) => habit.isCompleted(d)).length;
    final totalActive = pastActive.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C2823),
            Color.lerp(const Color(0xFF221F1B), accent, 0.07)!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.5),
      ),
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
          const SizedBox(height: 10),
          Divider(
            color: accent.withValues(alpha: 0.18),
            thickness: 0.5,
            height: 1,
          ),
          const SizedBox(height: 12),
          Row(
            children: dates.asMap().entries.map((e) {
              final date = e.value;
              final isToday = date == todayStart;
              final isActive = habit.isActive(date);
              final isFuture = date.isAfter(todayStart);
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      _dayLabels[e.key],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday
                            ? accent
                            : isActive && !isFuture
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _dayVisual(date, isFuture, isActive, accent),
                  ],
                ),
              );
            }).toList(),
          ),
          if (totalActive > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Container(height: 3, color: Colors.white.withValues(alpha: 0.06)),
                  FractionallySizedBox(
                    widthFactor: completedCount / totalActive,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withValues(alpha: 0.7),
                            accent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$completedCount of $totalActive days',
              style: TextStyle(
                fontSize: 11,
                color: completedCount > 0
                    ? accent.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dayVisual(
      DateTime date, bool isFuture, bool isActive, Color accent) {
    final entry = habit.entryFor(date);
    switch (habit.trackingType) {
      case HabitTrackingType.timed:
        return _timedBar(entry, isFuture, isActive, accent);
      case HabitTrackingType.count:
        return _countCircle(entry, isFuture, isActive, accent);
      case HabitTrackingType.checkIn:
        return _checkInCircle(entry, isFuture, isActive, accent);
      case HabitTrackingType.abstain:
        return _abstainShield(entry, isFuture, isActive, accent);
    }
  }

  Widget _timedBar(
      HabitEntry? entry, bool isFuture, bool isActive, Color accent) {
    final value = entry?.value ?? 0.0;
    final target = habit.dailyTarget;
    final ratio = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    final completed = entry?.isCompleted ?? false;
    final fillHeight = (40 * ratio).clamp(2.0, 40.0);

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
            if (!isFuture && isActive && ratio > 0)
              Container(
                width: 16,
                height: fillHeight.toDouble(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: completed
                        ? [MyWalkColor.softGold, MyWalkColor.golden]
                        : [
                            MyWalkColor.mutedSage.withValues(alpha: 0.6),
                            MyWalkColor.mutedSage,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: completed
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
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
                ? accent
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _countCircle(
      HabitEntry? entry, bool isFuture, bool isActive, Color accent) {
    final value = entry?.value ?? 0.0;
    final completed = entry?.isCompleted ?? false;
    final hasValue = !isFuture && isActive && value > 0;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasValue
                ? RadialGradient(colors: [
                    accent.withValues(alpha: completed ? 0.30 : 0.12),
                    accent.withValues(alpha: completed ? 0.10 : 0.04),
                  ])
                : null,
            color: hasValue ? null : Colors.white.withValues(alpha: isFuture || !isActive ? 0.02 : 0.04),
            border: hasValue && completed
                ? Border.all(
                    color: accent.withValues(alpha: 0.45), width: 1)
                : null,
            boxShadow: hasValue && completed
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
          child: hasValue
              ? Center(
                  child: Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: completed
                          ? accent
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

  Widget _checkInCircle(
      HabitEntry? entry, bool isFuture, bool isActive, Color accent) {
    final completed = entry?.isCompleted ?? false;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: completed
                ? RadialGradient(
                    colors: [MyWalkColor.softGold, accent],
                  )
                : null,
            color: completed
                ? null
                : Colors.white
                    .withValues(alpha: isFuture || !isActive ? 0.02 : 0.04),
            boxShadow: completed
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
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

  Widget _abstainShield(
      HabitEntry? entry, bool isFuture, bool isActive, Color accent) {
    final confirmed = entry?.isCompleted ?? false;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: confirmed
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Icon(
            confirmed ? Icons.shield_rounded : Icons.shield_outlined,
            size: 24,
            color: confirmed
                ? accent
                : Colors.white
                    .withValues(alpha: isFuture || !isActive ? 0.08 : 0.2),
          ),
        ),
        const SizedBox(height: 4),
        const Text(' ', style: TextStyle(fontSize: 9)),
      ],
    );
  }
}
