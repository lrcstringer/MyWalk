import 'package:flutter/material.dart';

enum FruitType {
  love,
  joy,
  peace,
  patience,
  kindness,
  goodness,
  faithfulness,
  gentleness,
  selfControl;

  static FruitType fromString(String value) {
    return FruitType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FruitType.love,
    );
  }
}

extension FruitTypeX on FruitType {
  String get label {
    switch (this) {
      case FruitType.love:          return 'Love';
      case FruitType.joy:           return 'Joy';
      case FruitType.peace:         return 'Peace';
      case FruitType.patience:      return 'Patience';
      case FruitType.kindness:      return 'Kindness';
      case FruitType.goodness:      return 'Goodness';
      case FruitType.faithfulness:  return 'Faithfulness';
      case FruitType.gentleness:    return 'Gentleness';
      case FruitType.selfControl:   return 'Self-Control';
    }
  }

  IconData get icon {
    switch (this) {
      case FruitType.love:          return Icons.favorite;
      case FruitType.joy:           return Icons.wb_sunny;
      case FruitType.peace:         return Icons.spa;
      case FruitType.patience:      return Icons.hourglass_empty;
      case FruitType.kindness:      return Icons.volunteer_activism;
      case FruitType.goodness:      return Icons.star;
      case FruitType.faithfulness:  return Icons.anchor;
      case FruitType.gentleness:    return Icons.air;
      case FruitType.selfControl:   return Icons.shield;
    }
  }

  Color get color {
    switch (this) {
      case FruitType.love:          return const Color(0xFFD4836B); // warmCoral
      case FruitType.joy:           return const Color(0xFFD4A843); // golden
      case FruitType.peace:         return const Color(0xFF7A9E7E); // sage
      case FruitType.patience:      return const Color(0xFF8B7355); // earth brown
      case FruitType.kindness:      return const Color(0xFF7A9EB5); // soft blue
      case FruitType.goodness:      return const Color(0xFFD4A843); // golden (warm white tile → golden icon)
      case FruitType.faithfulness:  return const Color(0xFF2E4057); // deep navy
      case FruitType.gentleness:    return const Color(0xFFB5A7C7); // lavender
      case FruitType.selfControl:   return const Color(0xFFC5D8C7); // mutedSage (charcoal → muted for display)
    }
  }

  String get greekWord {
    switch (this) {
      case FruitType.love:          return 'agapē';
      case FruitType.joy:           return 'chara';
      case FruitType.peace:         return 'eirēnē';
      case FruitType.patience:      return 'makrothymia';
      case FruitType.kindness:      return 'chrēstotēs';
      case FruitType.goodness:      return 'agathōsynē';
      case FruitType.faithfulness:  return 'pistis';
      case FruitType.gentleness:    return 'prautēs';
      case FruitType.selfControl:   return 'enkrateia';
    }
  }

  String get shortDescription {
    switch (this) {
      case FruitType.love:          return 'Unconditional love that serves before it feels';
      case FruitType.joy:           return "Delight rooted in God's presence, not circumstances";
      case FruitType.peace:         return 'Deep rest and wholeness, even amid uncertainty';
      case FruitType.patience:      return "Enduring grace that doesn't snap under pressure";
      case FruitType.kindness:      return 'Warmth and goodness expressed in everyday acts';
      case FruitType.goodness:      return 'Doing right because you are being made right';
      case FruitType.faithfulness:  return 'Consistent trust and reliability in small things';
      case FruitType.gentleness:    return "Calm strength that doesn't need to force or defend";
      case FruitType.selfControl:   return 'The quiet power to choose well';
    }
  }

  String get checkInPrompt {
    switch (this) {
      case FruitType.love:
        return 'Did you act out of love today, even when it was hard?';
      case FruitType.joy:
        return "Where did you find delight in God's presence today?";
      case FruitType.peace:
        return "Did you rest in God's peace today, even amid uncertainty?";
      case FruitType.patience:
        return 'Did you respond with patient grace today?';
      case FruitType.kindness:
        return 'Did you show kindness in an everyday moment today?';
      case FruitType.goodness:
        return 'Did you choose to do right today, even when no one was watching?';
      case FruitType.faithfulness:
        return 'Were you faithful in a small thing today?';
      case FruitType.gentleness:
        return 'Did you respond with gentle strength today?';
      case FruitType.selfControl:
        return 'Did you choose well in a moment of temptation today?';
    }
  }

