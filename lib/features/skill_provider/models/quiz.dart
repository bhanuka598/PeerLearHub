/// Teacher-authored quiz model nested under a [Lesson] module.
///
/// Business rules:
/// - One quiz per module (stored at `lessons/{lessonId}/modules/{moduleId}/quizzes/main`).
/// - A quiz cannot exist without its parent module.
/// - Editing a published quiz creates a new version; existing submissions stay on their version.
/// - Only `status == published` quizzes are visible to learners.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'assessment_status.dart';

enum QuizAttemptsPolicy {
  unlimited,
  oneAttempt,
  bestOfN,
}

extension QuizAttemptsPolicyX on QuizAttemptsPolicy {
  String get label {
    switch (this) {
      case QuizAttemptsPolicy.unlimited:
        return 'Unlimited attempts';
      case QuizAttemptsPolicy.oneAttempt:
        return 'One attempt only';
      case QuizAttemptsPolicy.bestOfN:
        return 'Best of N attempts';
    }
  }

  static QuizAttemptsPolicy fromName(String? value) {
    return QuizAttemptsPolicy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuizAttemptsPolicy.unlimited,
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.order,
  });

  final String id;
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final int order;

  QuizQuestion copyWith({
    String? id,
    String? questionText,
    List<String>? options,
    int? correctIndex,
    int? order,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'correctIndex': correctIndex,
      'order': order,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as String? ?? '',
      questionText: map['questionText'] as String? ?? '',
      options: List<String>.from(map['options'] as List? ?? []),
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }
}

class Quiz {
  const Quiz({
    required this.id,
    required this.lessonId,
    required this.moduleId,
    required this.providerId,
    required this.title,
    required this.questions,
    required this.pointsPerQuestion,
    required this.attemptsPolicy,
    required this.passThreshold,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.maxAttempts = 3,
  });

  final String id;
  final String lessonId;
  final String moduleId;
  final String providerId;
  final String title;
  final List<QuizQuestion> questions;
  final int pointsPerQuestion;
  final QuizAttemptsPolicy attemptsPolicy;
  final int maxAttempts;
  final int passThreshold;
  final AssessmentStatus status;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  static String defaultId(String lessonId, String moduleId) =>
      '${lessonId}_${moduleId}_quiz';

  Quiz copyWith({
    String? id,
    String? lessonId,
    String? moduleId,
    String? providerId,
    String? title,
    List<QuizQuestion>? questions,
    int? pointsPerQuestion,
    QuizAttemptsPolicy? attemptsPolicy,
    int? maxAttempts,
    int? passThreshold,
    AssessmentStatus? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      moduleId: moduleId ?? this.moduleId,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      pointsPerQuestion: pointsPerQuestion ?? this.pointsPerQuestion,
      attemptsPolicy: attemptsPolicy ?? this.attemptsPolicy,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      passThreshold: passThreshold ?? this.passThreshold,
      status: status ?? this.status,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonId': lessonId,
      'moduleId': moduleId,
      'providerId': providerId,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'pointsPerQuestion': pointsPerQuestion,
      'attemptsPolicy': attemptsPolicy.name,
      'maxAttempts': maxAttempts,
      'passThreshold': passThreshold,
      'status': status.name,
      'version': version,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    final rawQuestions = map['questions'] as List? ?? [];
    return Quiz(
      id: map['id'] as String? ?? '',
      lessonId: map['lessonId'] as String? ?? '',
      moduleId: map['moduleId'] as String? ?? '',
      providerId: map['providerId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      questions: rawQuestions
          .map((q) => QuizQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
          .toList(),
      pointsPerQuestion: (map['pointsPerQuestion'] as num?)?.toInt() ?? 1,
      attemptsPolicy: QuizAttemptsPolicyX.fromName(
        map['attemptsPolicy'] as String?,
      ),
      maxAttempts: (map['maxAttempts'] as num?)?.toInt() ?? 3,
      passThreshold: (map['passThreshold'] as num?)?.toInt() ?? 100,
      status: AssessmentStatusX.fromName(map['status'] as String?),
      version: (map['version'] as num?)?.toInt() ?? 1,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
