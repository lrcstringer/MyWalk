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
/// importance and alignment are now 1–10 (previously 1–5).
class ValuesInventoryEntry {
  final String domain;
  final int importance;          // 1–10
  final int alignment;           // 1–10
  final String reflectionText;   // user's written reflection for this domain
  final String compassDirection; // 'toward' | 'neutral' | 'away'

  int get gap => importance - alignment;

  const ValuesInventoryEntry({
    required this.domain,
    required this.importance,
    required this.alignment,
    this.reflectionText = '',
    this.compassDirection = 'neutral',
  });

  ValuesInventoryEntry copyWith({
    int? importance,
    int? alignment,
    String? reflectionText,
    String? compassDirection,
  }) =>
      ValuesInventoryEntry(
        domain: domain,
        importance: importance ?? this.importance,
        alignment: alignment ?? this.alignment,
        reflectionText: reflectionText ?? this.reflectionText,
        compassDirection: compassDirection ?? this.compassDirection,
      );

  Map<String, dynamic> toMap() => {
        'domain': domain,
        'importance': importance,
        'alignment': alignment,
        'reflectionText': reflectionText,
        'compassDirection': compassDirection,
      };

  factory ValuesInventoryEntry.fromMap(Map<String, dynamic> m) =>
      ValuesInventoryEntry(
        domain: m['domain'] as String,
        importance: (m['importance'] as int?) ?? 5,
        alignment: (m['alignment'] as int?) ?? 5,
        reflectionText: (m['reflectionText'] as String?) ?? '',
        compassDirection: (m['compassDirection'] as String?) ?? 'neutral',
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

  // Module sub-states
  final RecoveryModule1State module1;
  final RecoveryModule3State module3;
  final RecoveryModule4State module4;
  final RecoveryModule5State module5;

  // Lapse tracking
  final int totalLapses;
  final DateTime? lastLapseAt;

  // Letter and counter-responses
  final String? recoveryLetterDraft;
  // counterResponses stores Maps {thought, errorType, alternative, createdAt}.
  // Old Firestore docs may have Strings — fromFirestore handles both.
  final List<Map<String, dynamic>> counterResponses;

  // Habit classification for AI cue analysis
  final String habitType; // e.g. 'pornography', 'alcohol', 'generic'

  // Cue Hierarchy (built in Phase 2 flow)
  final bool cueHierarchyDone;
  final List<Map<String, dynamic>> cueHierarchy; // {rank, cueText, isAiSuggested}

  // Guardrail progression flags
  final bool environmentalChangesDone;
  final bool hrsPlanDone;
  final bool urgeSurfingIntroSeen;

  // Module 5 progression
  final bool module5IntroSeen;

  // Lapse button availability (always = startedAt; kept for future config)
  final DateTime? lapseButtonAvailableFrom;

  // Lifestyle audit
  final DateTime? lastLifestyleAuditAt;

  // Quarterly review schedule
  final List<int> quarterlyReviewDueDays; // days on which review should surface

  // Draft state for resumable flows
  final int thoughtExaminationDraftStep;
  final Map<String, dynamic>? thoughtExaminationDraft;
  final int valuesInventoryDraftStep;
  final List<Map<String, dynamic>> valuesInventoryDraft;
  final int cueHierarchyDraftStage;

  // Daily check-in transient state (reset each day on load)
  final int? dailyCheckInEmotionalRating;
  final String? dailyCheckInOutcome; // 'slipped' | 'urge_only' | 'clear'

  // Mid-point reflection
  final bool midPointReflectionDone;

  // Phase transition shown flags — each shown once only
  final bool phase2TransitionShown;
  final bool phase4TransitionShown;

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
    this.habitType = '',
    this.cueHierarchyDone = false,
    this.cueHierarchy = const [],
    this.environmentalChangesDone = false,
    this.hrsPlanDone = false,
    this.urgeSurfingIntroSeen = false,
    this.module5IntroSeen = false,
    this.lapseButtonAvailableFrom,
    this.lastLifestyleAuditAt,
    this.quarterlyReviewDueDays = const [90, 180, 270, 360],
    this.thoughtExaminationDraftStep = 0,
    this.thoughtExaminationDraft,
    this.valuesInventoryDraftStep = 0,
    this.valuesInventoryDraft = const [],
    this.cueHierarchyDraftStage = 0,
    this.dailyCheckInEmotionalRating,
    this.dailyCheckInOutcome,
    this.midPointReflectionDone = false,
    this.phase2TransitionShown = false,
    this.phase4TransitionShown = false,
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
    List<Map<String, dynamic>>? counterResponses,
    String? habitType,
    bool? cueHierarchyDone,
    List<Map<String, dynamic>>? cueHierarchy,
    bool? environmentalChangesDone,
    bool? hrsPlanDone,
    bool? urgeSurfingIntroSeen,
    bool? module5IntroSeen,
    DateTime? lapseButtonAvailableFrom,
    DateTime? lastLifestyleAuditAt,
    List<int>? quarterlyReviewDueDays,
    int? thoughtExaminationDraftStep,
    Map<String, dynamic>? thoughtExaminationDraft,
    int? valuesInventoryDraftStep,
    List<Map<String, dynamic>>? valuesInventoryDraft,
    int? cueHierarchyDraftStage,
    int? dailyCheckInEmotionalRating,
    String? dailyCheckInOutcome,
    bool? midPointReflectionDone,
    bool? phase2TransitionShown,
    bool? phase4TransitionShown,
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
        habitType: habitType ?? this.habitType,
        cueHierarchyDone: cueHierarchyDone ?? this.cueHierarchyDone,
        cueHierarchy: cueHierarchy ?? this.cueHierarchy,
        environmentalChangesDone:
            environmentalChangesDone ?? this.environmentalChangesDone,
        hrsPlanDone: hrsPlanDone ?? this.hrsPlanDone,
        urgeSurfingIntroSeen: urgeSurfingIntroSeen ?? this.urgeSurfingIntroSeen,
        module5IntroSeen: module5IntroSeen ?? this.module5IntroSeen,
        lapseButtonAvailableFrom:
            lapseButtonAvailableFrom ?? this.lapseButtonAvailableFrom,
        lastLifestyleAuditAt: lastLifestyleAuditAt ?? this.lastLifestyleAuditAt,
        quarterlyReviewDueDays:
            quarterlyReviewDueDays ?? this.quarterlyReviewDueDays,
        thoughtExaminationDraftStep:
            thoughtExaminationDraftStep ?? this.thoughtExaminationDraftStep,
        thoughtExaminationDraft:
            thoughtExaminationDraft ?? this.thoughtExaminationDraft,
        valuesInventoryDraftStep:
            valuesInventoryDraftStep ?? this.valuesInventoryDraftStep,
        valuesInventoryDraft: valuesInventoryDraft ?? this.valuesInventoryDraft,
        cueHierarchyDraftStage:
            cueHierarchyDraftStage ?? this.cueHierarchyDraftStage,
        dailyCheckInEmotionalRating:
            dailyCheckInEmotionalRating ?? this.dailyCheckInEmotionalRating,
        dailyCheckInOutcome: dailyCheckInOutcome ?? this.dailyCheckInOutcome,
        midPointReflectionDone:
            midPointReflectionDone ?? this.midPointReflectionDone,
        phase2TransitionShown:
            phase2TransitionShown ?? this.phase2TransitionShown,
        phase4TransitionShown:
            phase4TransitionShown ?? this.phase4TransitionShown,
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
        'habitType': habitType,
        'cueHierarchyDone': cueHierarchyDone,
        'cueHierarchy': cueHierarchy,
        'environmentalChangesDone': environmentalChangesDone,
        'hrsPlanDone': hrsPlanDone,
        'urgeSurfingIntroSeen': urgeSurfingIntroSeen,
        'module5IntroSeen': module5IntroSeen,
        'lapseButtonAvailableFrom': lapseButtonAvailableFrom != null
            ? Timestamp.fromDate(lapseButtonAvailableFrom!)
            : null,
        'lastLifestyleAuditAt': lastLifestyleAuditAt != null
            ? Timestamp.fromDate(lastLifestyleAuditAt!)
            : null,
        'quarterlyReviewDueDays': quarterlyReviewDueDays,
        'thoughtExaminationDraftStep': thoughtExaminationDraftStep,
        'thoughtExaminationDraft': thoughtExaminationDraft,
        'valuesInventoryDraftStep': valuesInventoryDraftStep,
        'valuesInventoryDraft': valuesInventoryDraft,
        'cueHierarchyDraftStage': cueHierarchyDraftStage,
        'dailyCheckInEmotionalRating': dailyCheckInEmotionalRating,
        'dailyCheckInOutcome': dailyCheckInOutcome,
        'midPointReflectionDone': midPointReflectionDone,
        'phase2TransitionShown': phase2TransitionShown,
        'phase4TransitionShown': phase4TransitionShown,
      };

