import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/lesson.dart';
import '../../../services/lesson_service.dart';
import '../widgets/app_header.dart';
import '../widgets/lesson_form.dart';

class CreateLessonScreen extends StatefulWidget {
  const CreateLessonScreen({super.key});

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _lessonService = DemoLessonService.instance;
  final _formKey = GlobalKey<LessonFormState>();

  Future<void> _saveLesson(LessonFormData data, {required bool publish}) async {
    final formState = _formKey.currentState!;
    final lesson = formState.buildLessonFromFormData(
      data,
      providerId: AppConstants.demoProviderId,
      status: publish ? LessonStatus.active : LessonStatus.draft,
    );

    await _lessonService.createLesson(lesson);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            publish
                ? 'Lesson published successfully!'
                : 'Lesson saved as draft.',
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
        title: 'Create Lesson',
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
                onCancel: () => Navigator.of(context).pop(),
                onSaveDraft: (data) => _saveLesson(data, publish: false),
                onPublish: (data) => _saveLesson(data, publish: true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
