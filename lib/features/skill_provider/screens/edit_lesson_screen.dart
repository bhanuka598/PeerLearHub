import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/lesson.dart';
import '../../../services/lesson_service.dart';
import '../widgets/app_header.dart';
import '../widgets/lesson_form.dart';

class EditLessonScreen extends StatefulWidget {
  const EditLessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<EditLessonScreen> createState() => _EditLessonScreenState();
}

class _EditLessonScreenState extends State<EditLessonScreen> {
  final _lessonService = DemoLessonService.instance;
  final _formKey = GlobalKey<LessonFormState>();

  Future<void> _updateLesson(LessonFormData data) async {
    final formState = _formKey.currentState!;
    final updatedLesson = formState.buildLessonFromFormData(
      data,
      id: widget.lesson.id,
      providerId: widget.lesson.providerId,
      status: widget.lesson.status,
      createdAt: widget.lesson.createdAt,
    );

    await _lessonService.updateLesson(updatedLesson);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson updated successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(
        title: 'Edit Lesson',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(20),
              child: LessonForm(
                key: _formKey,
                initialLesson: widget.lesson,
                showPublishButton: false,
                saveButtonLabel: 'Save Changes',
                onCancel: () => Navigator.of(context).pop(),
                onSaveDraft: _updateLesson,
                onPublish: _updateLesson,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