  factory RecoveryPath.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // counterResponses: old docs have List<String>, new docs have List<Map>.
    // Normalise either format to List<Map<String, dynamic>>.
    final rawResponses = d['counterResponses'];
    final counterResponses = <Map<String, dynamic>>[];
    if (rawResponses is List) {
      for (final item in rawResponses) {
        if (item is Map) {
          counterResponses.add(Map<String, dynamic>.from(item));
        } else if (item is String) {
          counterResponses.add({'alternative': item});
        }
      }
    }

    final rawCueHierarchy = d['cueHierarchy'];
    final cueHierarchy = rawCueHierarchy is List
        ? rawCueHierarchy
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : <Map<String, dynamic>>[];

    final rawVIDraft = d['valuesInventoryDraft'];
    final valuesInventoryDraft = rawVIDraft is List
        ? rawVIDraft
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : <Map<String, dynamic>>[];

    final rawTEDraft = d['thoughtExaminationDraft'];
    final thoughtExaminationDraft = rawTEDraft is Map
        ? Map<String, dynamic>.from(rawTEDraft)
        : null;

    final rawQRDays = d['quarterlyReviewDueDays'];
    final quarterlyReviewDueDays = rawQRDays is List
        ? rawQRDays.whereType<int>().toList()
        : const <int>[90, 180, 270, 360];

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
      counterResponses: counterResponses,
      habitType: (d['habitType'] as String?) ?? '',
      cueHierarchyDone: (d['cueHierarchyDone'] as bool?) ?? false,
      cueHierarchy: cueHierarchy,
      environmentalChangesDone: (d['environmentalChangesDone'] as bool?) ?? false,
      hrsPlanDone: (d['hrsPlanDone'] as bool?) ?? false,
      urgeSurfingIntroSeen: (d['urgeSurfingIntroSeen'] as bool?) ?? false,
      module5IntroSeen: (d['module5IntroSeen'] as bool?) ?? false,
      lapseButtonAvailableFrom:
          (d['lapseButtonAvailableFrom'] as Timestamp?)?.toDate(),
      lastLifestyleAuditAt:
          (d['lastLifestyleAuditAt'] as Timestamp?)?.toDate(),
      quarterlyReviewDueDays: quarterlyReviewDueDays,
      thoughtExaminationDraftStep:
          (d['thoughtExaminationDraftStep'] as int?) ?? 0,
      thoughtExaminationDraft: thoughtExaminationDraft,
      valuesInventoryDraftStep: (d['valuesInventoryDraftStep'] as int?) ?? 0,
      valuesInventoryDraft: valuesInventoryDraft,
      cueHierarchyDraftStage: (d['cueHierarchyDraftStage'] as int?) ?? 0,
      dailyCheckInEmotionalRating:
          d['dailyCheckInEmotionalRating'] as int?,
      dailyCheckInOutcome: d['dailyCheckInOutcome'] as String?,
      midPointReflectionDone: (d['midPointReflectionDone'] as bool?) ?? false,
      phase2TransitionShown: (d['phase2TransitionShown'] as bool?) ?? false,
      phase4TransitionShown: (d['phase4TransitionShown'] as bool?) ?? false,
    );
  }
}
