/// Learner assignment submission form for teacher-authored assignments.
///
/// Business rules:
/// - Separate from legacy [AssignmentService.submit] (catalog courses).
/// - Validates GitHub URL client-side.
/// - Writes to assignmentSubmissions and enrollments on success.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../skill_provider/models/assessment_status.dart';
import '../../skill_provider/models/assignment.dart';
import '../../skill_provider/services/assignment_service.dart';
import '../services/assignment_submission_service.dart';

class AssignmentSubmitScreen extends StatefulWidget {
  const AssignmentSubmitScreen({
    super.key,
    required this.lessonId,
    required this.moduleId,
  });

  final String lessonId;
  final String moduleId;

  @override
  State<AssignmentSubmitScreen> createState() => _AssignmentSubmitScreenState();
}

class _AssignmentSubmitScreenState extends State<AssignmentSubmitScreen> {
  final _descriptionController = TextEditingController();
  final _githubController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Assignment? _assignment;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final assignment = await ProviderAssignmentService.instance
          .getAssignmentForModule(widget.lessonId, widget.moduleId);

      if (assignment == null ||
          assignment.status != AssessmentStatus.published) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No published assignment available.')),
          );
          context.pop();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _assignment = assignment;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load assignment: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final assignment = _assignment;
    if (assignment == null) return;

    setState(() => _submitting = true);
    try {
      await AssignmentSubmissionService.instance.submit(
        assignmentId: assignment.id,
        lessonId: widget.lessonId,
        description: _descriptionController.text,
        githubUrl: _githubController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully.')),
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateGithub(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'GitHub URL is required.';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.host.toLowerCase() != 'github.com') {
      return 'Enter a valid github.com repository URL.';
    }
    if (value.trim().endsWith('github.com') ||
        value.trim().endsWith('github.com/')) {
      return 'Enter a complete repository URL.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final assignment = _assignment;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(assignment?.title ?? 'Submit Assignment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : assignment == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignment.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(assignment.description),
                              if (assignment.requirements.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Requirements',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                ...assignment.requirements.map(
                                  (r) => Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• '),
                                        Expanded(child: Text(r)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (assignment.dueAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Due: ${assignment.dueAt!.toLocal().toString().split(' ').first}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Your submission description',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _githubController,
                          decoration: const InputDecoration(
                            labelText: 'GitHub repository URL',
                            border: OutlineInputBorder(),
                            hintText: 'https://github.com/username/repository',
                          ),
                          validator: _validateGithub,
                        ),
                        const SizedBox(height: 24),
                        if (_submitting)
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          )
                        else
                          FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                            ),
                            child: const Text('Submit Assignment'),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
