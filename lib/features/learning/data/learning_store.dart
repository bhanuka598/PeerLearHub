import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/learning_course.dart';

class LearningStore extends ValueNotifier<List<LearningCourse>> {
  LearningStore._() : super([]);
  static final instance = LearningStore._();
  int _points = 0;
  final _completedQuizCourses = <String>{};

  int get points => _points;

  bool canSubmitAssignment(LearningCourse course) =>
      course.progress >= 100 && _completedQuizCourses.contains(course.id);

  Future<void> loadCourses() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('courses').get();
      if (snapshot.docs.isNotEmpty) {
        final loaded = snapshot.docs.map((doc) {
          final data = doc.data();
          final modulesData = (data['modules'] as List<dynamic>?) ?? [];
          final modules = modulesData.map((m) => CourseModule(
            id: m['id']?.toString() ?? '',
            title: m['title']?.toString() ?? '',
            lessonCount: (m['lessonCount'] as num?)?.toInt() ?? 1,
            duration: m['duration']?.toString() ?? '30 min',
          )).toList();

          final videosData = (data['videoLessons'] as List<dynamic>?) ?? [];
          final videoLessons = videosData.map((v) => MiniVideoLesson(
            id: v['id']?.toString() ?? '',
            title: v['title']?.toString() ?? '',
            description: v['description']?.toString() ?? '',
            duration: v['duration']?.toString() ?? '5 min',
          )).toList();

          return LearningCourse(
            id: doc.id,
            title: data['title']?.toString() ?? '',
            description: data['description']?.toString() ?? '',
            category: data['category']?.toString() ?? 'General',
            level: data['level']?.toString() ?? 'Beginner',
            instructor: data['instructor']?.toString() ?? 'Instructor',
            duration: data['duration']?.toString() ?? '10h',
            rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
            isInstructorVerified: data['isInstructorVerified'] == true,
            colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF00695C,
            modules: modules,
            videoLessons: videoLessons,
          );
        }).toList();
        value = loaded;
      }
    } catch (e) {
      debugPrint('Could not load courses: $e');
    }
  }

  Future<void> loadEnrollments() async {
    final user = FirebaseAuth.instance.currentUser;
    await loadCourses();
    if (user == null) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .get();
      final saved = {
        for (final document in snapshot.docs) document.id: document.data(),
      };
      value = [
        for (final course in value)
          course.copyWith(
            enrolled: course.enrolled || saved.containsKey(course.id),
            progress: (saved[course.id]?['progress'] as num?)?.toInt() ?? course.progress,
          ),
      ];
      for (final entry in saved.entries) {
        if (entry.value['quizCompleted'] == true) {
          _completedQuizCourses.add(entry.key);
        }
      }
    } on FirebaseException catch (error) {
      debugPrint('Could not load enrollments: ${error.code}');
    }
  }

  Future<void> enroll(LearningCourse course) async {
    final updated = course.copyWith(enrolled: true);
    _replace(updated);
    await _saveEnrollment(updated);
  }

  Future<void> updateProgress(LearningCourse course, int progress) async {
    final updated = course.copyWith(
      enrolled: true,
      progress: progress.clamp(0, 100).toInt(),
    );
    _replace(updated);
    await _saveEnrollment(updated);
  }

  Future<int> saveQuizPoints({
    required LearningCourse course,
    required String moduleId,
    required int points,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    _points += points;
    notifyListeners();
    if (user == null) {
      return _points;
    }

    try {
      final userReference = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await userReference.set({
        'learningPoints': FieldValue.increment(points),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await userReference.collection('enrollments').doc(course.id).set({
        'courseId': course.id,
        'lastQuizModuleId': moduleId,
        'lastQuizPoints': points,
        'quizCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _completedQuizCourses.add(course.id);
    } on FirebaseException catch (error) {
      debugPrint('Could not save quiz points: ${error.code}');
    }
    return _points;
  }

  Future<void> _saveEnrollment(LearningCourse course) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .doc(course.id)
          .set({
            'courseId': course.id,
            'progress': course.progress,
            'enrolledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      debugPrint('Could not save enrollment: ${error.code}');
    }
  }

  void _replace(LearningCourse updated) {
    value = [
      for (final course in value)
        if (course.id == updated.id) updated else course,
    ];
  }
}
