import 'package:cloud_firestore/cloud_firestore.dart';

/// State for Module 1 (Know Your Pattern).
class RecoveryModule1State {
  final int dailyCheckInCount;
  final DateTime? lastCheckInAt;

  const RecoveryModule1State({
    this.dailyCheckInCount = 0,
    this.lastCheckInAt,
  });

  RecoveryModule1State copyWith({
    int? dailyCheckInCount,
    DateTime? lastCheckInAt,
  }) =>
      RecoveryModule1State(
        dailyCheckInCount: dailyCheckInCount ?? this.dailyCheckInCount,
        lastCheckInAt: lastCheckInAt ?? this.lastCheckInAt,
      );

  Map<String, dynamic> toMap() => {
        'dailyCheckInCount': dailyCheckInCount,
        'lastCheckInAt':
            lastCheckInAt != null ? Timestamp.fromDate(lastCheckInAt!) : null,
      };

  factory RecoveryModule1State.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const RecoveryModule1State();
    return RecoveryModule1State(
      dailyCheckInCount: (m['dailyCheckInCount'] as int?) ?? 0,
      lastCheckInAt: (m['lastCheckInAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A single domain entry in the values inventory (Module 3).
class ValuesInventoryEntry {
  final String domain;
  final int importance; // 1–5
  final int alignment; // 1–5

  int get gap => importance - alignment;

  const ValuesInventoryEntry({
    required this.domain,
    required this.importance,
    required this.alignment,
  });

  ValuesInventoryEntry copyWith({int? importance, int? alignment}) =>
      ValuesInventoryEntry(
        domain: domain,
        importance: importance ?? this.importance,
        alignment: alignment ?? this.alignment,
      );

  Map<String, dynamic> toMap() =>
      {'domain': domain, 'importance': importance, 'alignment': alignment};

  factory ValuesInventoryEntry.fromMap(Map<String, dynamic> m) =>
      ValuesInventoryEntry(
        domain: m['domain'] as String,
        importance: (m['importance'] as int?) ?? 3,
        alignment: (m['alignment'] as int?) ?? 3,
      );
}

/// State for Module 3 (Anchor to Your Values).
class RecoveryModule3State {
  final bool valuesInventoryDone;
  final List<ValuesInventoryEntry> valuesInventory;
  final DateTime? lastCompassAt;

  const RecoveryModule3State({
    this.valuesInventoryDone = false,
    this.valuesInventory = const [],
    this.lastCompassAt,
  });

  RecoveryModule3State copyWith({
    bool? valuesInventoryDone,
    List<ValuesInventoryEntry>? valuesInventory,
    DateTime? lastCompassAt,
  }) =>
      RecoveryModule3State(
        valuesInventoryDone: valuesInventoryDone ?? this.valuesInventoryDone,
        valuesInventory: valuesInventory ?? this.valuesInventory,
        lastCompassAt: lastCompassAt ?? this.lastCompassAt,
      );

  Map<String, dynamic> toMap() => {
        'valuesInventoryDone': valuesInventoryDone,
        'valuesInventory': valuesInventory.map((e) => e.toMap()).toList(),
        'lastCompassAt':
            lastCompassAt != null ? Timestamp.fromDate(lastCompassAt!) : null,
      };

  factory RecoveryModule3State.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const RecoveryModule3State();
    final raw = m['valuesInventory'];
    final inventory = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(ValuesInventoryEntry.fromMap)
            .toList()
        : <ValuesInventoryEntry>[];
    return RecoveryModule3State(
      valuesInventoryDone: (m['valuesInventoryDone'] as bool?) ?? false,
      valuesInventory: inventory,
      lastCompassAt: (m['lastCompassAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A single High-Risk Situation plan (Module 4).
class HrsPlan {
  final String situation;
  final String earlyWarnings;
  final String firstResponse;
  final String contactName;

  const HrsPlan({
    required this.situation,
    required this.earlyWarnings,
    required this.firstResponse,
    required this.contactName,
  });

  HrsPlan copyWith({
    String? situation,
    String? earlyWarnings,
    String? firstResponse,
    String? contactName,
  }) =>
      HrsPlan(
        situation: situation ?? this.situation,
        earlyWarnings: earlyWarnings ?? this.earlyWarnings,
        firstResponse: firstResponse ?? this.firstResponse,
        contactName: contactName ?? this.contactName,
      );

  Map<String, dynamic> toMap() => {
        'situation': situation,
        'earlyWarnings': earlyWarnings,
        'firstResponse': firstResponse,
        'contactName': contactName,
      };

  factory HrsPlan.fromMap(Map<String, dynamic> m) => HrsPlan(
        situation: (m['situation'] as String?) ?? '',
        earlyWarnings: (m['earlyWarnings'] as String?) ?? '',
        firstResponse: (m['firstResponse'] as String?) ?? '',
        contactName: (m['contactName'] as String?) ?? '',
      );
}

/// State for Module 4 (Build Your Guardrails).
class RecoveryModule4State {
  final bool environmentalChecklistDone;
  final List<HrsPlan> hrsPlan;
  final int urgeSurfingCount;

  const RecoveryModule4State({
    this.environmentalChecklistDone = false,
    this.hrsPlan = const [],
    this.urgeSurfingCount = 0,
  });

  RecoveryModule4State copyWith({
    bool? environmentalChecklistDone,
    List<HrsPlan>? hrsPlan,
    int? urgeSurfingCount,
  }) =>
      RecoveryModule4State(
        environmentalChecklistDone:
            environmentalChecklistDone ?? this.environmentalChecklistDone,
        hrsPlan: hrsPlan ?? this.hrsPlan,
        urgeSurfingCount: urgeSurfingCount ?? this.urgeSurfingCount,
      );

  Map<String, dynamic> toMap() => {
        'environmentalChecklistDone': environmentalChecklistDone,
        'hrsPlan': hrsPlan.map((p) => p.toMap()).toList(),
        'urgeSurfingCount': urgeSurfingCount,
      };

  factory RecoveryModule4State.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const RecoveryModule4State();
    final raw = m['hrsPlan'];
    final plans = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(HrsPlan.fromMap).toList()
        : <HrsPlan>[];
    return RecoveryModule4State(
      environmentalChecklistDone:
          (m['environmentalChecklistDone'] as bool?) ?? false,
      hrsPlan: plans,
      urgeSurfingCount: (m['urgeSurfingCount'] as int?) ?? 0,
    );
  }
}

/// State for Module 5 (Navigate Lapses).
class RecoveryModule5State {
  final bool recoveryLetterWritten;
  final int quarterlyReviewCount;

  const RecoveryModule5State({
    this.recoveryLetterWritten = false,
    this.quarterlyReviewCount = 0,
  });

  RecoveryModule5State copyWith({
    bool? recoveryLetterWritten,
    int? quarterlyReviewCount,
  }) =>
      RecoveryModule5State(
        recoveryLetterWritten: recoveryLetterWritten ?? this.recoveryLetterWritten,
        quarterlyReviewCount: quarterlyReviewCount ?? this.quarterlyReviewCount,
      );

  Map<String, dynamic> toMap() => {
        'recoveryLetterWritten': recoveryLetterWritten,
        'quarterlyReviewCount': quarterlyReviewCount,
      };

  factory RecoveryModule5State.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const RecoveryModule5State();
    return RecoveryModule5State(
      recoveryLetterWritten: (m['recoveryLetterWritten'] as bool?) ?? false,
      quarterlyReviewCount: (m['quarterlyReviewCount'] as int?) ?? 0,
    );
  }
}

/// Top-level recovery path document (doc ID = habitId).
/// Stored at: recovery_paths/{habitId}
class RecoveryPath {
  final String id; // == habitId
  final String userId;
  final String habitId;
  final DateTime startedAt;
  final int currentPhase; // 1–4; written back when it changes
  final RecoveryModule1State module1;
  final RecoveryModule3State module3;
  final RecoveryModule4State module4;
  final RecoveryModule5State module5;
  final int totalLapses;
  final DateTime? lastLapseAt;
  final String? recoveryLetterDraft;
  final List<String> counterResponses;

  const RecoveryPath({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.startedAt,
    this.currentPhase = 1,
    this.module1 = const RecoveryModule1State(),
    this.module3 = const RecoveryModule3State(),
    this.module4 = const RecoveryModule4State(),
    this.module5 = const RecoveryModule5State(),
    this.totalLapses = 0,
    this.lastLapseAt,
    this.recoveryLetterDraft,
    this.counterResponses = const [],
  });

  RecoveryPath copyWith({
    int? currentPhase,
    RecoveryModule1State? module1,
    RecoveryModule3State? module3,
    RecoveryModule4State? module4,
    RecoveryModule5State? module5,
    int? totalLapses,
    DateTime? lastLapseAt,
    String? recoveryLetterDraft,
    List<String>? counterResponses,
  }) =>
      RecoveryPath(
        id: id,
        userId: userId,
        habitId: habitId,
        startedAt: startedAt,
        currentPhase: currentPhase ?? this.currentPhase,
        module1: module1 ?? this.module1,
        module3: module3 ?? this.module3,
        module4: module4 ?? this.module4,
        module5: module5 ?? this.module5,
        totalLapses: totalLapses ?? this.totalLapses,
        lastLapseAt: lastLapseAt ?? this.lastLapseAt,
        recoveryLetterDraft: recoveryLetterDraft ?? this.recoveryLetterDraft,
        counterResponses: counterResponses ?? this.counterResponses,
      );

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'habitId': habitId,
        'startedAt': Timestamp.fromDate(startedAt),
        'currentPhase': currentPhase,
        'module1': module1.toMap(),
        'module3': module3.toMap(),
        'module4': module4.toMap(),
        'module5': module5.toMap(),
        'totalLapses': totalLapses,
        'lastLapseAt':
            lastLapseAt != null ? Timestamp.fromDate(lastLapseAt!) : null,
        'recoveryLetterDraft': recoveryLetterDraft,
        'counterResponses': counterResponses,
      };

  factory RecoveryPath.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RecoveryPath(
      id: doc.id,
      userId: d['userId'] as String,
      habitId: d['habitId'] as String,
      startedAt: (d['startedAt'] as Timestamp).toDate(),
      currentPhase: (d['currentPhase'] as int?) ?? 1,
      module1: RecoveryModule1State.fromMap(d['module1'] as Map<String, dynamic>?),
      module3: RecoveryModule3State.fromMap(d['module3'] as Map<String, dynamic>?),
      module4: RecoveryModule4State.fromMap(d['module4'] as Map<String, dynamic>?),
      module5: RecoveryModule5State.fromMap(d['module5'] as Map<String, dynamic>?),
      totalLapses: (d['totalLapses'] as int?) ?? 0,
      lastLapseAt: (d['lastLapseAt'] as Timestamp?)?.toDate(),
      recoveryLetterDraft: d['recoveryLetterDraft'] as String?,
      counterResponses: List<String>.from(d['counterResponses'] ?? []),
    );
  }
}
