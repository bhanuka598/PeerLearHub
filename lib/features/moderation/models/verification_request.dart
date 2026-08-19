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
    final data = doc.data() as Map<String, dynamic>;
    return VerificationRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfileImage: data['userProfileImage'],
      verificationType: VerificationType.values.firstWhere(
        (e) => e.name == data['verificationType'],
        orElse: () => VerificationType.identity,
      ),
      fullName: data['fullName'],
      identityDocumentUrl: data['identityDocumentUrl'],
      skillName: data['skillName'],
      experienceDescription: data['experienceDescription'],
      evidenceUrls: data['evidenceUrls'] != null
          ? List<String>.from(data['evidenceUrls'])
          : null,
      portfolioUrl: data['portfolioUrl'],
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => VerificationStatus.pending,
      ),
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'],
      rejectionReason: data['rejectionReason'],
    );
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
