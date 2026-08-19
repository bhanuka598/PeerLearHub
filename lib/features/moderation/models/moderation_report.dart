import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  spam,
  harassment,
  unsafeLocation,
  inappropriateContent,
  fraudScam,
  other;

  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.unsafeLocation:
        return 'Unsafe Location';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.fraudScam:
        return 'Fraud/Scam';
      case ReportReason.other:
        return 'Other';
    }
  }
}

enum ReportSeverity {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case ReportSeverity.low:
        return 'Low';
      case ReportSeverity.medium:
        return 'Medium';
      case ReportSeverity.high:
        return 'High';
    }
  }
}

enum ReportStatus {
  open,
  underReview,
  resolved,
  dismissed;

  String get displayName {
    switch (this) {
      case ReportStatus.open:
        return 'Open';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }
}

class ModerationReport {
  final String id;
  final String reportedBy;
  final String? reporterName;
  final String reportedUserId;
  final String? reportedUserName;
  final String? relatedContentId;
  final ReportReason reason;
  final String description;
  final ReportSeverity severity;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? resolutionNote;

  ModerationReport({
    required this.id,
    required this.reportedBy,
    this.reporterName,
    required this.reportedUserId,
    this.reportedUserName,
    this.relatedContentId,
    required this.reason,
    required this.description,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.resolutionNote,
  });

  // Convert from Firestore document
  factory ModerationReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModerationReport(
      id: doc.id,
      reportedBy: data['reportedBy'] ?? '',
      reporterName: data['reporterName'],
      reportedUserId: data['reportedUserId'] ?? '',
      reportedUserName: data['reportedUserName'],
      relatedContentId: data['relatedContentId'],
      reason: ReportReason.values.firstWhere(
        (e) => e.name == data['reason'],
        orElse: () => ReportReason.other,
      ),
      description: data['description'] ?? '',
      severity: ReportSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => ReportSeverity.low,
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReportStatus.open,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'],
      resolutionNote: data['resolutionNote'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'relatedContentId': relatedContentId,
      'reason': reason.name,
      'description': description,
      'severity': severity.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'resolutionNote': resolutionNote,
    };
  }

  // Create a copy with updated fields
  ModerationReport copyWith({
    String? id,
    String? reportedBy,
    String? reporterName,
    String? reportedUserId,
    String? reportedUserName,
    String? relatedContentId,
    ReportReason? reason,
    String? description,
    ReportSeverity? severity,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? resolutionNote,
  }) {
    return ModerationReport(
      id: id ?? this.id,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterName: reporterName ?? this.reporterName,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportedUserName: reportedUserName ?? this.reportedUserName,
      relatedContentId: relatedContentId ?? this.relatedContentId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }
}
