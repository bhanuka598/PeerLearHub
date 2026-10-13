/// Firestore service for teacher-authored quizzes nested under lesson modules.
///
/// Firestore paths:
/// - Live quiz: `lessons/{lessonId}/modules/{moduleId}/quizzes/main`
/// - Version archive: `lessons/{lessonId}/modules/{moduleId}/quizzes/main/versions/{version}`
/// - Submissions: `users/{learnerId}/quizSubmissions/{quizId}_{attemptNumber}`
///
/// Security rules (add to firestore.rules):
/// ```
/// match /lessons/{lessonId}/modules/{moduleId}/quizzes/{quizDoc} {
///   allow read: if request.auth != null
///     && (resource.data.status == 'published'
///         || get(/databases/$(database)/documents/lessons/$(lessonId)).data.providerId == request.auth.uid
///         || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'moderator');
///   allow create, update: if request.auth != null
///     && get(/databases/$(database)/documents/lessons/$(lessonId)).data.providerId == request.auth.uid;
///   allow update: if request.auth != null
///     && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'moderator'
///     && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'updatedAt']);
///   match /versions/{versionId} {
///     allow read: if request.auth != null;
///     allow write: if request.auth != null
///       && get(/databases/$(database)/documents/lessons/$(lessonId)).data.providerId == request.auth.uid;
///   }
/// }
/// match /users/{userId}/quizSubmissions/{submissionId} {
///   allow read, create, update: if request.auth != null && request.auth.uid == userId;
///   allow delete: if false;
/// }
/// ```
///
/// TODO(production): Move quiz grading to a trusted server; client-side grading
/// using correctIndex is not secure for production.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/lesson.dart';
import '../../learning/models/quiz_submission.dart';
import '../../learning/utils/progress_calculator.dart';
import '../models/assessment_status.dart';
import '../models/assignment.dart';
import '../models/quiz.dart';
import 'assignment_service.dart';
import 'firebase_lesson_service.dart';

class QuizService {
  QuizService._();

  static final instance = QuizService._();

  static const _quizDocId = 'main';

  DocumentReference<Map<String, dynamic>> _quizRef(
    String lessonId,
    String moduleId,
  ) {
    return FirebaseFirestore.instance
        .collection('lessons')
        .doc(lessonId)
        .collection('modules')
        .doc(moduleId)
        .collection('quizzes')
        .doc(_quizDocId);
  }

  CollectionReference<Map<String, dynamic>> _versionsRef(
    String lessonId,
    String moduleId,
  ) {
    return _quizRef(lessonId, moduleId).collection('versions');
  }

