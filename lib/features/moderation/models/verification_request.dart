import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationType {
  identity,
  skill;

  String get displayName {
    switch (this) {
      case VerificationType.identity:
        return 'Identity Verification';
      case VerificationType.skill:
        return 'Skill Verification';
    }
  }
}

enum VerificationStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }
}

class VerificationRequest {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final VerificationType verificationType;
  
  // Identity Verification fields
  final String? fullName;
  final String? identityDocumentUrl;
  
  // Skill Verification fields
  final String? skillName;
  final String? experienceDescription;
  final List<String>? evidenceUrls;
  final String? portfolioUrl;
  
  final VerificationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  VerificationRequest({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.verificationType,
    this.fullName,
    this.identityDocumentUrl,
    this.skillName,
    this.experienceDescription,
    this.evidenceUrls,
    this.portfolioUrl,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  // Convert from Firestore document
  factory VerificationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final evidenceUrls = _asStringList(
      data['evidenceUrls'] ?? data['evidence'] ?? data['documents'],
    );
    final identityUrls = _asStringList(data['identityDocumentUrl']);
    final identityDocumentUrl = _asNullableString(data['identityDocumentUrl']) ??
        (identityUrls.isNotEmpty ? identityUrls.first : null);

    return VerificationRequest(
      id: doc.id,
      userId: _asString(data['userId']),
      userName: _asString(
        data['userName'] ?? data['displayName'] ?? data['fullName'] ?? data['name'],
      ),
      userProfileImage: _asNullableString(
        data['userProfileImage'] ?? data['profileImageUrl'] ?? data['photoURL'],
      ),
      verificationType: VerificationType.values.firstWhere(
        (e) => e.name == _asString(data['verificationType']),
        orElse: () => VerificationType.identity,
      ),
      fullName: _asNullableString(data['fullName']),
      identityDocumentUrl: identityDocumentUrl,
      skillName: _asJoinedString(
        data['skillName'] ?? data['skills'] ?? data['verifiedSkills'],
      ),
      experienceDescription: _asNullableString(data['experienceDescription']),
      evidenceUrls: evidenceUrls.isEmpty ? null : evidenceUrls,
      portfolioUrl: _asNullableString(data['portfolioUrl']),
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == _asString(data['status']),
        orElse: () => VerificationStatus.pending,
      ),
      submittedAt: _asDateTime(data['submittedAt'] ?? data['createdAt']),
      reviewedAt: _asNullableDateTime(data['reviewedAt']),
      reviewedBy: _asNullableString(data['reviewedBy']),
      rejectionReason: _asNullableString(data['rejectionReason']),
    );
  }

  static String _asString(dynamic value, [String fallback = '']) {
    return _asNullableString(value) ?? fallback;
  }

  static String? _asJoinedString(dynamic value) {
    if (value is List) {
      final parts = value
          .map(_asNullableString)
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
      if (parts.isEmpty) return null;
      return parts.join(', ');
    }
    return _asNullableString(value);
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : value;
    }
    if (value is List) {
      for (final item in value) {
        final parsed = _asNullableString(item);
        if (parsed != null) return parsed;
      }
      return null;
    }
    if (value is Map) {
      return _asNullableString(
        value['url'] ?? value['name'] ?? value['value'] ?? value['text'],
      );
    }
    return value.toString();
  }

  static List<String> _asStringList(dynamic value) {
    if (value == null) return const [];
    if (value is String) {
      final parsed = value.trim();
      return parsed.isEmpty ? const [] : [value];
    }
    if (value is List) {
      return value
          .map(_asNullableString)
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static DateTime _asDateTime(dynamic value) {
    return _asNullableDateTime(value) ?? DateTime.now();
  }

  static DateTime? _asNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'verificationType': verificationType.name,
      'fullName': fullName,
      'identityDocumentUrl': identityDocumentUrl,
      'skillName': skillName,
      'experienceDescription': experienceDescription,
      'evidenceUrls': evidenceUrls,
      'portfolioUrl': portfolioUrl,
      'status': status.name,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  // Create a copy with updated fields
  VerificationRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImage,
    VerificationType? verificationType,
    String? fullName,
    String? identityDocumentUrl,
    String? skillName,
    String? experienceDescription,
    List<String>? evidenceUrls,
    String? portfolioUrl,
    VerificationStatus? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      verificationType: verificationType ?? this.verificationType,
      fullName: fullName ?? this.fullName,
      identityDocumentUrl: identityDocumentUrl ?? this.identityDocumentUrl,
      skillName: skillName ?? this.skillName,
      experienceDescription: experienceDescription ?? this.experienceDescription,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
