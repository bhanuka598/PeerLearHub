import '../models/learning_course.dart';
import '../models/learning_quiz.dart';

LearningQuiz quizForModule(LearningCourse course, int moduleIndex) {
  final module = course.modules[moduleIndex % course.modules.length];
  return LearningQuiz(
    courseId: course.id,
    moduleId: module.id,
    moduleTitle: module.title,
    questions: [
      QuizQuestion(
        question: 'Which topic is covered in ${module.title}?',
        options: [
          module.title,
          'Server billing',
          'Email marketing',
          'Audio mixing',
        ],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: 'What is the best way to check your understanding?',
        options: [
          'Skip the lesson',
          'Practice and review',
          'Guess every answer',
          'Close the course',
        ],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: 'What happens when you complete a learning activity?',
        options: [
          'Progress is saved',
          'The course is deleted',
          'Your account logs out',
          'Nothing is recorded',
        ],
        correctIndex: 0,
      ),
    ],
  );
}