  CollectionReference<Map<String, dynamic>> _submissionsRef(String learnerId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(learnerId)
        .collection('quizSubmissions');
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
      throw StateError('Only the lesson owner can modify this quiz.');
    }
  }

  void _validateQuizForPublish(Quiz quiz) {
    if (quiz.questions.length < 3) {
      throw ArgumentError('Publish requires at least 3 questions.');
    }
    for (final question in quiz.questions) {
      if (question.questionText.trim().isEmpty) {
        throw ArgumentError('Every question must have text.');
      }
      if (question.options.length < 2 || question.options.length > 6) {
        throw ArgumentError('Each question must have 2–6 options.');
      }
      if (question.correctIndex < 0 ||
          question.correctIndex >= question.options.length) {
        throw ArgumentError('Each question must have a valid correct answer.');
      }
    }
    if (quiz.pointsPerQuestion <= 0) {
      throw ArgumentError('Points per question must be greater than 0.');
    }
  }

  Future<Quiz?> getQuizForModule(String lessonId, String moduleId) async {
    final doc = await _quizRef(lessonId, moduleId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Quiz.fromMap(doc.data()!);
  }

  Future<List<QuizSubmission>> getSubmissionsForLearner(String learnerId) async {
    final snapshot = await _submissionsRef(learnerId).get();
    return snapshot.docs
        .map((doc) => QuizSubmission.fromMap(doc.data()))
        .toList();
  }

  Future<void> saveQuizDraft(Quiz quiz) async {
    final lesson = await _loadLesson(quiz.lessonId);
    _assertOwner(lesson);

    final now = DateTime.now();
    final payload = quiz
        .copyWith(
          status: AssessmentStatus.draft,
          updatedAt: now,
          createdAt: quiz.createdAt,
        )
        .toMap();

    await _quizRef(quiz.lessonId, quiz.moduleId).set(
      payload,
      SetOptions(merge: true),
    );
  }

  Future<void> publishQuiz(
    String lessonId,
    String moduleId,
    String quizId,
  ) async {
    final lesson = await _loadLesson(lessonId);
    _assertOwner(lesson);

    final doc = await _quizRef(lessonId, moduleId).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('Quiz not found.');
    }
    var quiz = Quiz.fromMap(doc.data()!);
    if (quiz.id != quizId) {
      throw StateError('Quiz id mismatch.');
    }

    _validateQuizForPublish(quiz);
    quiz = quiz.copyWith(
      status: AssessmentStatus.published,
      updatedAt: DateTime.now(),
    );

    await _quizRef(lessonId, moduleId).set(
      quiz.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> disableQuiz(
    String lessonId,
    String moduleId,
    String quizId,
  ) async {
    final lesson = await _loadLesson(lessonId);
    _assertOwner(lesson);

    await _quizRef(lessonId, moduleId).set(
      {
        'status': AssessmentStatus.disabled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> createNewVersion(
    String lessonId,
    String moduleId,
    String quizId,
  ) async {
    final lesson = await _loadLesson(lessonId);
    _assertOwner(lesson);

    final doc = await _quizRef(lessonId, moduleId).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('Quiz not found.');
    }
    final current = Quiz.fromMap(doc.data()!);
    if (current.id != quizId) {
      throw StateError('Quiz id mismatch.');
    }
    if (current.status != AssessmentStatus.published) {
      throw StateError('Only published quizzes can be versioned.');
    }

    await _versionsRef(lessonId, moduleId)
        .doc('${current.version}')
        .set(current.toMap(), SetOptions(merge: true));

    final next = current.copyWith(
      version: current.version + 1,
      status: AssessmentStatus.draft,
      updatedAt: DateTime.now(),
    );

    await _quizRef(lessonId, moduleId).set(
      next.toMap(),
      SetOptions(merge: true),
    );
  }

  int gradeQuiz(Quiz quiz, List<int> answers) {
    var correct = 0;
    for (var i = 0; i < quiz.questions.length; i++) {
      if (i < answers.length &&
          answers[i] == quiz.questions[i].correctIndex) {
        correct++;
      }
    }
    if (quiz.questions.isEmpty) return 0;
    return ((correct / quiz.questions.length) * 100).round();
  }

  Future<QuizSubmission> submitAttempt({
    required Quiz quiz,
    required List<int> answers,
    required int perQuestionRetries,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in before submitting a quiz.');
    }
    if (quiz.status != AssessmentStatus.published) {
      throw StateError('This quiz is not available.');
    }

    final existing = await _submissionsRef(user.uid)
        .where('quizId', isEqualTo: quiz.id)
        .get();
    final attemptCount = existing.docs.length;

    if (quiz.attemptsPolicy == QuizAttemptsPolicy.oneAttempt &&
        attemptCount >= 1) {
      throw StateError('You have already used your one attempt for this quiz.');
    }
    if (quiz.attemptsPolicy == QuizAttemptsPolicy.bestOfN &&
        attemptCount >= quiz.maxAttempts) {
      throw StateError('You have reached the maximum number of attempts.');
    }

    final attemptNumber = attemptCount + 1;
    final score = gradeQuiz(quiz, answers);
    final submission = QuizSubmission(
      id: QuizSubmission.docId(quiz.id, attemptNumber),
      quizId: quiz.id,
      quizVersion: quiz.version,
      lessonId: quiz.lessonId,
      moduleId: quiz.moduleId,
      learnerId: user.uid,
      answers: answers,
      score: score,
      attemptNumber: attemptNumber,
      submittedAt: DateTime.now(),
    );

    await _submissionsRef(user.uid).doc(submission.id).set(
          submission.toMap(),
          SetOptions(merge: true),
        );

    final points = perQuestionRetries == 0 ? 5 : 3;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'learningPoints': FieldValue.increment(points)},
      SetOptions(merge: true),
    );

    await _updateEnrollmentProgress(
      lessonId: quiz.lessonId,
      learnerId: user.uid,
      quizPassed: score >= quiz.passThreshold,
      moduleId: quiz.moduleId,
    );

    return submission;
  }

  Future<void> _updateEnrollmentProgress({
    required String lessonId,
    required String learnerId,
    required bool quizPassed,
    required String moduleId,
  }) async {
    final lesson = await _loadLesson(lessonId);
    final quizzesByModule = <String, Quiz?>{};
    final assignmentsByModule = <String, Assignment?>{};
    final modulePlaylistComplete = <String, bool>{};

    for (final module in lesson.modules) {
      quizzesByModule[module.id] =
          await getQuizForModule(lessonId, module.id);
      assignmentsByModule[module.id] =
          await ProviderAssignmentService.instance
              .getAssignmentForModule(lessonId, module.id);

      final enrollmentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(learnerId)
          .collection('enrollments')
          .doc(lessonId)
          .get();
      final data = enrollmentDoc.data() ?? {};
      final completedVideos = List<int>.from(
        (data['completedVideos'] as List?)?.map((e) => (e as num).toInt()) ??
            [],
      );
      modulePlaylistComplete[module.id] = completedVideos.isNotEmpty;
    }

    final quizSubmissions = await getSubmissionsForLearner(learnerId);
    final assignmentSubmissions =
        await ProviderAssignmentService.instance.getSubmissionsForLearner(
      learnerId,
    );

    final progress = computeCourseProgress(
      lesson: lesson,
      modulePlaylistComplete: modulePlaylistComplete,
      quizzesByModule: quizzesByModule,
      assignmentsByModule: assignmentsByModule,
      quizSubmissions: quizSubmissions,
      assignmentSubmissions: assignmentSubmissions,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(learnerId)
        .collection('enrollments')
        .doc(lessonId)
        .set(
      {
        'courseId': lessonId,
        'progress': progress.overallPercent,
        'quizCompleted': quizPassed,
        'lastQuizModuleId': moduleId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
