import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? name;
  final String? email;
  final List<String> identitySelections;
  final DateTime createdAt;
  final DateTime? weekDedicatedAt;
  final DateTime? onboardingDate;

  const UserProfile({
    required this.uid,
    this.name,
    this.email,
    this.identitySelections = const [],
    required this.createdAt,
    this.weekDedicatedAt,
    this.onboardingDate,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    List<String>? identitySelections,
    DateTime? weekDedicatedAt,
    DateTime? onboardingDate,
  }) =>
      UserProfile(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        identitySelections: identitySelections ?? this.identitySelections,
        createdAt: createdAt,
        weekDedicatedAt: weekDedicatedAt ?? this.weekDedicatedAt,
        onboardingDate: onboardingDate ?? this.onboardingDate,
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'identitySelections': identitySelections,
        'createdAt': Timestamp.fromDate(createdAt),
        if (weekDedicatedAt != null) 'weekDedicatedAt': Timestamp.fromDate(weekDedicatedAt!),
        if (onboardingDate != null) 'onboardingDate': Timestamp.fromDate(onboardingDate!),
      };

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    DateTime parseTimestamp(Object? raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseOptionalTimestamp(Object? raw) {
      if (raw == null) return null;
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return UserProfile(
      uid: uid,
      name: data['name'] as String?,
      email: data['email'] as String?,
      identitySelections: (data['identitySelections'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: parseTimestamp(data['createdAt']),
      weekDedicatedAt: parseOptionalTimestamp(data['weekDedicatedAt']),
      onboardingDate: parseOptionalTimestamp(data['onboardingDate']),
    );
  }
}
