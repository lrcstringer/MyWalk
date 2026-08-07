import 'package:cloud_firestore/cloud_firestore.dart';

enum RecoverySessionType {
  m1DailyCheckIn,
  m1WeeklyReview,
  m1BehaviourLog,
  m1MidPointReflection,
  m1CueHierarchy,
  m2ThoughtExamination,
  m3ValuesInventory,
  m3WeeklyCompass,
  m4UrgeSurfing,
  m4EnvironmentalRestructuring,
  m4LifestyleAudit,
  m5RecoveryLetter,
  m5QuarterlyReview,
  m5AveEducation,
  m5LapseResponse,
  lapseRecord;

  static RecoverySessionType fromString(String s) {
    return RecoverySessionType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => RecoverySessionType.m1DailyCheckIn,
    );
  }

  String get value => name;
}

/// Structured data captured during a lapse recording.
class LapseData {
  final String? time;               // approximate time of lapse
  final String? location;           // where the user was
  final String? trigger;            // what triggered it
  final String? emotion;            // emotional state before
  final String? selfCompassionText; // Screen 1 self-compassion response
  final String? copingPlanGapText;  // what user learned about coping plan gap
  final String? recommittedValue;   // which value they committed to
  final bool copingPlanUpdated;     // whether user tapped "Update my coping plan"

  const LapseData({
    this.time,
    this.location,
    this.trigger,
    this.emotion,
    this.selfCompassionText,
    this.copingPlanGapText,
    this.recommittedValue,
    this.copingPlanUpdated = false,
  });

  Map<String, dynamic> toMap() => {
        'time': time,
        'location': location,
        'trigger': trigger,
        'emotion': emotion,
        'selfCompassionText': selfCompassionText,
        'copingPlanGapText': copingPlanGapText,
        'recommittedValue': recommittedValue,
        'copingPlanUpdated': copingPlanUpdated,
      };

  factory LapseData.fromMap(Map<String, dynamic> m) => LapseData(
        time: m['time'] as String?,
        location: m['location'] as String?,
        trigger: m['trigger'] as String?,
        emotion: m['emotion'] as String?,
        selfCompassionText: m['selfCompassionText'] as String?,
        copingPlanGapText: m['copingPlanGapText'] as String?,
        recommittedValue: m['recommittedValue'] as String?,
        copingPlanUpdated: (m['copingPlanUpdated'] as bool?) ?? false,
      );
}

/// A single journalling/reflection session for the recovery path.
/// Stored at: recovery_paths/{habitId}/recovery_sessions/{sessionId}
/// [responseText] is stored encrypted (AES-256 via EncryptionService) in Firestore.
class RecoverySession {
  final String id;
  final String habitId;
  final RecoverySessionType sessionType;
  final int moduleNumber;
  final String responseText; // plain text in memory; encrypted in Firestore
  final DateTime createdAt;
  final LapseData? lapseData; // populated for lapseRecord and m5LapseResponse sessions

  const RecoverySession({
    required this.id,
    required this.habitId,
    required this.sessionType,
    required this.moduleNumber,
    required this.responseText,
    required this.createdAt,
    this.lapseData,
  });

  Map<String, dynamic> toFirestore({required String encryptedText}) => {
        'habitId': habitId,
        'sessionType': sessionType.value,
        'moduleNumber': moduleNumber,
        'responseText': encryptedText,
        'createdAt': Timestamp.fromDate(createdAt),
        if (lapseData != null) 'lapseData': lapseData!.toMap(),
      };

  factory RecoverySession.fromFirestore(
    DocumentSnapshot doc, {
    required String decryptedText,
  }) {
    final d = doc.data() as Map<String, dynamic>;
    final rawLapse = d['lapseData'];
    return RecoverySession(
      id: doc.id,
      habitId: d['habitId'] as String,
      sessionType: RecoverySessionType.fromString(d['sessionType'] as String),
      moduleNumber: (d['moduleNumber'] as int?) ?? 1,
      responseText: decryptedText,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      lapseData: rawLapse is Map<String, dynamic>
          ? LapseData.fromMap(rawLapse)
          : null,
    );
  }
}
