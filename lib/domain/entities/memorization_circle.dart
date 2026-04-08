import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// CircleComment — stored in /memorizationCircles/{id}/comments/{commentId}
// ---------------------------------------------------------------------------

class CircleComment {
  final String id;
  final String authorUid;
  final String text;
  final DateTime createdAt;

  const CircleComment({
    required this.id,
    required this.authorUid,
    required this.text,
    required this.createdAt,
  });

  factory CircleComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CircleComment(
      id: doc.id,
      authorUid: data['authorUid'] as String,
      text: data['text'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

/// A community memorization circle — stored in /memorizationCircles/{circleId}.
/// Members share a common memorization goal (text + target date).
class MemorizationCircle {
  final String id;
  final String name;
  final String createdBy; // uid of circle leader
  final List<String> memberIds;

  /// The shared text all members are memorising.
  final String itemText;
  final String itemTitle; // e.g. "Psalm 23"

  final DateTime? targetDate;
  final DateTime createdAt;

  /// Summary of each member's mastery % — denormalised for leaderboard display.
  /// Map of uid → masteryPercent (0–100).
  final Map<String, double> memberMastery;

  const MemorizationCircle({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.memberIds,
    required this.itemText,
    required this.itemTitle,
    this.targetDate,
    required this.createdAt,
    required this.memberMastery,
  });

  factory MemorizationCircle.create({
    required String name,
    required String createdBy,
    required String itemText,
    required String itemTitle,
    DateTime? targetDate,
  }) {
    final now = DateTime.now();
    return MemorizationCircle(
      id: const Uuid().v4(),
      name: name,
      createdBy: createdBy,
      memberIds: [createdBy],
      itemText: itemText,
      itemTitle: itemTitle,
      targetDate: targetDate,
      createdAt: now,
      memberMastery: {createdBy: 0.0},
    );
  }

  MemorizationCircle copyWith({
    String? name,
    List<String>? memberIds,
    String? itemText,
    String? itemTitle,
    DateTime? targetDate,
    Map<String, double>? memberMastery,
  }) {
    return MemorizationCircle(
      id: id,
      name: name ?? this.name,
      createdBy: createdBy,
      memberIds: memberIds ?? this.memberIds,
      itemText: itemText ?? this.itemText,
      itemTitle: itemTitle ?? this.itemTitle,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt,
      memberMastery: memberMastery ?? this.memberMastery,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'createdBy': createdBy,
        'memberIds': memberIds,
        'itemText': itemText,
        'itemTitle': itemTitle,
        'targetDate':
            targetDate != null ? Timestamp.fromDate(targetDate!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'memberMastery': memberMastery,
      };

  factory MemorizationCircle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawMastery = data['memberMastery'] as Map<String, dynamic>? ?? {};
    return MemorizationCircle(
      id: doc.id,
      name: data['name'] as String,
      createdBy: data['createdBy'] as String,
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
      itemText: data['itemText'] as String,
      itemTitle: data['itemTitle'] as String,
      targetDate: (data['targetDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      memberMastery: rawMastery.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
    );
  }
}
