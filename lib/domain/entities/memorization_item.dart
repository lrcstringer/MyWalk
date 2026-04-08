import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// TextChunk — one memorisable phrase within a MemorizationItem
// ---------------------------------------------------------------------------

class TextChunk {
  final String id;
  final int sequenceNumber;
  final String text;
  final String hint; // first-letter scaffold, e.g. "F G s l t w"
  final int wordCount;
  final int successCount;
  final int attemptCount;

  const TextChunk({
    required this.id,
    required this.sequenceNumber,
    required this.text,
    required this.hint,
    required this.wordCount,
    this.successCount = 0,
    this.attemptCount = 0,
  });

  /// strengthScore drives the heat-map colour (0.0–1.0).
  /// Returns 0.5 (amber) until the chunk has been attempted at least once.
  double get strengthScore =>
      attemptCount == 0 ? 0.5 : successCount / attemptCount;

  factory TextChunk.create({
    required int sequenceNumber,
    required String text,
    required String hint,
  }) {
    final words = text.trim().split(RegExp(r'\s+'));
    return TextChunk(
      id: const Uuid().v4(),
      sequenceNumber: sequenceNumber,
      text: text,
      hint: hint,
      wordCount: words.isEmpty ? 0 : words.length,
    );
  }

  TextChunk copyWith({
    String? text,
    String? hint,
    int? sequenceNumber,
    int? successCount,
    int? attemptCount,
  }) {
    return TextChunk(
      id: id,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      text: text ?? this.text,
      hint: hint ?? this.hint,
      wordCount: (text ?? this.text).trim().split(RegExp(r'\s+')).length,
      successCount: successCount ?? this.successCount,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sequenceNumber': sequenceNumber,
        'text': text,
        'hint': hint,
        'wordCount': wordCount,
        'successCount': successCount,
        'attemptCount': attemptCount,
      };

  factory TextChunk.fromMap(Map<String, dynamic> map) => TextChunk(
        id: map['id'] as String,
        sequenceNumber: (map['sequenceNumber'] as num).toInt(),
        text: map['text'] as String,
        hint: map['hint'] as String,
        wordCount: (map['wordCount'] as num).toInt(),
        successCount: (map['successCount'] as num? ?? 0).toInt(),
        attemptCount: (map['attemptCount'] as num? ?? 0).toInt(),
      );
}

// ---------------------------------------------------------------------------
// MemorizationItem — root document per memorisation item
// ---------------------------------------------------------------------------

enum MemorizationStatus { active, mastered, archived }

class MemorizationItem {
  final String id;
  final String userId;
  final String title;
  final String fullText;
  final List<TextChunk> chunks;
  final MemorizationStatus status;

  /// Optional link to a MyWalk habit sub-category (e.g. scriptureRecall).
  final String? habitSubCategoryId;

  final DateTime createdAt;
  final DateTime? lastReviewedAt;

  /// SM2 — when the next review is due.
  final DateTime nextReviewDate;

  /// SM2 state
  final double intervalDays;   // starts at 1
  final double easeFactor;     // starts at 2.5, min 1.3
  final int repetitionCount;   // consecutive successes; resets on failure

  /// Stats
  final int totalAttempts;
  final int successfulAttempts; // quality >= 3
  final int streakCount;        // consecutive days reviewed

  /// Audio
  final String? audioUrl;  // user's own voice recording
  final String? ttsUrl;    // cached TTS audio (item-level, for full text)

