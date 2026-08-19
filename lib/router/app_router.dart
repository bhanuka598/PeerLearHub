import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/features/skill_exchange/skill_exchange.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/skill_provider_dashboard_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/create_lesson_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/edit_lesson_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/my_lessons_screen.dart';
import 'package:peer_learn_hub/features/moderation/screens/moderator_dashboard_screen.dart';
import 'package:peer_learn_hub/models/lesson.dart';
import 'package:peer_learn_hub/screens/loading_screen.dart';
import 'package:peer_learn_hub/screens/login_screen.dart';
import 'package:peer_learn_hub/screens/register_screen.dart';

class RouterClass {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Loading / Home Screen
      GoRoute(
        path: '/',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),

      // Login Screen
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Skill Exchange Feature
      GoRoute(
        path: '/skill-exchange',
        builder: (context, state) => const SkillExchangeDashboardScreen(),
      ),

      // Skill Provider Feature
      GoRoute(
        path: '/skill-provider',
        builder: (context, state) => const SkillProviderDashboardScreen(),
      ),
      GoRoute(
        path: '/skill-provider/my-lessons',
        builder: (context, state) => const MyLessonsScreen(),
      ),
      GoRoute(
        path: '/skill-provider/create',
        builder: (context, state) => const CreateLessonScreen(),
      ),
      GoRoute(
        path: '/skill-provider/edit',
        builder: (context, state) {
          final lesson = state.extra;
          return lesson is Lesson
              ? EditLessonScreen(lesson: lesson)
              : const SkillProviderDashboardScreen();
        },
      ),

      // Moderation and verification feature
      GoRoute(
        path: '/moderation',
        builder: (context, state) => const ModeratorDashboardScreen(),
      ),

      // Register Screen
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
}
