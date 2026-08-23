import 'package:flutter/material.dart';
import '../models/skill_exchange_models.dart';
import '../repositories/skill_exchange_repository.dart';

class SkillExchangeProvider extends ChangeNotifier {
  final SkillExchangeRepository _repository;

  SkillExchangeProvider({SkillExchangeRepository? repository})
      : _repository = repository ?? SkillExchangeRepository() {
    loadInitialData();
  }

  bool _isLoading = false;
  String? _errorMessage;
  List<ExchangeCourse> _availableCourses = [];
  List<ExchangeCourse> _myCourses = [];
  List<SkillExchangeRequest> _requests = [];
  List<AIMatchSuggestion> _aiSuggestions = [];
  ExchangeCourse? _selectedOfferedCourseForAI;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ExchangeUser get currentUser => _repository.currentUser;
  List<ExchangeCourse> get availableCourses => _availableCourses;
  List<ExchangeCourse> get myCourses => _myCourses;
  List<SkillExchangeRequest> get requests => _requests;
  List<AIMatchSuggestion> get aiSuggestions => _aiSuggestions;
  ExchangeCourse? get selectedOfferedCourseForAI => _selectedOfferedCourseForAI;

  // Filtered requests
  List<SkillExchangeRequest> get incomingRequests => _requests
      .where((r) => r.targetOwnerId == currentUser.id)
      .toList();

  List<SkillExchangeRequest> get outgoingRequests => _requests
      .where((r) => r.requesterId == currentUser.id)
      .toList();

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final courses = await _repository.getAvailableCourses();
      final myCoursesList = await _repository.getMyCourses();
      final reqList = await _repository.getRequests();

      _availableCourses = courses;
      _myCourses = myCoursesList;
      _requests = reqList;

      if (_myCourses.isNotEmpty) {
        _selectedOfferedCourseForAI = _myCourses.first;
        await loadAISuggestions(_selectedOfferedCourseForAI!);
      }
    } catch (e) {
      _errorMessage = 'Failed to load skill exchange data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchRole(UserRole role) async {
    _repository.switchUserRole(role);
    await loadInitialData();
  }

  Future<void> selectCourseForAI(ExchangeCourse course) async {
    _selectedOfferedCourseForAI = course;
    await loadAISuggestions(course);
  }

  Future<void> loadAISuggestions(ExchangeCourse course) async {
    try {
      final suggestions = await _repository.getAISuggestions(course);
      _aiSuggestions = suggestions;
      notifyListeners();
    } catch (e) {
      debugPrint('Error generating suggestions: $e');
    }
  }

  Future<bool> sendExchangeRequest({
    required ExchangeCourse offeredCourse,
    required ExchangeCourse targetCourse,
    required String message,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newReq = await _repository.createExchangeRequest(
        offeredCourse: offeredCourse,
        targetCourse: targetCourse,
        message: message,
      );
      _requests = [newReq, ..._requests];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not send request: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> approveRequest(String requestId) async {
    await _repository.updateRequestStatus(requestId, ExchangeStatus.approved);
    _requests = await _repository.getRequests();
    notifyListeners();
  }

  Future<void> rejectRequest(String requestId) async {
    await _repository.updateRequestStatus(requestId, ExchangeStatus.rejected);
    _requests = await _repository.getRequests();
    notifyListeners();
  }

  Future<void> cancelRequest(String requestId) async {
    await _repository.updateRequestStatus(requestId, ExchangeStatus.cancelled);
    _requests = await _repository.getRequests();
    notifyListeners();
  }
}
