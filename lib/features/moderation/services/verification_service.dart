import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/verification_request.dart';

class VerificationService {
  // Flag to use mock data (set to true when Firebase is not configured)
  static bool useMockData = true;
  
  final String _collection = 'verificationRequests';

  // Get all verification requests
  Stream<List<VerificationRequest>> getVerificationRequests() {
    if (useMockData) {
      return Stream.value(_getMockVerificationRequests());
    }
    
    return FirebaseFirestore.instance
        .collection(_collection)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VerificationRequest.fromFirestore(doc))
            .toList());
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
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VerificationRequest.fromFirestore(doc))
            .toList());
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
      return VerificationRequest.fromFirestore(doc);
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
    
    await FirebaseFirestore.instance.collection(_collection).doc(requestId).update({
      'status': VerificationStatus.approved.name,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': moderatorId,
    });
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
    
    await FirebaseFirestore.instance.collection(_collection).doc(requestId).update({
      'status': VerificationStatus.rejected.name,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': moderatorId,
      'rejectionReason': rejectionReason,
    });
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
    final requests = snapshot.docs
        .map((doc) => VerificationRequest.fromFirestore(doc))
        .toList();
    
    return {
      'pending': requests.where((r) => r.status == VerificationStatus.pending).length,
      'approved': requests.where((r) => r.status == VerificationStatus.approved).length,
      'rejected': requests.where((r) => r.status == VerificationStatus.rejected).length,
      'total': requests.length,
    };
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