  const MemorizationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.fullText,
    required this.chunks,
    required this.status,
    this.habitSubCategoryId,
    required this.createdAt,
    this.lastReviewedAt,
    required this.nextReviewDate,
    required this.intervalDays,
    required this.easeFactor,
    required this.repetitionCount,
    required this.totalAttempts,
    required this.successfulAttempts,
    required this.streakCount,
    this.audioUrl,
    this.ttsUrl,
  });

  double get masteryPercent =>
      totalAttempts == 0 ? 0.0 : (successfulAttempts / totalAttempts) * 100;

  bool get isDueNow => DateTime.now().isAfter(nextReviewDate);

  factory MemorizationItem.create({
    required String userId,
    required String title,
    required String fullText,
    List<TextChunk> chunks = const [],
    String? habitSubCategoryId,
  }) {
    final now = DateTime.now();
    return MemorizationItem(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      fullText: fullText,
      chunks: chunks,
      status: MemorizationStatus.active,
      habitSubCategoryId: habitSubCategoryId,
      createdAt: now,
      lastReviewedAt: null,
      // First review scheduled 12 hours after creation (initial session sets this).
      nextReviewDate: now.add(const Duration(hours: 12)),
      intervalDays: 1.0,
      easeFactor: 2.5,
      repetitionCount: 0,
      totalAttempts: 0,
      successfulAttempts: 0,
      streakCount: 0,
    );
  }

  MemorizationItem copyWith({
    String? title,
    String? fullText,
    List<TextChunk>? chunks,
    MemorizationStatus? status,
    String? habitSubCategoryId,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
    double? intervalDays,
    double? easeFactor,
    int? repetitionCount,
    int? totalAttempts,
    int? successfulAttempts,
    int? streakCount,
    String? audioUrl,
    String? ttsUrl,
  }) {
    return MemorizationItem(
      id: id,
      userId: userId,
      title: title ?? this.title,
      fullText: fullText ?? this.fullText,
      chunks: chunks ?? this.chunks,
      status: status ?? this.status,
      habitSubCategoryId: habitSubCategoryId ?? this.habitSubCategoryId,
      createdAt: createdAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      successfulAttempts: successfulAttempts ?? this.successfulAttempts,
      streakCount: streakCount ?? this.streakCount,
      audioUrl: audioUrl ?? this.audioUrl,
      ttsUrl: ttsUrl ?? this.ttsUrl,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'title': title,
        'fullText': fullText,
        'chunks': chunks.map((c) => c.toMap()).toList(),
        'status': status.name,
        'habitSubCategoryId': habitSubCategoryId,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastReviewedAt':
            lastReviewedAt != null ? Timestamp.fromDate(lastReviewedAt!) : null,
        'nextReviewDate': Timestamp.fromDate(nextReviewDate),
        'intervalDays': intervalDays,
        'easeFactor': easeFactor,
        'repetitionCount': repetitionCount,
        'totalAttempts': totalAttempts,
        'successfulAttempts': successfulAttempts,
        'streakCount': streakCount,
        'audioUrl': audioUrl,
        'ttsUrl': ttsUrl,
      };

  factory MemorizationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemorizationItem(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      fullText: data['fullText'] as String,
      chunks: (data['chunks'] as List<dynamic>? ?? [])
          .map((c) => TextChunk.fromMap(c as Map<String, dynamic>))
          .toList(),
      status: MemorizationStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? 'active'),
        orElse: () => MemorizationStatus.active,
      ),
      habitSubCategoryId: data['habitSubCategoryId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastReviewedAt:
          (data['lastReviewedAt'] as Timestamp?)?.toDate(),
      nextReviewDate: (data['nextReviewDate'] as Timestamp).toDate(),
      intervalDays: (data['intervalDays'] as num? ?? 1.0).toDouble(),
      easeFactor: (data['easeFactor'] as num? ?? 2.5).toDouble(),
      repetitionCount: (data['repetitionCount'] as num? ?? 0).toInt(),
      totalAttempts: (data['totalAttempts'] as num? ?? 0).toInt(),
      successfulAttempts: (data['successfulAttempts'] as num? ?? 0).toInt(),
      streakCount: (data['streakCount'] as num? ?? 0).toInt(),
      audioUrl: data['audioUrl'] as String?,
      ttsUrl: data['ttsUrl'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// ReviewAttempt — sub-collection document per individual review session
// ---------------------------------------------------------------------------

enum ReviewMode { cloze, progressive, flipCard, typing, recitation }

class ReviewAttempt {
  final String id;
  final ReviewMode mode;
  final DateTime attemptedAt;

  /// SM2 quality score 0–5.
  final int qualityScore;

  /// User-reported confidence 1–5.
  final int confidence;

  final int timeToRecallSeconds;

  /// IDs of TextChunks that failed — drives heat-map update.
  final List<String> missedChunkIds;

  /// Typing/recitation only.
  final String? userResponse;
  final double? levenshteinScore;

  /// Marks the very first review (12-hour window after initial session).
  /// SM2 proper begins on the second review.
  final bool isInitialReview;

  // SM2 audit trail
  final DateTime nextReviewScheduledFor;
  final double intervalDaysApplied;
  final double easeFactorAfter;

  const ReviewAttempt({
    required this.id,
    required this.mode,
    required this.attemptedAt,
    required this.qualityScore,
    required this.confidence,
    required this.timeToRecallSeconds,
    required this.missedChunkIds,
    this.userResponse,
    this.levenshteinScore,
    this.isInitialReview = false,
    required this.nextReviewScheduledFor,
    required this.intervalDaysApplied,
    required this.easeFactorAfter,
  });

  factory ReviewAttempt.create({
    required ReviewMode mode,
    required int qualityScore,
    required int confidence,
    required int timeToRecallSeconds,
    required List<String> missedChunkIds,
    String? userResponse,
    double? levenshteinScore,
    bool isInitialReview = false,
    required DateTime nextReviewScheduledFor,
    required double intervalDaysApplied,
    required double easeFactorAfter,
  }) {
    return ReviewAttempt(
      id: const Uuid().v4(),
      mode: mode,
      attemptedAt: DateTime.now(),
      qualityScore: qualityScore,
      confidence: confidence,
      timeToRecallSeconds: timeToRecallSeconds,
      missedChunkIds: missedChunkIds,
      userResponse: userResponse,
      levenshteinScore: levenshteinScore,
      isInitialReview: isInitialReview,
      nextReviewScheduledFor: nextReviewScheduledFor,
      intervalDaysApplied: intervalDaysApplied,
      easeFactorAfter: easeFactorAfter,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'mode': mode.name,
        'attemptedAt': Timestamp.fromDate(attemptedAt),
        'qualityScore': qualityScore,
        'confidence': confidence,
        'timeToRecallSeconds': timeToRecallSeconds,
        'missedChunkIds': missedChunkIds,
        'userResponse': userResponse,
        'levenshteinScore': levenshteinScore,
        'isInitialReview': isInitialReview,
        'nextReviewScheduledFor': Timestamp.fromDate(nextReviewScheduledFor),
        'intervalDaysApplied': intervalDaysApplied,
        'easeFactorAfter': easeFactorAfter,
      };

  factory ReviewAttempt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewAttempt(
      id: doc.id,
      mode: ReviewMode.values.firstWhere(
        (m) => m.name == (data['mode'] as String),
        orElse: () => ReviewMode.flipCard,
      ),
      attemptedAt: (data['attemptedAt'] as Timestamp).toDate(),
      qualityScore: (data['qualityScore'] as num).toInt(),
      confidence: (data['confidence'] as num).toInt(),
      timeToRecallSeconds: (data['timeToRecallSeconds'] as num).toInt(),
      missedChunkIds: List<String>.from(data['missedChunkIds'] as List? ?? []),
      userResponse: data['userResponse'] as String?,
      levenshteinScore: (data['levenshteinScore'] as num?)?.toDouble(),
      isInitialReview: data['isInitialReview'] as bool? ?? false,
      nextReviewScheduledFor:
          (data['nextReviewScheduledFor'] as Timestamp).toDate(),
      intervalDaysApplied: (data['intervalDaysApplied'] as num).toDouble(),
      easeFactorAfter: (data['easeFactorAfter'] as num).toDouble(),
    );
  }
}
