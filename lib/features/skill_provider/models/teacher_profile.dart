import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherProfile {
  const TeacherProfile({
    required this.uid,
    required this.displayName,
    required this.bio,
    required this.verifiedSkills,
    required this.overallRating,
    required this.completedSessions,
    required this.totalReviews,
    this.profileImageUrl,
    this.email,
    this.location,
  });

  final String uid;
  final String displayName;
  final String bio;
  final List<String> verifiedSkills;
  final double overallRating;
  final int completedSessions;
  final int totalReviews;
  final String? profileImageUrl;
  final String? email;
  final String? location;

  TeacherProfile copyWith({
    String? displayName,
    String? bio,
    List<String>? verifiedSkills,
    String? profileImageUrl,
    String? email,
    String? location,
    double? overallRating,
    int? completedSessions,
    int? totalReviews,
    bool clearImage = false,
  }) {
    return TeacherProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      verifiedSkills: verifiedSkills ?? this.verifiedSkills,
      overallRating: overallRating ?? this.overallRating,
      completedSessions: completedSessions ?? this.completedSessions,
      totalReviews: totalReviews ?? this.totalReviews,
      profileImageUrl:
          clearImage ? null : (profileImageUrl ?? this.profileImageUrl),
      email: email ?? this.email,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'bio': bio,
      'verifiedSkills': verifiedSkills,
      'profileImageUrl': profileImageUrl,
      'email': email,
      'location': location,
    };
  }

  factory TeacherProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TeacherProfile.fromDocData(doc.id, data);
  }

  factory TeacherProfile.fromDocData(String uid, Map<String, dynamic> data) {
    return TeacherProfile(
      uid: uid,
      displayName: data['displayName'] as String? ??
          data['fullName'] as String? ??
          '',
      bio: data['bio'] as String? ?? '',
      verifiedSkills: List<String>.from(data['verifiedSkills'] as List? ?? []),
      overallRating: (data['overallRating'] as num?)?.toDouble() ?? 0,
      completedSessions: data['completedSessions'] as int? ?? 0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      profileImageUrl: data['profileImageUrl'] as String?,
      email: data['email'] as String?,
      location: data['location'] as String?,
    );
  }
}
