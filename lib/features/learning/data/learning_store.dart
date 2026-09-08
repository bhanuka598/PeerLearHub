import 'package:flutter/foundation.dart';

import '../models/learning_course.dart';

class LearningStore extends ValueNotifier<List<LearningCourse>> {
  LearningStore._() : super(_courses);
  static final instance = LearningStore._();

  void enroll(LearningCourse course) => _replace(course.copyWith(enrolled: true));
  void updateProgress(LearningCourse course, int progress) =>
      _replace(course.copyWith(enrolled: true, progress: progress.clamp(0, 100).toInt()));

  void _replace(LearningCourse updated) {
    value = [for (final course in value) if (course.id == updated.id) updated else course];
  }
}

const _modules = [
  CourseModule(id: 'm1', title: 'Introduction to Flutter', lessonCount: 4, duration: '32 min'),
  CourseModule(id: 'm2', title: 'Stateless Widgets', lessonCount: 5, duration: '48 min'),
  CourseModule(id: 'm3', title: 'Stateful Widgets', lessonCount: 6, duration: '56 min'),
  CourseModule(id: 'm4', title: 'Layouts and Navigation', lessonCount: 7, duration: '1 hr 12 min'),
  CourseModule(id: 'm5', title: 'Working with APIs', lessonCount: 5, duration: '45 min'),
];

const _courses = [
  LearningCourse(id: 'flutter', title: 'Flutter & Dart Masterclass', description: 'Build polished, responsive mobile apps with Flutter and Dart from first widget to production-ready interface.', category: 'Mobile', level: 'Intermediate', instructor: 'Angela Yu', duration: '18h 30m', rating: 4.8, colorValue: 0xFF00695C, modules: _modules, enrolled: true, progress: 75),
  LearningCourse(id: 'mern', title: 'MERN Stack Essentials', description: 'Learn to build full-stack web applications using MongoDB, Express, React, and Node.js.', category: 'Web', level: 'Beginner', instructor: 'Colt Steele', duration: '14h 10m', rating: 4.7, colorValue: 0xFF1565C0, modules: _modules, enrolled: true, progress: 12),
  LearningCourse(id: 'ux', title: 'UI/UX Design Foundations', description: 'Create user-centred digital experiences with practical design systems and prototypes.', category: 'UI/UX', level: 'Beginner', instructor: 'Maya Patel', duration: '9h 20m', rating: 4.9, colorValue: 0xFF7B1FA2, modules: _modules),
  LearningCourse(id: 'ai', title: 'Applied AI for Developers', description: 'Explore practical AI concepts, prompts, and integrations for modern applications.', category: 'AI', level: 'Advanced', instructor: 'James Wilson', duration: '11h 45m', rating: 4.6, colorValue: 0xFFEF6C00, modules: _modules),
];
