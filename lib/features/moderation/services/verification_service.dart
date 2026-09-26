import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/verification_request.dart';
import 'activity_log_service.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/services/notification_service.dart';

class VerificationService {
  // Flag to use mock data (set to true when Firebase is not configured)
  static bool useMockData = false;
  
  final String _collection = 'verificationRequests';
  final ActivityLogService _activityLogService = ActivityLogService();

  // Get all verification requests
  Stream<List<VerificationRequest>> getVerificationRequests() {
    if (useMockData) {
      return Stream.value(_getMockVerificationRequests());
    }
    
    return FirebaseFirestore.instance
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
          final requests = _parseRequests(snapshot.docs);
          requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return requests;
        });
  }

  // Get verification requests by status
  Stream<List<VerificationRequest>> getVerificationRequestsByStatus(
      VerificationStatus status) {
    if (useMockData) {
      return Stream.value(
        _getMockVerificationRequests()
            .where((req) => req.status == status)
            .toList(),
      );
    }
    
    return FirebaseFirestore.instance
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .snapshots()
        .map((snapshot) {
          final requests = _parseRequests(snapshot.docs);
          // Sort in Dart instead of Firestore to avoid index requirement
          requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return requests;
        });
  }

  // Get verification requests by user ID
  Stream<List<VerificationRequest>> getVerificationRequestsByUserId(String userId) {
    if (useMockData) {
      return Stream.value(
        _getMockVerificationRequests()
            .where((req) => req.userId == userId)
            .toList(),
      );
    }
    
    return FirebaseFirestore.instance
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final requests = _parseRequests(snapshot.docs);
          requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return requests;
        });
  }

  // Get verification request by ID
  Future<VerificationRequest?> getVerificationRequestById(String id) async {
    if (useMockData) {
      try {
        return _getMockVerificationRequests().firstWhere((req) => req.id == id);
      } catch (e) {
        return null;
      }
    }
    
    final doc = await FirebaseFirestore.instance.collection(_collection).doc(id).get();
    if (doc.exists) {
      return _tryParseRequest(doc);
    }
    return null;
  }

  // Approve verification request
  Future<void> approveVerificationRequest(
    String requestId,
    String moderatorId,
  ) async {
    if (useMockData) {
      // Simulate async operation
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    
    // Get the request details before updating
    final request = await getVerificationRequestById(requestId);
    
    await FirebaseFirestore.instance.collection(_collection).doc(requestId).update({
      'status': VerificationStatus.approved.name,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': moderatorId,
    });
    
    // Log the activity
    if (request != null) {
      Map<String, dynamic> userUpdate = {
        'isVerified': true,
      };

      if (request.verificationType == VerificationType.skill && request.skillName != null) {
        userUpdate['verifiedSkills'] = FieldValue.arrayUnion([request.skillName]);
        
        // Also update the teacher profile collection
        await FirebaseFirestore.instance.collection('teacherProfiles').doc(request.userId).set({
          'verifiedSkills': FieldValue.arrayUnion([request.skillName]),
          'isVerified': true,
        }, SetOptions(merge: true));
      } else if (request.verificationType == VerificationType.identity) {
        userUpdate['isIdentityVerified'] = true;
      }

      await FirebaseFirestore.instance.collection('users').doc(request.userId).set(
        userUpdate, 
        SetOptions(merge: true)
      );

      final now = DateTime.now();
      await NotificationService.instance.createIfAbsent(
        AppNotification(
          id: AppNotification.buildId(
            sessionId: 'verif_${requestId}',
            type: NotificationType.verificationApproved,
            role: NotificationRecipientRole.learner,
            scheduledAt: now,
          ),
          recipientId: request.userId,
          recipientRole: NotificationRecipientRole.learner,
          type: NotificationType.verificationApproved,
          title: 'Verification Approved',
          body: 'Your verification request for ${request.verificationType.displayName} has been approved. You now have a verified badge!',
          sessionId: 'verif_${requestId}',
          createdAt: now,
        )
      );

      await _activityLogService.logAction(
        moderatorId: moderatorId,
        moderatorName: 'Moderator', // TODO: Get from user profile
        actionType: 'verification_approved',
        targetId: requestId,
        targetUserId: request.userId,
        description: 'Approved ${request.verificationType.displayName} verification for ${request.userName}',
        metadata: {
          'verificationType': request.verificationType.name,
          'skillName': request.skillName,
        },
      );
    }
  }

  // Reject verification request
  Future<void> rejectVerificationRequest(
    String requestId,
    String moderatorId,
    String rejectionReason,
  ) async {
    if (useMockData) {
      // Simulate async operation
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    
    // Get the request details before updating
    final request = await getVerificationRequestById(requestId);
    
    await FirebaseFirestore.instance.collection(_collection).doc(requestId).update({
      'status': VerificationStatus.rejected.name,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': moderatorId,
      'rejectionReason': rejectionReason,
    });
    
    // Log the activity
    if (request != null) {
      final now = DateTime.now();
      await NotificationService.instance.createIfAbsent(
        AppNotification(
          id: AppNotification.buildId(
            sessionId: 'verif_${requestId}',
            type: NotificationType.verificationRejected,
            role: NotificationRecipientRole.learner,
            scheduledAt: now,
          ),
          recipientId: request.userId,
          recipientRole: NotificationRecipientRole.learner,
          type: NotificationType.verificationRejected,
          title: 'Verification Rejected',
          body: 'Your verification request for ${request.verificationType.displayName} was rejected. Reason: $rejectionReason',
          sessionId: 'verif_${requestId}',
          createdAt: now,
        )
      );

      await _activityLogService.logAction(
        moderatorId: moderatorId,
        moderatorName: 'Moderator', // TODO: Get from user profile
        actionType: 'verification_rejected',
        targetId: requestId,
        targetUserId: request.userId,
        description: 'Rejected ${request.verificationType.displayName} verification for ${request.userName}',
        metadata: {
          'verificationType': request.verificationType.name,
          'rejectionReason': rejectionReason,
        },
      );
    }
  }

  // Submit a new verification request (User action)
  Future<void> submitVerificationRequest({
    required String userId,
    required String userName,
    required VerificationType verificationType,
    String? userProfileImage,
    String? fullName,
    String? identityDocumentUrl,
    String? skillName,
    String? experienceDescription,
    List<String>? evidenceUrls,
    String? portfolioUrl,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    
    final docRef = FirebaseFirestore.instance.collection(_collection).doc();
    final request = VerificationRequest(
      id: docRef.id,
      userId: userId,
      userName: userName,
      userProfileImage: userProfileImage,
      verificationType: verificationType,
      fullName: fullName,
      identityDocumentUrl: identityDocumentUrl,
      skillName: skillName,
      experienceDescription: experienceDescription,
      evidenceUrls: evidenceUrls,
      portfolioUrl: portfolioUrl,
      status: VerificationStatus.pending,
      submittedAt: DateTime.now(),
    );
    
    await docRef.set(request.toFirestore());
  }

  // Get statistics
  Future<Map<String, int>> getVerificationStatistics() async {
    if (useMockData) {
      final requests = _getMockVerificationRequests();
      return {
        'pending': requests.where((r) => r.status == VerificationStatus.pending).length,
        'approved': requests.where((r) => r.status == VerificationStatus.approved).length,
        'rejected': requests.where((r) => r.status == VerificationStatus.rejected).length,
        'total': requests.length,
      };
    }
    
    final snapshot = await FirebaseFirestore.instance.collection(_collection).get();
    var pending = 0;
    var approved = 0;
    var rejected = 0;

    for (final doc in snapshot.docs) {
      switch (_statusName(doc.data()['status'])) {
        case 'pending':
          pending++;
          break;
        case 'approved':
          approved++;
          break;
        case 'rejected':
          rejected++;
          break;
      }
    }

    return {
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
      'total': snapshot.docs.length,
    };
  }

  List<VerificationRequest> _parseRequests(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map(_tryParseRequest).whereType<VerificationRequest>().toList();
  }

  VerificationRequest? _tryParseRequest(DocumentSnapshot doc) {
    try {
      return VerificationRequest.fromFirestore(doc);
    } catch (e) {
      debugPrint('Skipping malformed verification request ${doc.id}: $e');
      return null;
    }
  }

  String _statusName(dynamic value) {
    if (value is String) return value;
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    return value?.toString() ?? '';
  }

  // Mock data for development
  List<VerificationRequest> _getMockVerificationRequests() {
    final now = DateTime.now();
    return [
      VerificationRequest(
        id: '1',
        userId: 'user_001',
        userName: 'Sarah Johnson',
        userProfileImage: null,
        verificationType: VerificationType.skill,
        skillName: 'Flutter Development',
        experienceDescription: '5 years of experience building mobile applications with Flutter. Developed 20+ production apps.',
        evidenceUrls: [
          'https://example.com/portfolio/app1.png',
          'https://example.com/portfolio/app2.png',
        ],
        portfolioUrl: 'https://github.com/sarahjohnson',
        status: VerificationStatus.pending,
        submittedAt: now.subtract(const Duration(hours: 2)),
      ),
      VerificationRequest(
        id: '2',
        userId: 'user_002',
        userName: 'Michael Chen',
        userProfileImage: null,
        verificationType: VerificationType.identity,
        fullName: 'Michael Chen',
        identityDocumentUrl: 'https://example.com/docs/id_sample.jpg',
        status: VerificationStatus.pending,
        submittedAt: now.subtract(const Duration(days: 1)),
      ),
      VerificationRequest(
        id: '3',
        userId: 'user_003',
        userName: 'Emily Rodriguez',
        userProfileImage: null,
        verificationType: VerificationType.skill,
        skillName: 'Graphic Design',
        experienceDescription: 'Professional graphic designer with 8 years of experience in branding and UI/UX design.',
        evidenceUrls: [
          'https://example.com/portfolio/design1.jpg',
        ],
        portfolioUrl: 'https://behance.net/emilyrodriguez',
        status: VerificationStatus.approved,
        submittedAt: now.subtract(const Duration(days: 3)),
        reviewedAt: now.subtract(const Duration(days: 2)),
        reviewedBy: 'mod_001',
      ),
      VerificationRequest(
        id: '4',
        userId: 'user_004',
        userName: 'David Kim',
        userProfileImage: null,
        verificationType: VerificationType.skill,
        skillName: 'Web Development',
        experienceDescription: 'Junior developer learning web technologies.',
        evidenceUrls: [],
        portfolioUrl: null,
        status: VerificationStatus.rejected,
        submittedAt: now.subtract(const Duration(days: 5)),
        reviewedAt: now.subtract(const Duration(days: 4)),
        reviewedBy: 'mod_001',
        rejectionReason: 'Insufficient evidence of experience. Please provide portfolio or certificates.',
      ),
      VerificationRequest(
        id: '5',
        userId: 'user_005',
        userName: 'Lisa Anderson',
        userProfileImage: null,
        verificationType: VerificationType.skill,
        skillName: 'Python Programming',
        experienceDescription: 'Data scientist with expertise in Python, ML, and data analysis.',
        evidenceUrls: [
          'https://example.com/certs/python_cert.pdf',
        ],
        portfolioUrl: 'https://github.com/lisaanderson',
        status: VerificationStatus.pending,
        submittedAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }
}
