// ── Section types ─────────────────────────────────────────────────────────────

enum BibleReadingSection {
  psalms,
  newTestament,
  torah,
  historical,
  prophetic,
  wisdom;

  String get key {
    switch (this) {
      case psalms:        return 'psalms';
      case newTestament:  return 'nt';
      case torah:         return 'torah';
      case historical:    return 'historical';
      case prophetic:     return 'prophetic';
      case wisdom:        return 'wisdom';
    }
  }

  String get label {
    switch (this) {
      case psalms:        return 'Psalms';
      case newTestament:  return 'New Testament';
      case torah:         return 'Old Testament: Torah';
      case historical:    return 'Old Testament: Historical Books';
      case prophetic:     return 'Old Testament: Prophetic Books';
      case wisdom:        return 'Old Testament: Wisdom & Poetry';
    }
  }

  static const ordered = [psalms, newTestament, torah, historical, prophetic, wisdom];
}

// ── Reading reference ─────────────────────────────────────────────────────────

/// A single tappable chapter link within the reading plan.
/// [bookNum] and [chapter] are used for Bible navigation.
/// [label] is the human-readable display string (e.g. "Psalm 2:1–4").
class BibleReadingRef {
  final int bookNum;
  final int chapter;
  final String label;

  const BibleReadingRef({
    required this.bookNum,
    required this.chapter,
    required this.label,
  });
}

// ── Day plan ──────────────────────────────────────────────────────────────────

/// The static reading schedule for one day (Sun–Sat).
class BibleReadingDayPlan {
  final List<BibleReadingRef> psalms;
  final List<BibleReadingRef> newTestament;
  final List<BibleReadingRef> torah;
  final List<BibleReadingRef> historical;
  final List<BibleReadingRef> prophetic;
  final List<BibleReadingRef> wisdom;

  const BibleReadingDayPlan({
    this.psalms = const [],
    this.newTestament = const [],
    this.torah = const [],
    this.historical = const [],
    this.prophetic = const [],
    this.wisdom = const [],
  });

  List<BibleReadingRef> refsForSection(BibleReadingSection s) {
    switch (s) {
      case BibleReadingSection.psalms:       return psalms;
      case BibleReadingSection.newTestament: return newTestament;
      case BibleReadingSection.torah:        return torah;
      case BibleReadingSection.historical:   return historical;
      case BibleReadingSection.prophetic:    return prophetic;
      case BibleReadingSection.wisdom:       return wisdom;
    }
  }

  /// Returns only sections that have at least one reading ref.
  List<BibleReadingSection> get activeSections =>
      BibleReadingSection.ordered.where((s) => refsForSection(s).isNotEmpty).toList();

  /// Abbreviated one-line summary for grid row display.
  String get abbreviatedSummary {
    final parts = <String>[];
    for (final s in BibleReadingSection.ordered) {
      final refs = refsForSection(s);
      if (refs.isNotEmpty) parts.add(refs.map((r) => r.label).join(' · '));
    }
    return parts.join('  ·  ');
  }
}

// ── Plan status ───────────────────────────────────────────────────────────────

enum BibleReadingPlanStatus { notStarted, pending, active }

// ── User plan state ───────────────────────────────────────────────────────────

/// Persisted in Firestore at /users/{uid}/bibleReadingPlan/settings.
class BibleReadingPlanState {
  /// Date the user tapped "Start Plan". Null if never started.
  final DateTime? startDate;

  /// The Sunday the plan goes live. Null if never started.
  final DateTime? liveDate;

  final BibleReadingPlanStatus status;

  /// Map of completed section keys → true.
  /// Key format: "{weekIndex}_{dayIndex}_{sectionKey}" e.g. "0_0_psalms".
  final Map<String, bool> sectionsDone;

  /// Which milestone week indices have already been shown (0-indexed).
  final List<int> milestonesShown;

  /// Current consecutive-full-days streak.
  final int streakDays;

  /// Last calendar date (UTC midnight) a full day's reading was completed.
  final DateTime? lastStreakDate;

  const BibleReadingPlanState({
    this.startDate,
    this.liveDate,
    this.status = BibleReadingPlanStatus.notStarted,
    this.sectionsDone = const {},
    this.milestonesShown = const [],
    this.streakDays = 0,
    this.lastStreakDate,
  });

  // ── Progress helpers ────────────────────────────────────────────────────────

  bool isSectionDone(int weekIndex, int dayIndex, BibleReadingSection section) =>
      sectionsDone['${weekIndex}_${dayIndex}_${section.key}'] == true;

  bool isDayDone(int weekIndex, int dayIndex, BibleReadingDayPlan plan) =>
      plan.activeSections.every((s) => isSectionDone(weekIndex, dayIndex, s));

  bool isWeekDone(int weekIndex, List<BibleReadingDayPlan> weekPlans) =>
      weekPlans.asMap().entries.every(
          (e) => isDayDone(weekIndex, e.key, e.value));

  // ── Current position ────────────────────────────────────────────────────────

  /// Days elapsed since liveDate (clamped to 0–363). Returns null if not active.
  int? get elapsedDays {
    if (status != BibleReadingPlanStatus.active || liveDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final live = DateTime(liveDate!.year, liveDate!.month, liveDate!.day);
    final diff = today.difference(live).inDays;
    return diff.clamp(0, 363);
  }

  int? get currentWeekIndex {
    final e = elapsedDays;
    return e == null ? null : e ~/ 7;
  }

  int? get currentDayIndex {
    final e = elapsedDays;
    return e == null ? null : e % 7;
  }

  /// Days until liveDate from today. Returns null if not pending.
  int? get daysUntilLive {
    if (status != BibleReadingPlanStatus.pending || liveDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final live = DateTime(liveDate!.year, liveDate!.month, liveDate!.day);
    return live.difference(today).inDays;
  }

  BibleReadingPlanState copyWith({
    DateTime? startDate,
    DateTime? liveDate,
    BibleReadingPlanStatus? status,
    Map<String, bool>? sectionsDone,
    List<int>? milestonesShown,
    int? streakDays,
    DateTime? lastStreakDate,
  }) =>
      BibleReadingPlanState(
        startDate: startDate ?? this.startDate,
        liveDate: liveDate ?? this.liveDate,
        status: status ?? this.status,
        sectionsDone: sectionsDone ?? this.sectionsDone,
        milestonesShown: milestonesShown ?? this.milestonesShown,
        streakDays: streakDays ?? this.streakDays,
        lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      );
}
