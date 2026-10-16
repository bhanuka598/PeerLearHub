/// Learner quiz attempt screen for teacher-authored module quizzes.
///
/// Business rules:
/// - Only published quizzes are loaded.
/// - One question at a time; client-side grading on final submit.
/// - Attempts policy enforced at UI and service level.
/// - Awards 5 points first-try, 3 on retry (per question flow).
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../skill_provider/models/assessment_status.dart';
import '../../skill_provider/models/quiz.dart';
import '../../skill_provider/services/quiz_service.dart';
import '../models/quiz_submission.dart';

class QuizAttemptScreen extends StatefulWidget {
  const QuizAttemptScreen({
    super.key,
    required this.lessonId,
    required this.moduleId,
  });

  final String lessonId;
  final String moduleId;

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  Quiz? _quiz;
  List<QuizSubmission> _existingSubmissions = [];
  bool _loading = true;
  bool _submitting = false;
  int _currentIndex = 0;
  int? _selectedOption;
  bool _checked = false;
  int _retriesThisQuestion = 0;
  final _answers = <int>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final quiz = await QuizService.instance.getQuizForModule(
        widget.lessonId,
        widget.moduleId,
      );
      final user = FirebaseAuth.instance.currentUser;
      var submissions = <QuizSubmission>[];
      if (user != null) {
        submissions = await QuizService.instance.getSubmissionsForLearner(
          user.uid,
        );
        submissions = submissions
            .where((s) => s.quizId == quiz?.id)
            .toList();
      }

      if (quiz == null || quiz.status != AssessmentStatus.published) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No published quiz available.')),
          );
          popOrGo(context, '/learning');
        }
        return;
      }

      if (mounted) {
        setState(() {
          _quiz = quiz;
          _existingSubmissions = submissions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load quiz: $e')),
        );
      }
    }
  }

  bool get _attemptsBlocked {
    final quiz = _quiz;
    if (quiz == null) return true;
    final count = _existingSubmissions.length;
    if (quiz.attemptsPolicy == QuizAttemptsPolicy.oneAttempt && count >= 1) {
      return true;
    }
    if (quiz.attemptsPolicy == QuizAttemptsPolicy.bestOfN &&
        count >= quiz.maxAttempts) {
      return true;
    }
    return false;
  }

  Future<void> _checkAnswer() async {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an answer first.')),
      );
      return;
    }

    final quiz = _quiz!;
    final question = quiz.questions[_currentIndex];
    final isCorrect = _selectedOption == question.correctIndex;

    if (!isCorrect) {
      setState(() {
        _retriesThisQuestion++;
        _checked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect. Try again or move on.')),
      );
      return;
    }

    setState(() => _checked = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Correct!')),
    );
  }

  Future<void> _next() async {
    if (_selectedOption == null) return;

    _answers.add(_selectedOption!);
    final quiz = _quiz!;

    if (_currentIndex < quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _checked = false;
        _retriesThisQuestion = 0;
      });
      return;
    }

    await _submit();
  }

  Future<void> _submit() async {
    if (_attemptsBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attempts remaining for this quiz.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final submission = await QuizService.instance.submitAttempt(
        quiz: _quiz!,
        answers: _answers,
        perQuestionRetries: _retriesThisQuestion,
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Quiz Complete'),
          content: Text(
            'Score: ${submission.score}%\n'
            '${submission.score >= _quiz!.passThreshold ? 'Passed!' : 'Not passed yet.'}',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/learning/my-courses');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Back to My Courses'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(quiz?.title ?? 'Quiz'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => popOrGo(context, '/learning'),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _attemptsBlocked
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.block,
                          size: 48,
                          color: AppTheme.statusInactiveText,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You have no remaining attempts for this quiz.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => popOrGo(context, '/learning'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          child: const Text('Go back'),
                        ),
                      ],
                    ),
                  ),
                )
              : quiz == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Question ${_currentIndex + 1} of ${quiz.questions.length}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.cardDecoration,
                            child: Text(
                              quiz.questions[_currentIndex].questionText,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView(
                              children: [
                                for (var i = 0;
                                    i <
                                        quiz
                                            .questions[_currentIndex]
                                            .options
                                            .length;
                                    i++)
                                  RadioListTile<int>(
                                    value: i,
                                    groupValue: _selectedOption,
                                    activeColor: AppTheme.primaryColor,
                                    title: Text(
                                      quiz.questions[_currentIndex].options[i],
                                    ),
                                    onChanged: _checked
                                        ? null
                                        : (v) => setState(() => _selectedOption = v),
                                  ),
                              ],
                            ),
                          ),
                          if (_submitting)
                            const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            )
                          else ...[
                            if (!_checked)
                              FilledButton(
                                onPressed: _checkAnswer,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                ),
                                child: const Text('Check Answer'),
                              )
                            else
                              FilledButton(
                                onPressed: _next,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                ),
                                child: Text(
                                  _currentIndex < quiz.questions.length - 1
                                      ? 'Next'
                                      : 'Submit Quiz',
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}
