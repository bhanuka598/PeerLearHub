import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/lesson.dart';

/// Tracks teacher lessons a student added to My Learning.
class StudentLessonStore extends ChangeNotifier {
  StudentLessonStore._();

  static final StudentLessonStore instance = StudentLessonStore._();

  final Set<String> _enrolledIds = {};

  bool isEnrolled(String lessonId) => _enrolledIds.contains(lessonId);

  List<Lesson> enrolledFrom(List<Lesson> published) {
    return published.where((lesson) => _enrolledIds.contains(lesson.id)).toList();
  }

  Future<void> load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final stored = doc.data()?['enrolledLessonIds'];
      if (stored is List) {
        _enrolledIds
          ..clear()
          ..addAll(stored.map((id) => id.toString()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Enrolled lessons read skipped: $e');
    }
  }

  Future<void> enroll(String lessonId) async {
    if (_enrolledIds.contains(lessonId)) return;
    _enrolledIds.add(lessonId);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'enrolledLessonIds': _enrolledIds.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Enrolled lessons write skipped: $e');
    }
  }
}