  String get completionMessage {
    switch (this) {
      case FruitType.love:         return 'Love is patient, love is kind.';
      case FruitType.joy:          return 'The joy of the Lord is your strength.';
      case FruitType.peace:        return "The peace of God guards your heart.";
      case FruitType.patience:     return 'Let perseverance finish its work.';
      case FruitType.kindness:     return "A kind word can change someone's day.";
      case FruitType.goodness:     return 'Well done, good and faithful servant.';
      case FruitType.faithfulness: return "You've been faithful with a little.";
      case FruitType.gentleness:   return 'Blessed are the meek.';
      case FruitType.selfControl:  return 'You have the mind of Christ.';
    }
  }
}

// ── Portfolio data ─────────────────────────────────────────────────────────────

class FruitPortfolioEntry {
  final FruitType fruit;
  final int habitCount;
  final int totalCompletions;
  final int weeklyCompletions;
  final DateTime? lastCompletedAt;
  final int currentStreak;
  final int longestStreak;

  const FruitPortfolioEntry({
    required this.fruit,
    this.habitCount = 0,
    this.totalCompletions = 0,
    this.weeklyCompletions = 0,
    this.lastCompletedAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  FruitPortfolioEntry copyWith({
    int? habitCount,
    int? totalCompletions,
    int? weeklyCompletions,
    DateTime? lastCompletedAt,
    int? currentStreak,
    int? longestStreak,
  }) =>
      FruitPortfolioEntry(
        fruit: fruit,
        habitCount: habitCount ?? this.habitCount,
        totalCompletions: totalCompletions ?? this.totalCompletions,
        weeklyCompletions: weeklyCompletions ?? this.weeklyCompletions,
        lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
      );

  Map<String, dynamic> toFirestore() => {
        'fruit': fruit.name,
        'habitCount': habitCount,
        'totalCompletions': totalCompletions,
        'weeklyCompletions': weeklyCompletions,
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };

  factory FruitPortfolioEntry.fromFirestore(Map<String, dynamic> data) {
    DateTime? lastCompleted;
    final raw = data['lastCompletedAt'];
    if (raw is String) lastCompleted = DateTime.tryParse(raw);

    return FruitPortfolioEntry(
      fruit: FruitType.fromString(data['fruit'] as String? ?? ''),
      habitCount: (data['habitCount'] as num?)?.toInt() ?? 0,
      totalCompletions: (data['totalCompletions'] as num?)?.toInt() ?? 0,
      weeklyCompletions: (data['weeklyCompletions'] as num?)?.toInt() ?? 0,
      lastCompletedAt: lastCompleted,
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (data['longestStreak'] as num?)?.toInt() ?? 0,
    );
  }
}

class FruitPortfolio {
  final Map<FruitType, FruitPortfolioEntry> entries;

  const FruitPortfolio({required this.entries});

  factory FruitPortfolio.empty() => FruitPortfolio(
        entries: {
          for (final f in FruitType.values)
            f: FruitPortfolioEntry(fruit: f),
        },
      );

  FruitPortfolioEntry entryFor(FruitType fruit) =>
      entries[fruit] ?? FruitPortfolioEntry(fruit: fruit);

  List<FruitType> get activeFruits => FruitType.values
      .where((f) => (entries[f]?.habitCount ?? 0) > 0)
      .toList();

  List<FruitType> get neglectedFruits => FruitType.values
      .where((f) => (entries[f]?.habitCount ?? 0) == 0)
      .toList();

  FruitType? get dominantFruit {
    FruitType? top;
    int topCount = 0;
    for (final f in FruitType.values) {
      final count = entries[f]?.weeklyCompletions ?? 0;
      if (count > topCount) {
        topCount = count;
        top = f;
      }
    }
    return top;
  }

  /// Percentage of fruits that have at least one weekly completion (0–100).
  int get weeklyBalance {
    final withCompletions =
        FruitType.values.where((f) => (entries[f]?.weeklyCompletions ?? 0) > 0).length;
    return (withCompletions / FruitType.values.length * 100).round();
  }
}
