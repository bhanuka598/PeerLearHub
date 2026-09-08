import 'dart:async';
import '../data/mock_skill_exchange_data.dart';
import '../models/skill_exchange_models.dart';
import '../services/ai_suggestion_service.dart';

class SkillExchangeRepository {
  final List<ExchangeCourse> _courses = MockSkillExchangeData.getSampleCourses();
  List<SkillExchangeRequest> _requests = MockSkillExchangeData.getInitialRequests();

  // Active current user session
  ExchangeUser _currentUser = MockSkillExchangeData.currentUserLecturer;

  ExchangeUser get currentUser => _currentUser;

  void switchUserRole(UserRole role) {
    if (role == UserRole.student) {
      _currentUser = MockSkillExchangeData.currentUserStudent;
    } else {
      _currentUser = MockSkillExchangeData.currentUserLecturer;
    }
  }

  Future<List<ExchangeCourse>> getAvailableCourses() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return List.unmodifiable(_courses);
  }

  Future<List<ExchangeCourse>> getMyCourses() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _courses.where((c) => c.ownerId == _currentUser.id).toList();
  }

  Future<List<SkillExchangeRequest>> getRequests() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_requests);
  }

  /// Implements business rules for creating a direct or student-initiated exchange
  Future<SkillExchangeRequest> createExchangeRequest({
    required ExchangeCourse offeredCourse,
    required ExchangeCourse targetCourse,
    required String message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Rule 1 & Rule 2:
    // If the requester is a Lecturer/Tutor requesting from another Lecturer/Tutor:
    // Direct Tutor-to-Tutor -> ExchangeStatus.pendingPeerApproval
    // If the requester is a Student -> ExchangeStatus.pendingTutorApproval
    final ExchangeStatus initialStatus;
    if (_currentUser.isLecturerOrTutor && targetCourse.ownerRole != UserRole.student) {
      initialStatus = ExchangeStatus.pendingPeerApproval;
    } else {
      initialStatus = ExchangeStatus.pendingTutorApproval;
    }

    final double matchScore = AISuggestionService.generateMatchSuggestions(
      myOfferedCourse: offeredCourse,
      availableCourses: [targetCourse],
    ).firstOrNull?.matchPercentage ?? 80.0;

    final newRequest = SkillExchangeRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      requesterId: _currentUser.id,
      requesterName: _currentUser.name,
      requesterAvatar: _currentUser.avatarUrl,
      requesterRole: _currentUser.role,
      offeredCourseId: offeredCourse.id,
      offeredCourseTitle: offeredCourse.title,
      targetOwnerId: targetCourse.ownerId,
      targetOwnerName: targetCourse.ownerName,
      targetOwnerAvatar: targetCourse.ownerAvatar,
      requestedCourseId: targetCourse.id,
      requestedCourseTitle: targetCourse.title,
      status: initialStatus,
      message: message,
      createdAt: DateTime.now(),
      matchScore: matchScore,
    );

    _requests = [newRequest, ..._requests];
    return newRequest;
  }

  Future<void> updateRequestStatus(String requestId, ExchangeStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _requests = _requests.map((req) {
      if (req.id == requestId) {
        return req.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }
      return req;
    }).toList();
  }

  Future<List<AIMatchSuggestion>> getAISuggestions(ExchangeCourse offeredCourse) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final allCourses = await getAvailableCourses();
    return AISuggestionService.generateMatchSuggestions(
      myOfferedCourse: offeredCourse,
      availableCourses: allCourses,
    );
  }
}
