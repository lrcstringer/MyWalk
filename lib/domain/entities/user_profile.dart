import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? name;
  final String? email;
  final String? photoURL;
  final List<String> identitySelections;
  final DateTime createdAt;
  final DateTime? weekDedicatedAt;
  final DateTime? onboardingDate;
  final String? firstName;
  final String? surname;
  final String? phone;

  const UserProfile({
    required this.uid,
    this.name,
    this.email,
    this.photoURL,
    this.identitySelections = const [],
    required this.createdAt,
    this.weekDedicatedAt,
    this.onboardingDate,
    this.firstName,
    this.surname,
    this.phone,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? photoURL,
    List<String>? identitySelections,
    DateTime? weekDedicatedAt,
    DateTime? onboardingDate,
    String? firstName,
    String? surname,
    String? phone,
  }) =>
      UserProfile(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        photoURL: photoURL ?? this.photoURL,
        identitySelections: identitySelections ?? this.identitySelections,
        createdAt: createdAt,
        weekDedicatedAt: weekDedicatedAt ?? this.weekDedicatedAt,
        onboardingDate: onboardingDate ?? this.onboardingDate,
        firstName: firstName ?? this.firstName,
        surname: surname ?? this.surname,
        phone: phone ?? this.phone,
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'identitySelections': identitySelections,
        'createdAt': Timestamp.fromDate(createdAt),
        if (photoURL != null) 'photoURL': photoURL,
        if (weekDedicatedAt != null) 'weekDedicatedAt': Timestamp.fromDate(weekDedicatedAt!),
        if (onboardingDate != null) 'onboardingDate': Timestamp.fromDate(onboardingDate!),
        if (firstName != null) 'firstName': firstName,
        if (surname != null) 'surname': surname,
        if (phone != null) 'phone': phone,
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
      photoURL: data['photoURL'] as String?,
      identitySelections: (data['identitySelections'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: parseTimestamp(data['createdAt']),
      weekDedicatedAt: parseOptionalTimestamp(data['weekDedicatedAt']),
      onboardingDate: parseOptionalTimestamp(data['onboardingDate']),
      firstName: data['firstName'] as String?,
      surname: data['surname'] as String?,
      phone: data['phone'] as String?,
    );
  }
}
