import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/learning_course.dart';

class LearningStore extends ValueNotifier<List<LearningCourse>> {
  LearningStore._() : super(_courses);
  static final instance = LearningStore._();
  int _points = 0;
  final _completedQuizCourses = <String>{};

  int get points => _points;

  bool canSubmitAssignment(LearningCourse course) =>
      course.progress >= 100 && _completedQuizCourses.contains(course.id);

  Future<void> loadEnrollments() async {
    final user = FirebaseAuth.instance.currentUser;
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
            enrolled: saved.containsKey(course.id),
            progress: saved[course.id]?['progress'] as int? ?? 0,
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

const _modules = [
  CourseModule(
    id: 'm1',
    title: 'Introduction to Flutter',
    lessonCount: 4,
    duration: '32 min',
  ),
  CourseModule(
    id: 'm2',
    title: 'Stateless Widgets',
    lessonCount: 5,
    duration: '48 min',
  ),
  CourseModule(
    id: 'm3',
    title: 'Stateful Widgets',
    lessonCount: 6,
    duration: '56 min',
  ),
  CourseModule(
    id: 'm4',
    title: 'Layouts and Navigation',
    lessonCount: 7,
    duration: '1 hr 12 min',
  ),
  CourseModule(
    id: 'm5',
    title: 'Working with APIs',
    lessonCount: 5,
    duration: '45 min',
  ),
];

const _courses = [
  LearningCourse(
    id: 'flutter',
    title: 'Flutter & Dart Masterclass',
    description:
        'Build polished, responsive mobile apps with Flutter and Dart from first widget to production-ready interface.',
    category: 'Mobile',
    level: 'Intermediate',
    instructor: 'Angela Yu',
    duration: '18h 30m',
    rating: 4.8,
    colorValue: 0xFF00695C,
    modules: _modules,
  ),
  LearningCourse(
    id: 'mern',
    title: 'MERN Stack Essentials',
    description:
        'Learn to build full-stack web applications using MongoDB, Express, React, and Node.js.',
    category: 'Web',
    level: 'Beginner',
    instructor: 'Colt Steele',
    duration: '14h 10m',
    rating: 4.7,
    colorValue: 0xFF1565C0,
    modules: _modules,
  ),
  LearningCourse(
    id: 'ux',
    title: 'UI/UX Design Foundations',
    description:
        'Create user-centred digital experiences with practical design systems and prototypes.',
    category: 'UI/UX',
    level: 'Beginner',
    instructor: 'Maya Patel',
    duration: '9h 20m',
    rating: 4.9,
    colorValue: 0xFF7B1FA2,
    modules: _modules,
  ),
  LearningCourse(
    id: 'ai',
    title: 'Applied AI for Developers',
    description:
        'Explore practical AI concepts, prompts, and integrations for modern applications.',
    category: 'AI',
    level: 'Advanced',
    instructor: 'James Wilson',
    duration: '11h 45m',
    rating: 4.6,
    colorValue: 0xFFEF6C00,
    modules: _modules,
  ),
];
