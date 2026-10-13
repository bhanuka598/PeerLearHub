/// Entry point for managing quizzes and assignments on an existing lesson.
///
/// Business rules:
/// - Only the lesson owner can author assessments (enforced in services).
/// - Each module row shows separate Quiz and Assignment cards with status.
/// - Assessments have independent lifecycles from lesson publish state.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/lesson.dart';
import '../models/assessment_status.dart';
import '../models/assignment.dart';
import '../models/quiz.dart';
import '../services/assignment_service.dart';
import '../services/firebase_lesson_service.dart';
import '../services/quiz_service.dart';
import '../widgets/app_header.dart';

class CourseManageScreen extends StatefulWidget {
  const CourseManageScreen({
    super.key,
    required this.lessonId,
    this.lesson,
  });

  final String lessonId;
  final Lesson? lesson;

  @override
  State<CourseManageScreen> createState() => _CourseManageScreenState();
}

class _CourseManageScreenState extends State<CourseManageScreen> {
  Lesson? _lesson;
  final _quizStatuses = <String, Quiz?>{};
  final _assignmentStatuses = <String, Assignment?>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final lesson =
          widget.lesson ??
          await FirebaseLessonService.instance.getLessonById(widget.lessonId);
      if (lesson == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lesson not found.')),
          );
          context.pop();
        }
        return;
      }

      final quizzes = <String, Quiz?>{};
      final assignments = <String, Assignment?>{};
      for (final module in lesson.modules) {
        quizzes[module.id] =
            await QuizService.instance.getQuizForModule(lesson.id, module.id);
        assignments[module.id] = await ProviderAssignmentService.instance
            .getAssignmentForModule(lesson.id, module.id);
      }

      if (mounted) {
        setState(() {
          _lesson = lesson;
          _quizStatuses
            ..clear()
            ..addAll(quizzes);
          _assignmentStatuses
            ..clear()
            ..addAll(assignments);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  String _statusLabel(AssessmentStatus? status) {
    if (status == null) return 'Not created';
    return status.label;
  }

  Color _statusColor(AssessmentStatus? status) {
    if (status == null) return AppTheme.textSecondary;
    switch (status) {
      case AssessmentStatus.published:
        return AppTheme.statusActiveText;
      case AssessmentStatus.draft:
        return AppTheme.statusDraftText;
      case AssessmentStatus.disabled:
        return AppTheme.statusInactiveText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: TealPageHeader(
        title: lesson?.title ?? 'Manage Assessments',
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : lesson == null
              ? const SizedBox.shrink()
              : RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Manage quizzes and assignments for each module. '
                        'Assessments are published independently from the lesson.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...lesson.modules.map((module) {
                        final quiz = _quizStatuses[module.id];
                        final assignment = _assignmentStatuses[module.id];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            decoration: AppTheme.cardDecoration,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                _AssessmentCard(
                                  icon: Icons.quiz_outlined,
                                  label: 'Quiz',
                                  status: _statusLabel(quiz?.status),
                                  statusColor: _statusColor(quiz?.status),
                                  buttonLabel: quiz == null ? 'Create' : 'Edit',
                                  onPressed: () => context.push(
                                    '/skill-provider/lesson/${lesson.id}/module/${module.id}/quiz',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _AssessmentCard(
                                  icon: Icons.assignment_outlined,
                                  label: 'Assignment',
                                  status: _statusLabel(assignment?.status),
                                  statusColor:
                                      _statusColor(assignment?.status),
                                  buttonLabel:
                                      assignment == null ? 'Create' : 'Edit',
                                  onPressed: () => context.push(
                                    '/skill-provider/lesson/${lesson.id}/module/${module.id}/assignment',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({
    required this.icon,
    required this.label,
    required this.status,
    required this.statusColor,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String status;
  final Color statusColor;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.iconBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
