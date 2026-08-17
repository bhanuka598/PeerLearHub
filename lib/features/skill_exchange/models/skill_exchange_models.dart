enum ExchangeStatus {
  pendingTutorApproval,
  pendingPeerApproval,
  approved,
  rejected,
  completed,
  cancelled,
}

enum UserRole {
  student,
  lecturer,
  tutor,
}

enum SkillLevel {
  beginner,
  intermediate,
  advanced,
}

class ExchangeUser {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final UserRole role;
  final double rating;
  final int completedExchangesCount;
  final List<String> skillsOffered;
  final List<String> skillsWanted;

  const ExchangeUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.role,
    this.rating = 4.8,
    this.completedExchangesCount = 0,
    this.skillsOffered = const [],
    this.skillsWanted = const [],
  });

  bool get isLecturerOrTutor =>
      role == UserRole.lecturer || role == UserRole.tutor;
}

class ExchangeCourse {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final SkillLevel level;
  final String ownerId;
  final String ownerName;
  final String ownerAvatar;
  final UserRole ownerRole;
  final double rating;
  final int totalLessons;
  final int durationMinutes;
  final String thumbnailUrl;

  const ExchangeCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.level,
    required this.ownerId,
    required this.ownerName,
    required this.ownerAvatar,
    required this.ownerRole,
    this.rating = 4.8,
    this.totalLessons = 8,
    this.durationMinutes = 120,
    required this.thumbnailUrl,
  });
}

class SkillExchangeRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterAvatar;
  final UserRole requesterRole;
  final String offeredCourseId;
  final String offeredCourseTitle;
  final String targetOwnerId;
  final String targetOwnerName;
  final String targetOwnerAvatar;
  final String requestedCourseId;
  final String requestedCourseTitle;
  final ExchangeStatus status;
  final String message;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double matchScore;

  const SkillExchangeRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterAvatar,
    required this.requesterRole,
    required this.offeredCourseId,
    required this.offeredCourseTitle,
    required this.targetOwnerId,
    required this.targetOwnerName,
    required this.targetOwnerAvatar,
    required this.requestedCourseId,
    required this.requestedCourseTitle,
    required this.status,
    required this.message,
    required this.createdAt,
    this.updatedAt,
    this.matchScore = 0.0,
  });

  SkillExchangeRequest copyWith({
    ExchangeStatus? status,
    DateTime? updatedAt,
    String? message,
  }) {
    return SkillExchangeRequest(
      id: id,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterAvatar: requesterAvatar,
      requesterRole: requesterRole,
      offeredCourseId: offeredCourseId,
      offeredCourseTitle: offeredCourseTitle,
      targetOwnerId: targetOwnerId,
      targetOwnerName: targetOwnerName,
      targetOwnerAvatar: targetOwnerAvatar,
      requestedCourseId: requestedCourseId,
      requestedCourseTitle: requestedCourseTitle,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      matchScore: matchScore,
    );
  }
}

class AIMatchSuggestion {
  final ExchangeCourse offeredCourse;
  final ExchangeCourse suggestedCourse;
  final double matchPercentage;
  final List<String> matchingTags;
  final String reasoning;

  const AIMatchSuggestion({
    required this.offeredCourse,
    required this.suggestedCourse,
    required this.matchPercentage,
    required this.matchingTags,
    required this.reasoning,
  });
}
