/// Learner submission records for teacher-authored quizzes and assignments.
///
/// Business rules:
/// - Quiz submissions are keyed by `{quizId}_{attemptNumber}` and linked to a quiz version.
/// - Assignment submissions are keyed by assignmentId.
/// - Submissions are never hard-deleted; status changes only.
/// - Existing quiz submissions stay linked to the version they were taken against.
import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentSubmissionStatus {
  submitted,
  graded,
  returned,
}

extension AssignmentSubmissionStatusX on AssignmentSubmissionStatus {
  static AssignmentSubmissionStatus fromName(String? value) {
    return AssignmentSubmissionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AssignmentSubmissionStatus.submitted,
    );
  }
}

class QuizSubmission {
  const QuizSubmission({
    required this.id,
    required this.quizId,
    required this.quizVersion,
    required this.lessonId,
    required this.moduleId,
    required this.learnerId,
    required this.answers,
    required this.score,
    required this.attemptNumber,
    required this.submittedAt,
  });

  final String id;
  final String quizId;
  final int quizVersion;
  final String lessonId;
  final String moduleId;
  final String learnerId;
  final List<int> answers;
  final int score;
  final int attemptNumber;
  final DateTime submittedAt;

  static String docId(String quizId, int attemptNumber) =>
      '${quizId}_$attemptNumber';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'quizVersion': quizVersion,
      'lessonId': lessonId,
      'moduleId': moduleId,
      'learnerId': learnerId,
      'answers': answers,
      'score': score,
      'attemptNumber': attemptNumber,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }

  factory QuizSubmission.fromMap(Map<String, dynamic> map) {
    return QuizSubmission(
      id: map['id'] as String? ?? '',
      quizId: map['quizId'] as String? ?? '',
      quizVersion: (map['quizVersion'] as num?)?.toInt() ?? 1,
      lessonId: map['lessonId'] as String? ?? '',
      moduleId: map['moduleId'] as String? ?? '',
      learnerId: map['learnerId'] as String? ?? '',
      answers: List<int>.from(map['answers'] as List? ?? []),
      score: (map['score'] as num?)?.toInt() ?? 0,
      attemptNumber: (map['attemptNumber'] as num?)?.toInt() ?? 1,
      submittedAt: _parseDate(map['submittedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

class AssignmentSubmission {
  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.lessonId,
    required this.learnerId,
    required this.description,
    required this.githubUrl,
    required this.status,
    required this.submittedAt,
    this.feedback,
    this.score,
  });

  final String id;
  final String assignmentId;
  final String lessonId;
  final String learnerId;
  final String description;
  final String githubUrl;
  final AssignmentSubmissionStatus status;
  final String? feedback;
  final int? score;
  final DateTime submittedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'lessonId': lessonId,
      'learnerId': learnerId,
      'description': description,
      'githubUrl': githubUrl,
      'status': status.name,
      'feedback': feedback,
      'score': score,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }

  factory AssignmentSubmission.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmission(
      id: map['id'] as String? ?? '',
      assignmentId: map['assignmentId'] as String? ?? '',
      lessonId: map['lessonId'] as String? ?? '',
      learnerId: map['learnerId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      githubUrl: map['githubUrl'] as String? ?? '',
      status: AssignmentSubmissionStatusX.fromName(map['status'] as String?),
      feedback: map['feedback'] as String?,
      score: (map['score'] as num?)?.toInt(),
      submittedAt: _parseDate(map['submittedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
