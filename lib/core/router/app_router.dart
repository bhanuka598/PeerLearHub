import 'package:flutter/material.dart';

import '../../features/skill_provider/screens/create_lesson_screen.dart';
import '../../features/skill_provider/screens/edit_lesson_screen.dart';
import '../../features/skill_provider/screens/my_lessons_screen.dart';
import '../../features/skill_provider/screens/skill_provider_dashboard_screen.dart';
import '../../models/lesson.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.dashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SkillProviderDashboardScreen(),
        );
      case AppRoutes.myLessons:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MyLessonsScreen(),
        );
      case AppRoutes.createLesson:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CreateLessonScreen(),
        );
      case AppRoutes.editLesson:
        final lesson = settings.arguments as Lesson?;
        if (lesson == null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SkillProviderDashboardScreen(),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => EditLessonScreen(lesson: lesson),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SkillProviderDashboardScreen(),
        );
    }
  }
}
