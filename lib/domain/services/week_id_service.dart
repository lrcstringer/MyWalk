/// Week ID utilities used across circle collaboration features.
///
/// App convention: weeks start on Sunday (day index 0).
/// Week IDs use the format YYYY-WW where WW is the zero-based week number
/// within the year (0 = week containing Jan 1, same convention the server uses).
library;

class WeekIdService {
  WeekIdService._();

  /// Returns the Sunday of the week containing [dt].
  static DateTime weekStart(DateTime dt) {
    final day = DateTime(dt.year, dt.month, dt.day);
    // weekday: Mon=1 … Sun=7. We want Sun=0 offset.
    final daysSinceSunday = day.weekday % 7; // Sun→0, Mon→1 … Sat→6
    return day.subtract(Duration(days: daysSinceSunday));
  }

  /// Returns an ISO week identifier for [dt] in 'YYYY-WW' format.
  ///
  /// WW is calculated as floor((dayOfYear of Sunday) / 7), giving a
  /// deterministic, server-compatible value. Weeks are 0-indexed so
  /// Jan 1 is always in week '00' of its year.
  static String weekId(DateTime dt) {
    final sunday = weekStart(dt);
    final jan1 = DateTime(sunday.year, 1, 1);
    final dayOfYear = sunday.difference(jan1).inDays;
    final weekNum = dayOfYear ~/ 7;
    return '${sunday.year}-${weekNum.toString().padLeft(2, '0')}';
  }

  /// Returns today's week ID.
  static String currentWeekId() => weekId(DateTime.now());

  /// Returns a YYYY-MM-DD date string for [dt].
  static String dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Returns today's date string.
  static String todayStr() => dateStr(DateTime.now());
}
