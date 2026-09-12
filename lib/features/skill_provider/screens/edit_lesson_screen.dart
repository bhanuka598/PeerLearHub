import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/lesson.dart';
import '../services/firebase_lesson_service.dart';
import '../widgets/app_header.dart';
import '../widgets/lesson_form.dart';

class EditLessonScreen extends StatefulWidget {
  const EditLessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<EditLessonScreen> createState() => _EditLessonScreenState();
}

class _EditLessonScreenState extends State<EditLessonScreen> {
  final _lessonService = FirebaseLessonService.instance;
  final _formKey = GlobalKey<LessonFormState>();

  Future<void> _updateLesson(LessonFormData data) async {
    final formState = _formKey.currentState!;
    final updatedLesson = formState.buildLessonFromFormData(
      data,
      id: widget.lesson.id,
      providerId: widget.lesson.providerId,
      status: data.publishAsActive ? LessonStatus.active : widget.lesson.status,
      createdAt: widget.lesson.createdAt,
    );

    try {
      await _lessonService.updateLesson(updatedLesson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update lesson in Firebase. Please sign in and try again.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data.publishAsActive
                ? 'Lesson published successfully!'
                : 'Draft updated successfully!',
          ),
        ),
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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: LessonForm(
              key: _formKey,
              initialLesson: widget.lesson,
              showPublishButton: widget.lesson.status == LessonStatus.draft,
              saveButtonLabel: widget.lesson.status == LessonStatus.draft
                  ? 'Save as Draft'
                  : 'Save Changes',
              onCancel: () => Navigator.of(context).pop(),
              onSaveDraft: _updateLesson,
              onPublish: _updateLesson,
            ),
          ),
        ),
      ),
    );
  }
}
