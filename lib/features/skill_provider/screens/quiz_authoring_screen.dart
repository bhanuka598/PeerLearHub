/// Dedicated form for authoring a module quiz — separate from lesson creation.
///
/// Business rules:
/// - Validates ≥3 questions, 2–6 options each, one correct answer per question.
/// - Editing a published quiz creates a new version (existing learners keep their attempt).
/// - Only the lesson owner can save or publish.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/lesson.dart';
import '../models/assessment_status.dart';
import '../models/quiz.dart';
import '../services/firebase_lesson_service.dart';
import '../services/quiz_service.dart';
import '../utils/provider_id_helper.dart';
import '../widgets/app_header.dart';

class QuizAuthoringScreen extends StatefulWidget {
  const QuizAuthoringScreen({
    super.key,
    required this.lessonId,
    required this.moduleId,
  });

  final String lessonId;
  final String moduleId;

  @override
  State<QuizAuthoringScreen> createState() => _QuizAuthoringScreenState();
}

class _QuestionDraft {
  _QuestionDraft({
    required this.id,
    required this.textController,
    required this.optionControllers,
    this.correctIndex = 0,
  });

  final String id;
  final TextEditingController textController;
  final List<TextEditingController> optionControllers;
  int correctIndex;

  void dispose() {
    textController.dispose();
    for (final c in optionControllers) {
      c.dispose();
    }
  }
}

class _QuizAuthoringScreenState extends State<QuizAuthoringScreen> {
  final _titleController = TextEditingController();
  final _questions = <_QuestionDraft>[];
  final _quizService = QuizService.instance;

  Lesson? _lesson;
  Quiz? _existingQuiz;
  bool _loading = true;
  bool _saving = false;
  int _pointsPerQuestion = 1;
  QuizAttemptsPolicy _attemptsPolicy = QuizAttemptsPolicy.unlimited;
  int _maxAttempts = 3;
  double _passThreshold = 100;

  bool get _isPublished =>
      _existingQuiz?.status == AssessmentStatus.published;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final lesson =
          await FirebaseLessonService.instance.getLessonById(widget.lessonId);
      final quiz = await _quizService.getQuizForModule(
        widget.lessonId,
        widget.moduleId,
      );

