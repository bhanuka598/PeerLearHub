/// Dedicated form for authoring a module assignment — separate from lesson creation.
///
/// Business rules:
/// - Validates title, description, ≥1 requirement, maxPoints > 0 before publish.
/// - Only the lesson owner can save or publish.
/// - Assignments have an independent lifecycle from lesson publish state.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/lesson.dart';
import '../models/assessment_status.dart';
import '../models/assignment.dart';
import '../services/assignment_service.dart';
import '../services/firebase_lesson_service.dart';
import '../utils/provider_id_helper.dart';
import '../widgets/app_header.dart';

class AssignmentAuthoringScreen extends StatefulWidget {
  const AssignmentAuthoringScreen({
    super.key,
    required this.lessonId,
    required this.moduleId,
  });

  final String lessonId;
  final String moduleId;

  @override
  State<AssignmentAuthoringScreen> createState() =>
      _AssignmentAuthoringScreenState();
}

class _AssignmentAuthoringScreenState extends State<AssignmentAuthoringScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxPointsController = TextEditingController(text: '15');
  final _requirements = <TextEditingController>[];

  Lesson? _lesson;
  Assignment? _existing;
  DateTime? _dueAt;
  bool _loading = true;
  bool _saving = false;

  bool get _isPublished =>
      _existing?.status == AssessmentStatus.published;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxPointsController.dispose();
    for (final c in _requirements) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final lesson =
          await FirebaseLessonService.instance.getLessonById(widget.lessonId);
      final assignment = await ProviderAssignmentService.instance
          .getAssignmentForModule(widget.lessonId, widget.moduleId);

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
      _existing = assignment;

      if (assignment != null) {
        _titleController.text = assignment.title;
        _descriptionController.text = assignment.description;
        _maxPointsController.text = '${assignment.maxPoints}';
        _dueAt = assignment.dueAt;
        for (final req in assignment.requirements) {
          _requirements.add(TextEditingController(text: req));
        }
      } else {
        _requirements.add(TextEditingController());
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load assignment: $e')),
        );
      }
    }
  }

  void _addRequirement() {
    setState(() => _requirements.add(TextEditingController()));
  }

  void _removeRequirement(int index) {
    if (_requirements.length <= 1) return;
    setState(() {
      _requirements[index].dispose();
      _requirements.removeAt(index);
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dueAt = picked);
    }
  }

  Assignment _buildAssignment({required AssessmentStatus status}) {
    final providerId =
        _lesson?.providerId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();
    final assignmentId = _existing?.id ??
        Assignment.defaultId(widget.lessonId, widget.moduleId);

    return Assignment(
      id: assignmentId,
      lessonId: widget.lessonId,
      moduleId: widget.moduleId,
      providerId: providerId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      requirements: _requirements
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      dueAt: _dueAt,
      maxPoints: int.tryParse(_maxPointsController.text.trim()) ?? 15,
      status: status,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _saveDraft() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ensureProviderId();
      final assignment = _buildAssignment(status: AssessmentStatus.draft);
      await ProviderAssignmentService.instance.saveAssignmentDraft(assignment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment saved as draft.')),
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
      final assignment = _buildAssignment(status: AssessmentStatus.draft);
      await ProviderAssignmentService.instance.saveAssignmentDraft(assignment);
      await ProviderAssignmentService.instance.publishAssignment(
        widget.lessonId,
        widget.moduleId,
        assignment.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment published.')),
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(title: 'Manage Assignment'),
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
                        'This assignment is published. Edits update the live assignment; existing submissions are preserved.',
                        style: TextStyle(color: AppTheme.statusDraftText),
                      ),
                    ),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Assignment title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Requirements',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      OutlinedButton.icon(
                        onPressed: _addRequirement,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_requirements.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _requirements[index],
                              decoration: InputDecoration(
                                labelText: 'Requirement ${index + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          if (_requirements.length > 1)
                            IconButton(
                              onPressed: () => _removeRequirement(index),
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: AppTheme.statusInactiveText,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _dueAt == null
                          ? 'Due date (optional)'
                          : 'Due: ${_dueAt!.toLocal().toString().split(' ').first}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_dueAt != null)
                          IconButton(
                            onPressed: () => setState(() => _dueAt = null),
                            icon: const Icon(Icons.clear),
                          ),
                        OutlinedButton(
                          onPressed: _pickDueDate,
                          child: const Text('Pick date'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _maxPointsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max points',
                      border: OutlineInputBorder(),
                    ),
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
                      child: const Text('Publish'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
