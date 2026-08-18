import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../data/demo/demo_dashboard_stats.dart';
import '../data/demo/demo_lessons.dart';
import '../models/lesson.dart';
import '../models/provider_dashboard_stats.dart';

/// Contract for lesson CRUD operations.
/// Implement [DemoLessonService] for Sprint 1; replace with Firebase later.
abstract class LessonService extends ChangeNotifier {
  Future<List<Lesson>> getLessonsByProvider(String providerId);
  Future<Lesson?> getLessonById(String id);
  Future<Lesson> createLesson(Lesson lesson);
  Future<Lesson> updateLesson(Lesson lesson);
  Future<void> deleteLesson(String id);
  Future<ProviderDashboardStats> getDashboardStats(String providerId);
  List<Lesson> getRecentLessons(String providerId, {int limit = 3});
}

/// In-memory demo implementation for Sprint 1.
class DemoLessonService extends LessonService {
  DemoLessonService._() {
    _lessons.addAll(createDemoLessons());
  }

  static final DemoLessonService instance = DemoLessonService._();

  final List<Lesson> _lessons = [];
  int _idCounter = 6;

  String _generateId() {
    final id = 'lesson_$_idCounter';
    _idCounter++;
    return id;
  }

  @override
  Future<List<Lesson>> getLessonsByProvider(String providerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _lessons
        .where((lesson) => lesson.providerId == providerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Lesson?> getLessonById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      return _lessons.firstWhere((lesson) => lesson.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Lesson> createLesson(Lesson lesson) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now();
    final newLesson = lesson.copyWith(
      id: _generateId(),
      createdAt: now,
      updatedAt: now,
    );
    _lessons.add(newLesson);
    notifyListeners();
    return newLesson;
  }

  @override
  Future<Lesson> updateLesson(Lesson lesson) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _lessons.indexWhere((item) => item.id == lesson.id);
    if (index == -1) {
      throw StateError('Lesson not found: ${lesson.id}');
    }
    final updated = lesson.copyWith(updatedAt: DateTime.now());
    _lessons[index] = updated;
    notifyListeners();
    return updated;
  }

  @override
  Future<void> deleteLesson(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _lessons.removeWhere((lesson) => lesson.id == id);
    notifyListeners();
  }

  @override
  Future<ProviderDashboardStats> getDashboardStats(String providerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (providerId == AppConstants.demoProviderId) {
      return demoDashboardStats;
    }
    final providerLessons =
        _lessons.where((l) => l.providerId == providerId).toList();
    return ProviderDashboardStats(
      totalLessons: providerLessons.length,
      activeLessons:
          providerLessons.where((l) => l.status == LessonStatus.active).length,
      pendingRequests: demoDashboardStats.pendingRequests,
      completedLessons: demoDashboardStats.completedLessons,
    );
  }

  @override
  List<Lesson> getRecentLessons(String providerId, {int limit = 3}) {
    final sorted = _lessons
        .where((lesson) => lesson.providerId == providerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }
}