      if (lesson == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lesson not found.')),
          );
          context.pop();
        }
        return;
      }

      _lesson = lesson;
      _existingQuiz = quiz;

      if (quiz != null) {
        _titleController.text = quiz.title;
        _pointsPerQuestion = quiz.pointsPerQuestion;
        _attemptsPolicy = quiz.attemptsPolicy;
        _maxAttempts = quiz.maxAttempts;
        _passThreshold = quiz.passThreshold.toDouble();
        for (final q in quiz.questions) {
          _questions.add(_questionFromModel(q));
        }
      } else {
        _addQuestion();
        _addQuestion();
        _addQuestion();
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load quiz: $e')),
        );
      }
    }
  }

  _QuestionDraft _questionFromModel(QuizQuestion q) {
    return _QuestionDraft(
      id: q.id,
      textController: TextEditingController(text: q.questionText),
      optionControllers: q.options
          .map((o) => TextEditingController(text: o))
          .toList(),
      correctIndex: q.correctIndex,
    );
  }

  _QuestionDraft _newQuestionDraft({int order = 0}) {
    return _QuestionDraft(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}_$order',
      textController: TextEditingController(),
      optionControllers: [
        TextEditingController(),
        TextEditingController(),
      ],
    );
  }

  void _addQuestion() {
    setState(() => _questions.add(_newQuestionDraft(order: _questions.length)));
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) return;
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  void _addOption(_QuestionDraft question) {
    if (question.optionControllers.length >= 6) return;
    setState(() {
      question.optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(_QuestionDraft question, int optionIndex) {
    if (question.optionControllers.length <= 2) return;
    setState(() {
      question.optionControllers[optionIndex].dispose();
      question.optionControllers.removeAt(optionIndex);
      if (question.correctIndex >= question.optionControllers.length) {
        question.correctIndex = 0;
      }
    });
  }

  Quiz _buildQuiz({required AssessmentStatus status}) {
    final providerId =
        _lesson?.providerId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();
    final quizId = _existingQuiz?.id ??
        Quiz.defaultId(widget.lessonId, widget.moduleId);

    return Quiz(
      id: quizId,
      lessonId: widget.lessonId,
      moduleId: widget.moduleId,
      providerId: providerId,
      title: _titleController.text.trim(),
      questions: [
        for (var i = 0; i < _questions.length; i++)
          QuizQuestion(
            id: _questions[i].id,
            questionText: _questions[i].textController.text.trim(),
            options: _questions[i].optionControllers
                .map((c) => c.text.trim())
                .toList(),
            correctIndex: _questions[i].correctIndex,
            order: i + 1,
          ),
      ],
      pointsPerQuestion: _pointsPerQuestion,
      attemptsPolicy: _attemptsPolicy,
      maxAttempts: _maxAttempts,
      passThreshold: _passThreshold.round(),
      status: status,
      version: _existingQuiz?.version ?? 1,
      createdAt: _existingQuiz?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _saveDraft() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz title is required.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ensureProviderId();
      final quiz = _buildQuiz(status: AssessmentStatus.draft);
      await _quizService.saveQuizDraft(quiz);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz saved as draft.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish() async {
    setState(() => _saving = true);
    try {
      await ensureProviderId();
      var quiz = _buildQuiz(status: AssessmentStatus.draft);

      if (_isPublished) {
        await _quizService.createNewVersion(
          widget.lessonId,
          widget.moduleId,
          quiz.id,
        );
        quiz = quiz.copyWith(version: (_existingQuiz?.version ?? 1) + 1);
      }

      await _quizService.saveQuizDraft(quiz);
      await _quizService.publishQuiz(widget.lessonId, widget.moduleId, quiz.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isPublished ? 'New quiz version published.' : 'Quiz published.',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.teacherPageBackground,
      appBar: const TealPageHeader(title: 'Manage Quiz'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isPublished)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.statusDraftBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.statusDraftText),
                      ),
                      child: const Text(
                        'Editing creates a new version. Existing learners keep their current attempt.',
                        style: TextStyle(color: AppTheme.statusDraftText),
                      ),
                    ),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Quiz title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      OutlinedButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Add question'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_questions.length, (index) {
                    final question = _questions[index];
                    return _QuestionEditor(
                      index: index,
                      question: question,
                      onRemove: () => _removeQuestion(index),
                      onAddOption: () => _addOption(question),
                      onRemoveOption: (oi) => _removeOption(question, oi),
                      onCorrectChanged: (value) {
                        setState(() => question.correctIndex = value);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _pointsPerQuestion,
                    decoration: const InputDecoration(
                      labelText: 'Points per question',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      10,
                      (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                    ),
                    onChanged: (v) => setState(() => _pointsPerQuestion = v ?? 1),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<QuizAttemptsPolicy>(
                    value: _attemptsPolicy,
                    decoration: const InputDecoration(
                      labelText: 'Attempts policy',
                      border: OutlineInputBorder(),
                    ),
                    items: QuizAttemptsPolicy.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _attemptsPolicy = v ?? _attemptsPolicy),
                  ),
                  if (_attemptsPolicy == QuizAttemptsPolicy.bestOfN) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _maxAttempts,
                      decoration: const InputDecoration(
                        labelText: 'Max attempts (N)',
                        border: OutlineInputBorder(),
                      ),
                      items: [2, 3, 4, 5]
                          .map(
                            (n) => DropdownMenuItem(
                              value: n,
                              child: Text('$n'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _maxAttempts = v ?? _maxAttempts),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text('Pass threshold: ${_passThreshold.round()}%'),
                  Slider(
                    value: _passThreshold,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: AppTheme.primaryColor,
                    label: '${_passThreshold.round()}%',
                    onChanged: (v) => setState(() => _passThreshold = v),
                  ),
                  const SizedBox(height: 24),
                  if (_saving)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  else ...[
                    OutlinedButton(
                      onPressed: _saveDraft,
                      child: const Text('Save as Draft'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _publish,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: Text(
                        _isPublished ? 'Publish New Version' : 'Publish',
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _QuestionEditor extends StatelessWidget {
  const _QuestionEditor({
    required this.index,
    required this.question,
    required this.onRemove,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onCorrectChanged,
  });

  final int index;
  final _QuestionDraft question;
  final VoidCallback onRemove;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;
  final ValueChanged<int> onCorrectChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.teacherCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question ${index + 1}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline, color: AppTheme.statusInactiveText),
              ),
            ],
          ),
          TextField(
            controller: question.textController,
            decoration: const InputDecoration(
              labelText: 'Question text',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          ...List.generate(question.optionControllers.length, (oi) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Radio<int>(
                    value: oi,
                    groupValue: question.correctIndex,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) {
                      if (v != null) onCorrectChanged(v);
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: question.optionControllers[oi],
                      decoration: InputDecoration(
                        labelText: 'Option ${oi + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  if (question.optionControllers.length > 2)
                    IconButton(
                      onPressed: () => onRemoveOption(oi),
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                    ),
                ],
              ),
            );
          }),
          if (question.optionControllers.length < 6)
            TextButton.icon(
              onPressed: onAddOption,
              icon: const Icon(Icons.add),
              label: const Text('Add option'),
            ),
        ],
      ),
    );
  }
}
