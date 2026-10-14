/// Firestore service for teacher-authored assignments nested under lesson modules.
///
/// Firestore paths:
/// - Assignment: `lessons/{lessonId}/modules/{moduleId}/assignment/main`
/// - Submissions: `users/{learnerId}/assignmentSubmissions/{assignmentId}`
///
/// Security rules (add to firestore.rules):
/// ```
/// match /lessons/{lessonId}/modules/{moduleId}/assignment/{assignmentDoc} {
///   allow read: if request.auth != null
///     && (resource.data.status == 'published'
///         || get(/databases/$(database)/documents/lessons/$(lessonId)).data.providerId == request.auth.uid
///         || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'moderator');
///   allow create, update: if request.auth != null
///     && get(/databases/$(database)/documents/lessons/$(lessonId)).data.providerId == request.auth.uid;
///   allow update: if request.auth != null
///     && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'moderator'
///     && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'updatedAt']);
/// }
/// match /users/{userId}/assignmentSubmissions/{submissionId} {
///   allow read, create, update: if request.auth != null && request.auth.uid == userId;
///   allow delete: if false;
/// }
/// ```
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/lesson.dart';
import '../../learning/models/quiz_submission.dart';
import '../models/assessment_status.dart';
import '../models/assignment.dart';
import 'firebase_lesson_service.dart';

/// Teacher-side assignment service (distinct from learner [AssignmentService]).
class ProviderAssignmentService {
  ProviderAssignmentService._();

  static final instance = ProviderAssignmentService._();

  static const _assignmentDocId = 'main';

  DocumentReference<Map<String, dynamic>> _assignmentRef(
    String lessonId,
    String moduleId,
  ) {
    return FirebaseFirestore.instance
        .collection('lessons')
        .doc(lessonId)
        .collection('modules')
        .doc(moduleId)
        .collection('assignment')
        .doc(_assignmentDocId);
  }

  CollectionReference<Map<String, dynamic>> _submissionsRef(String learnerId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(learnerId)
        .collection('assignmentSubmissions');
  }

  Future<Lesson> _loadLesson(String lessonId) async {
    final lesson = await FirebaseLessonService.instance.getLessonById(lessonId);
    if (lesson == null) {
      throw StateError('Lesson not found.');
    }
    return lesson;
  }

  void _assertOwner(Lesson lesson) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || lesson.providerId != uid) {
      throw StateError('Only the lesson owner can modify this assignment.');
    }
  }

  void _validateForPublish(Assignment assignment) {
    if (assignment.title.trim().isEmpty) {
      throw ArgumentError('Title is required.');
    }
    if (assignment.description.trim().isEmpty) {
      throw ArgumentError('Description is required.');
    }
    if (assignment.requirements.isEmpty) {
      throw ArgumentError('At least one requirement is required.');
    }
    if (assignment.maxPoints <= 0) {
      throw ArgumentError('Max points must be greater than 0.');
    }
  }

  Future<Assignment?> getAssignmentForModule(
    String lessonId,
    String moduleId,
  ) async {
    final doc = await _assignmentRef(lessonId, moduleId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Assignment.fromMap(doc.data()!);
  }

  Future<List<AssignmentSubmission>> getSubmissionsForLearner(
    String learnerId,
  ) async {
    final snapshot = await _submissionsRef(learnerId).get();
    return snapshot.docs
        .map((doc) => AssignmentSubmission.fromMap(doc.data()))
        .toList();
  }

  Future<void> saveAssignmentDraft(Assignment assignment) async {
    final lesson = await _loadLesson(assignment.lessonId);
    _assertOwner(lesson);

    final payload = assignment
        .copyWith(
          status: AssessmentStatus.draft,
          updatedAt: DateTime.now(),
        )
        .toMap();

    await _assignmentRef(assignment.lessonId, assignment.moduleId).set(
      payload,
      SetOptions(merge: true),
    );
  }

  Future<void> publishAssignment(
    String lessonId,
    String moduleId,
    String assignmentId,
  ) async {
    final lesson = await _loadLesson(lessonId);
    _assertOwner(lesson);

    final doc = await _assignmentRef(lessonId, moduleId).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('Assignment not found.');
    }
    final assignment = Assignment.fromMap(doc.data()!);
    if (assignment.id != assignmentId) {
      throw StateError('Assignment id mismatch.');
    }

    _validateForPublish(assignment);
    await _assignmentRef(lessonId, moduleId).set(
      {
        'status': AssessmentStatus.published.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> disableAssignment(
    String lessonId,
    String moduleId,
    String assignmentId,
  ) async {
    final lesson = await _loadLesson(lessonId);
    _assertOwner(lesson);

    await _assignmentRef(lessonId, moduleId).set(
      {
        'status': AssessmentStatus.disabled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
