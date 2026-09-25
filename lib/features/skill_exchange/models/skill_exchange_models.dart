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

  ExchangeCourse copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    SkillLevel? level,
    String? ownerId,
    String? ownerName,
    String? ownerAvatar,
    UserRole? ownerRole,
    double? rating,
    int? totalLessons,
    int? durationMinutes,
    String? thumbnailUrl,
  }) {
    return ExchangeCourse(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      level: level ?? this.level,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      ownerRole: ownerRole ?? this.ownerRole,
      rating: rating ?? this.rating,
      totalLessons: totalLessons ?? this.totalLessons,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'level': level.name,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerAvatar': ownerAvatar,
      'ownerRole': ownerRole.name,
      'rating': rating,
      'totalLessons': totalLessons,
      'durationMinutes': durationMinutes,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory ExchangeCourse.fromMap(Map<String, dynamic> map, [String? id]) {
    UserRole parsedRole = UserRole.student;
    final roleStr = map['ownerRole']?.toString().toLowerCase();
    if (roleStr == 'lecturer' || roleStr == 'teacher') {
      parsedRole = UserRole.lecturer;
    } else if (roleStr == 'tutor') {
      parsedRole = UserRole.tutor;
    }

    SkillLevel parsedLevel = SkillLevel.beginner;
    final lvlStr = map['level']?.toString().toLowerCase();
    if (lvlStr == 'intermediate') {
      parsedLevel = SkillLevel.intermediate;
    } else if (lvlStr == 'advanced') {
      parsedLevel = SkillLevel.advanced;
    }

    return ExchangeCourse(
      id: id ?? map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'General',
      tags: map['tags'] is List
          ? List<String>.from(map['tags'].map((t) => t.toString()))
          : (map['tags']?.toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? []),
      level: parsedLevel,
      ownerId: map['ownerId']?.toString() ?? map['providerId']?.toString() ?? '',
      ownerName: map['ownerName']?.toString() ?? 'Peer Instructor',
      ownerAvatar: map['ownerAvatar']?.toString() ??
          map['imageUrl']?.toString() ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      ownerRole: parsedRole,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      totalLessons: (map['totalLessons'] as num?)?.toInt() ?? 8,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 120,
      thumbnailUrl: map['thumbnailUrl']?.toString() ??
          map['imageUrl']?.toString() ??
          'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=500',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeCourse && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterAvatar': requesterAvatar,
      'requesterRole': requesterRole.name,
      'offeredCourseId': offeredCourseId,
      'offeredCourseTitle': offeredCourseTitle,
      'targetOwnerId': targetOwnerId,
      'targetOwnerName': targetOwnerName,
      'targetOwnerAvatar': targetOwnerAvatar,
      'requestedCourseId': requestedCourseId,
      'requestedCourseTitle': requestedCourseTitle,
      'status': status.name,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'matchScore': matchScore,
    };
  }

  factory SkillExchangeRequest.fromMap(Map<String, dynamic> map, [String? id]) {
    UserRole parsedRole = UserRole.student;
    final roleStr = map['requesterRole']?.toString().toLowerCase();
    if (roleStr == 'lecturer' || roleStr == 'teacher') {
      parsedRole = UserRole.lecturer;
    } else if (roleStr == 'tutor') {
      parsedRole = UserRole.tutor;
    }

    ExchangeStatus parsedStatus = ExchangeStatus.pendingTutorApproval;
    final statusStr = map['status']?.toString();
    for (final s in ExchangeStatus.values) {
      if (s.name == statusStr) {
        parsedStatus = s;
        break;
      }
    }

    DateTime parseDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      try {
        // Support Firestore Timestamp without direct import
        final dynamic dynVal = val;
        if (dynVal.toDate != null) {
          return dynVal.toDate() as DateTime;
        }
      } catch (_) {}
      return DateTime.now();
    }

    final parsedCreated = parseDateTime(map['createdAt']);
    final parsedUpdated = map['updatedAt'] != null ? parseDateTime(map['updatedAt']) : null;

    return SkillExchangeRequest(
      id: id ?? map['id']?.toString() ?? '',
      requesterId: map['requesterId']?.toString() ?? '',
      requesterName: map['requesterName']?.toString() ?? 'Peer Learner',
      requesterAvatar: map['requesterAvatar']?.toString() ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      requesterRole: parsedRole,
      offeredCourseId: map['offeredCourseId']?.toString() ?? '',
      offeredCourseTitle: map['offeredCourseTitle']?.toString() ?? '',
      targetOwnerId: map['targetOwnerId']?.toString() ?? '',
      targetOwnerName: map['targetOwnerName']?.toString() ?? 'Course Instructor',
      targetOwnerAvatar: map['targetOwnerAvatar']?.toString() ??
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      requestedCourseId: map['requestedCourseId']?.toString() ?? '',
      requestedCourseTitle: map['requestedCourseTitle']?.toString() ?? '',
      status: parsedStatus,
      message: map['message']?.toString() ?? '',
      createdAt: parsedCreated,
      updatedAt: parsedUpdated,
      matchScore: (map['matchScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

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
