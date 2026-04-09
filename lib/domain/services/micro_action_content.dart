import '../entities/habit.dart';
import '../entities/scripture.dart';
import 'milestone_service.dart';

/// Static content service for the ReachOut sheet — micro-actions,
/// milestone motivators, and coping plan helper copy.
class MicroActionContent {
  MicroActionContent._();

  static const _milestoneService = MilestoneService.instance;

  // ---------------------------------------------------------------------------
  // Micro-actions (category-keyed, date-seeded selection)
  // ---------------------------------------------------------------------------

  static List<String> microActionsFor(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise:
        return [
          'Just do the first 5 minutes.',
          'Do 10 pushups to reset your headspace.',
          'Step outside and walk for 2 minutes.',
        ];
      case HabitCategory.scripture:
        return [
          'Open to any page. Read one verse.',
          'Pray for 60 seconds. Just talk to Him.',
          'Write down one thing God has done for you.',
        ];
      case HabitCategory.rest:
        return [
          'Put your phone down for 5 minutes.',
          'Close your eyes and breathe for 60 seconds.',
          "Tell God what's keeping you up.",
        ];
      case HabitCategory.abstain:
        return [
          "Pray for 60 seconds. Tell God what you're feeling.",
          'Do 10 pushups to reset your headspace.',
          'Text someone you trust right now.',
          'Step outside. Change your environment.',
        ];
      case HabitCategory.fasting:
        return [
          'Drink a glass of water slowly.',
          'Pray for 60 seconds. Offer the hunger to God.',
          "Read one verse about God's provision.",
        ];
      case HabitCategory.study:
        return [
          'Just open the book. Read one page.',
          "Set a 5-minute timer. That's all.",
          'Write down why you started this.',
        ];
      case HabitCategory.service:
        return [
          'Send one encouraging text to someone.',
          'Pray for someone specific right now.',
          'Do one small act of kindness today.',
        ];
      case HabitCategory.connection:
        return [
          'Reach out to one person right now.',
          "Pray for someone you haven't talked to.",
          "Send a simple 'thinking of you' message.",
        ];
      case HabitCategory.health:
        return [
          'Drink a glass of water right now.',
          'Fill your bottle and take three sips.',
          'Set a timer for your next glass.',
        ];
      case HabitCategory.custom:
        return [
          'Just start. Do the smallest version of this.',
          'Pray for 60 seconds. Ask God for strength.',
          'Remember why you committed to this.',
        ];
      case HabitCategory.gratitude:
        return ['Thank God for one thing right now.'];
      case HabitCategory.prayer:
        return [
          'Just start talking to God. No script needed.',
          'Pray for one person by name right now.',
          'Be still for 60 seconds and listen.',
        ];
    }
  }

  /// Returns today's micro-action for [category], seeded by day-of-year so
  /// the same action shows all day but rotates daily.
  static String selectedMicroActionFor(HabitCategory category) {
    final actions = microActionsFor(category);
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return actions[dayOfYear % actions.length];
  }

  // ---------------------------------------------------------------------------
  // Milestone shield message (shown in ReachOut sheet)
  // ---------------------------------------------------------------------------

  static String milestoneMessageFor(Habit habit) {
    switch (habit.trackingType) {
      case HabitTrackingType.abstain:
        final consecutive = _milestoneService.consecutiveCleanDays(habit);
        final total = habit.totalCompletedDays();
        final next = _nextTarget(consecutive, [7, 14, 30, 60, 90, 180, 365]);
        var msg = '';
        if (consecutive > 0) {
          msg =
              "You've been going strong for $consecutive day${consecutive == 1 ? '' : 's'}.";
          if (next != null) {
            final rem = next - consecutive;
            msg +=
                " You're just $rem day${rem == 1 ? '' : 's'} from $next days. That's worth protecting.";
          }
        }
        if (total > 0 && total != consecutive) {
          msg +=
              '\n\nEven if today is hard, those $total total clean days still stand. They\'re not going anywhere.';
        } else if (consecutive > 0) {
          msg +=
              "\n\nBut even if today is hard, those $consecutive days still stand. They're not going anywhere.";
        }
        return msg.isEmpty
            ? 'Every moment of strength matters. God sees you in this.'
            : msg;

      case HabitTrackingType.timed:
        final totalMinutes = habit.totalValue();
        final hours = totalMinutes ~/ 60;
        final mins = totalMinutes.toInt() % 60;
        final timeStr = hours > 0
            ? '$hours hour${hours == 1 ? '' : 's'} and $mins minute${mins == 1 ? '' : 's'}'
            : '$mins minute${mins == 1 ? '' : 's'}';
        if (totalMinutes > 0) {
          return "You've given $timeStr to God through ${habit.name.toLowerCase()}. That's real. That's yours. Keep going.";
        }
        return 'Every minute you give matters. Start with just one.';

      case HabitTrackingType.count:
        final total = habit.totalValue().toInt();
        final unit = habit.targetUnit.isEmpty ? 'times' : habit.targetUnit;
        if (total > 0) {
          return 'You\'ve reached $total $unit. Every single one counted. Keep building.';
        }
        return 'Every one counts. Start with just one.';

      case HabitTrackingType.checkIn:
        final days = habit.totalCompletedDays();
        if (days > 0) {
          final next = _nextTarget(days, [7, 30, 100, 365]);
          var msg = "$days day${days == 1 ? '' : 's'} of showing up. That's faithfulness.";
          if (next != null) {
            final rem = next - days;
            msg += ' You\'re $rem day${rem == 1 ? '' : 's'} from $next. Worth protecting.';
          }
          return msg;
        }
        return 'Showing up matters. Even today.';
    }
  }

  // ---------------------------------------------------------------------------
  // "Your Why" section (purposeStatement + anchor verse)
  // ---------------------------------------------------------------------------

  static Scripture anchorVerseFor(HabitCategory category) =>
      ScriptureLibrary.anchorVerse(category);

  // ---------------------------------------------------------------------------
  // Coping plan helper copy
  // ---------------------------------------------------------------------------

  static const String copingPlanSubtitle =
      'You wrote this when you were strong. Trust that version of yourself.';

  // ---------------------------------------------------------------------------

  static int? _nextTarget(int current, List<int> thresholds) =>
      thresholds.where((t) => t > current).firstOrNull;
}
