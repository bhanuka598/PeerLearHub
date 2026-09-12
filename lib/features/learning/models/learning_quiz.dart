class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
}

class LearningQuiz {
  const LearningQuiz({
    required this.courseId,
    required this.moduleId,
    required this.moduleTitle,
    required this.questions,
  });

  final String courseId;
  final String moduleId;
  final String moduleTitle;
  final List<QuizQuestion> questions;
}
