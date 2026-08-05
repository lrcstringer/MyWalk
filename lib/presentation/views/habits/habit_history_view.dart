import 'package:flutter/material.dart';
import '../../../domain/entities/habit.dart';
import '../../theme/app_theme.dart';
import 'habit_week_card.dart';
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

  Color get _accent => _habit.trackingType == HabitTrackingType.abstain
      ? MyWalkColor.sage
      : MyWalkColor.golden;

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

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
                  child: Icon(Icons.close,
                      color: Colors.white.withValues(alpha: 0.4), size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                _pill('Week', _range == _HistoryRange.week, accent,
                    () => setState(() => _range = _HistoryRange.week)),
                const SizedBox(width: 8),
                _pill('Month', _range == _HistoryRange.month, accent,
                    () => setState(() => _range = _HistoryRange.month)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _range == _HistoryRange.week
                ? HabitWeekCard(habit: _habit)
                : _monthContent(accent),
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
          color: selected
              ? accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
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

  Widget _monthContent(Color accent) {
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
            'Last 4 Weeks',
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
          HeatmapView(habit: _habit, weekCount: 4),
        ],
      ),
    );
  }
}
