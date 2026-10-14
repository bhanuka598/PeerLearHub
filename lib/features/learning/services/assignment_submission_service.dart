/// Learner-side assignment submission writer for teacher-authored assignments.
///
/// Distinct from [AssignmentService] which handles the legacy catalog-course flow.
/// Writes to:
/// - `users/{uid}/assignmentSubmissions/{assignmentId}`
/// - `users/{uid}/enrollments/{lessonId}` with `assignmentSubmitted: true`
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/quiz_submission.dart';

class AssignmentSubmissionService {
  AssignmentSubmissionService._();

  static final instance = AssignmentSubmissionService._();

  Future<void> submit({
    required String assignmentId,
    required String lessonId,
    required String description,
    required String githubUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in before submitting an assignment.');
    }

    final trimmedUrl = githubUrl.trim();
    final github = Uri.tryParse(trimmedUrl);
    if (github == null) {
      throw ArgumentError(
        'Enter a valid GitHub repository URL (e.g., https://github.com/username/repository).',
      );
    }
    if (github.host.toLowerCase() != 'github.com') {
      throw ArgumentError(
        'URL must be from github.com (e.g., https://github.com/username/repository).',
      );
    }
    if (trimmedUrl.endsWith('/') ||
        trimmedUrl.endsWith('github.com/') ||
        trimmedUrl.endsWith('github.com')) {
      throw ArgumentError(
        'Please enter a complete GitHub repository URL (e.g., https://github.com/username/repository).',
      );
    }

    final submission = AssignmentSubmission(
      id: assignmentId,
      assignmentId: assignmentId,
      lessonId: lessonId,
      learnerId: user.uid,
      description: description.trim(),
      githubUrl: trimmedUrl,
      status: AssignmentSubmissionStatus.submitted,
      submittedAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('assignmentSubmissions')
        .doc(assignmentId)
        .set(submission.toMap(), SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('enrollments')
        .doc(lessonId)
        .set(
      {
        'courseId': lessonId,
        'assignmentSubmitted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<AssignmentSubmission?> getSubmission({
    required String learnerId,
    required String assignmentId,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(learnerId)
        .collection('assignmentSubmissions')
        .doc(assignmentId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return AssignmentSubmission.fromMap(doc.data()!);
  }
}
