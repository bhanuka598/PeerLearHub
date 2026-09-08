import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/moderation_report.dart';

class ModerationService {
  // Flag to use mock data (set to true when Firebase is not configured)
  static bool useMockData = true;
  
  final String _collection = 'reports';

  // Get all reports
  Stream<List<ModerationReport>> getReports() {
    if (useMockData) {
      return Stream.value(_getMockReports());
    }
    
    return FirebaseFirestore.instance
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ModerationReport.fromFirestore(doc))
            .toList());
  }

  // Get reports by status
  Stream<List<ModerationReport>> getReportsByStatus(ReportStatus status) {
    if (useMockData) {
      return Stream.value(
        _getMockReports().where((report) => report.status == status).toList(),
      );
    }
    
    return FirebaseFirestore.instance
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ModerationReport.fromFirestore(doc))
            .toList());
  }

  // Get reports by severity
  Stream<List<ModerationReport>> getReportsBySeverity(ReportSeverity severity) {
    if (useMockData) {
      return Stream.value(
        _getMockReports().where((report) => report.severity == severity).toList(),
      );
    }
    
    return FirebaseFirestore.instance
        .collection(_collection)
        .where('severity', isEqualTo: severity.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ModerationReport.fromFirestore(doc))
            .toList());
  }

  // Get report by ID
  Future<ModerationReport?> getReportById(String id) async {
    if (useMockData) {
      try {
        return _getMockReports().firstWhere((report) => report.id == id);
      } catch (e) {
        return null;
      }
    }
    
    final doc = await FirebaseFirestore.instance.collection(_collection).doc(id).get();
    if (doc.exists) {
      return ModerationReport.fromFirestore(doc);
    }
    return null;
  }

  // Update report status
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status,
    String moderatorId, {
    String? resolutionNote,
  }) async {
    if (useMockData) {
      // Simulate async operation
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    
    final updateData = {
      'status': status.name,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': moderatorId,
    };
    
    if (resolutionNote != null) {
      updateData['resolutionNote'] = resolutionNote;
    }
    
    await FirebaseFirestore.instance.collection(_collection).doc(reportId).update(updateData);
  }

  // Get statistics
  Future<Map<String, int>> getReportStatistics() async {
    if (useMockData) {
      final reports = _getMockReports();
      return {
        'open': reports.where((r) => r.status == ReportStatus.open).length,
        'underReview': reports.where((r) => r.status == ReportStatus.underReview).length,
        'resolved': reports.where((r) => r.status == ReportStatus.resolved).length,
        'dismissed': reports.where((r) => r.status == ReportStatus.dismissed).length,
        'highSeverity': reports.where((r) => r.severity == ReportSeverity.high).length,
        'total': reports.length,
      };
    }
    
    final snapshot = await FirebaseFirestore.instance.collection(_collection).get();
    final reports = snapshot.docs
        .map((doc) => ModerationReport.fromFirestore(doc))
        .toList();
    
    return {
      'open': reports.where((r) => r.status == ReportStatus.open).length,
      'underReview': reports.where((r) => r.status == ReportStatus.underReview).length,
      'resolved': reports.where((r) => r.status == ReportStatus.resolved).length,
      'dismissed': reports.where((r) => r.status == ReportStatus.dismissed).length,
      'highSeverity': reports.where((r) => r.severity == ReportSeverity.high).length,
      'total': reports.length,
    };
  }

  // Mock data for development
  List<ModerationReport> _getMockReports() {
    final now = DateTime.now();
    return [
      ModerationReport(
        id: 'rep_001',
        reportedBy: 'user_101',
        reporterName: 'John Smith',
        reportedUserId: 'user_202',
        reportedUserName: 'Spam Account',
        relatedContentId: 'post_123',
        reason: ReportReason.spam,
        description: 'User is posting promotional content repeatedly in multiple groups.',
        severity: ReportSeverity.high,
        status: ReportStatus.open,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      ModerationReport(
        id: 'rep_002',
        reportedBy: 'user_102',
        reporterName: 'Alice Williams',
        reportedUserId: 'user_203',
        reportedUserName: 'Bob Turner',
        relatedContentId: 'comment_456',
        reason: ReportReason.harassment,
        description: 'User made offensive comments and personal attacks in the discussion thread.',
        severity: ReportSeverity.high,
        status: ReportStatus.underReview,
        createdAt: now.subtract(const Duration(hours: 3)),
        reviewedAt: now.subtract(const Duration(hours: 2)),
        reviewedBy: 'mod_001',
      ),
      ModerationReport(
        id: 'rep_003',
        reportedBy: 'user_103',
        reporterName: 'Maria Garcia',
        reportedUserId: 'user_204',
        reportedUserName: 'Tom Parker',
        relatedContentId: 'listing_789',
        reason: ReportReason.unsafeLocation,
        description: 'Meeting location seems suspicious and in an isolated area.',
        severity: ReportSeverity.medium,
        status: ReportStatus.open,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      ModerationReport(
        id: 'rep_004',
        reportedBy: 'user_104',
        reporterName: 'James Brown',
        reportedUserId: 'user_205',
        reportedUserName: 'Scammer Account',
        relatedContentId: 'msg_321',
        reason: ReportReason.fraudScam,
        description: 'User requested payment upfront and disappeared without delivering the promised service.',
        severity: ReportSeverity.high,
        status: ReportStatus.open,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ModerationReport(
        id: 'rep_005',
        reportedBy: 'user_105',
        reporterName: 'Emma Davis',
        reportedUserId: 'user_206',
        reportedUserName: 'Content Poster',
        relatedContentId: 'post_654',
        reason: ReportReason.inappropriateContent,
        description: 'Post contains content that is not appropriate for the platform.',
        severity: ReportSeverity.medium,
        status: ReportStatus.resolved,
        createdAt: now.subtract(const Duration(days: 2)),
        reviewedAt: now.subtract(const Duration(days: 1)),
        reviewedBy: 'mod_001',
        resolutionNote: 'Content removed and user warned.',
      ),
      ModerationReport(
        id: 'rep_006',
        reportedBy: 'user_106',
        reporterName: 'Chris Wilson',
        reportedUserId: 'user_207',
        reportedUserName: 'Normal User',
        relatedContentId: 'comment_987',
        reason: ReportReason.other,
        description: 'User disagreed with me in a discussion.',
        severity: ReportSeverity.low,
        status: ReportStatus.dismissed,
        createdAt: now.subtract(const Duration(days: 3)),
        reviewedAt: now.subtract(const Duration(days: 2)),
        reviewedBy: 'mod_002',
        resolutionNote: 'No policy violation found. Legitimate disagreement.',
      ),
    ];
  }
}
