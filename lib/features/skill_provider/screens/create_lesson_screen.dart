import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/lesson.dart';
import '../services/firebase_lesson_service.dart';
import '../utils/provider_id_helper.dart';
import '../widgets/app_header.dart';
import '../widgets/lesson_form.dart';

class CreateLessonScreen extends StatefulWidget {
  const CreateLessonScreen({super.key});

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _lessonService = FirebaseLessonService.instance;
  final _formKey = GlobalKey<LessonFormState>();

  Future<void> _saveLesson(LessonFormData data, {required bool publish}) async {
    final formState = _formKey.currentState!;
    final providerId = await ensureProviderId();
    final lesson = formState.buildLessonFromFormData(
      data,
      providerId: providerId,
      status: publish ? LessonStatus.active : LessonStatus.draft,
    );

    try {
      await _lessonService.createLesson(lesson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError
                  ? e.message
                  : 'Could not save lesson. Please sign in and try again.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      final usedFallback = _lessonService.lastSaveUsedFallback;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            usedFallback
                ? 'Saved, but the lessons collection is not writable yet. '
                    'Publish the Firestore rules for /lessons.'
                : publish
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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: LessonForm(
              key: _formKey,
              onCancel: () => Navigator.of(context).pop(),
              onSaveDraft: (data) => _saveLesson(data, publish: false),
              onPublish: (data) => _saveLesson(data, publish: true),
            ),
          ),
        ),
      ),
    );
  }
}
