/// Single source of truth for lesson/module completion and certificate unlock.
///
/// Business rules:
/// - Module complete = playlist watched AND (quiz passed if a published quiz exists).
/// - Lesson complete = all modules complete AND (assignment submitted if a published assignment exists).
/// - Certificate unlock = lesson complete.
/// - Draft/disabled assessments are treated as absent (do not block completion).
import '../../../models/lesson.dart';
import '../../skill_provider/models/assessment_status.dart';
import '../../skill_provider/models/assignment.dart';
import '../../skill_provider/models/quiz.dart';
import '../models/quiz_submission.dart';

class ModuleProgressResult {
  const ModuleProgressResult({
    required this.moduleId,
    required this.playlistComplete,
    required this.quizRequired,
    required this.quizPassed,
    required this.isComplete,
  });

  final String moduleId;
  final bool playlistComplete;
  final bool quizRequired;
  final bool quizPassed;
  final bool isComplete;
}

class CourseProgressResult {
  const CourseProgressResult({
    required this.moduleResults,
    required this.allModulesComplete,
    required this.assignmentRequired,
    required this.assignmentSubmitted,
    required this.isLessonComplete,
    required this.certificateUnlocked,
    required this.overallPercent,
  });

  final Map<String, ModuleProgressResult> moduleResults;
  final bool allModulesComplete;
  final bool assignmentRequired;
  final bool assignmentSubmitted;
  final bool isLessonComplete;
  final bool certificateUnlocked;
  final int overallPercent;
}

bool _quizPassedForModule({
  required Quiz quiz,
  required List<QuizSubmission> submissions,
}) {
  return submissions.any(
    (s) =>
        s.quizId == quiz.id &&
        s.quizVersion == quiz.version &&
        s.score >= quiz.passThreshold,
  );
}

CourseProgressResult computeCourseProgress({
  required Lesson lesson,
  required Map<String, bool> modulePlaylistComplete,
  required Map<String, Quiz?> quizzesByModule,
  required Map<String, Assignment?> assignmentsByModule,
  required List<QuizSubmission> quizSubmissions,
  required List<AssignmentSubmission> assignmentSubmissions,
}) {
  final moduleResults = <String, ModuleProgressResult>{};

  for (final module in lesson.modules) {
    final playlistComplete = modulePlaylistComplete[module.id] ?? false;
    final quiz = quizzesByModule[module.id];
    final publishedQuiz =
        quiz != null && quiz.status == AssessmentStatus.published ? quiz : null;
    final quizRequired = publishedQuiz != null;
    final quizPassed = !quizRequired ||
        _quizPassedForModule(
          quiz: publishedQuiz,
          submissions: quizSubmissions,
        );
    final isComplete = playlistComplete && quizPassed;

    moduleResults[module.id] = ModuleProgressResult(
      moduleId: module.id,
      playlistComplete: playlistComplete,
      quizRequired: quizRequired,
      quizPassed: quizPassed,
      isComplete: isComplete,
    );
  }

  final allModulesComplete = lesson.modules.isNotEmpty &&
      lesson.modules.every((m) => moduleResults[m.id]?.isComplete ?? false);

  final publishedAssignments = assignmentsByModule.entries
      .where((e) =>
          e.value != null && e.value!.status == AssessmentStatus.published)
      .map((e) => e.value!)
      .toList();

  final assignmentRequired = publishedAssignments.isNotEmpty;
  final submittedAssignmentIds =
      assignmentSubmissions.map((s) => s.assignmentId).toSet();
  final assignmentSubmitted = !assignmentRequired ||
      publishedAssignments.every((a) => submittedAssignmentIds.contains(a.id));

  final isLessonComplete = allModulesComplete && assignmentSubmitted;
  final totalSteps = lesson.modules.length + (assignmentRequired ? 1 : 0);
  var completedSteps = moduleResults.values.where((m) => m.isComplete).length;
  if (assignmentRequired && assignmentSubmitted) {
    completedSteps++;
  }
  final overallPercent = totalSteps == 0
      ? 0
      : ((completedSteps / totalSteps) * 100).round().clamp(0, 100);

  return CourseProgressResult(
    moduleResults: moduleResults,
    allModulesComplete: allModulesComplete,
    assignmentRequired: assignmentRequired,
    assignmentSubmitted: assignmentSubmitted,
    isLessonComplete: isLessonComplete,
    certificateUnlocked: isLessonComplete,
    overallPercent: overallPercent,
  );
}
