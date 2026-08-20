import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/core/auth/app_auth.dart';
import 'package:peer_learn_hub/features/moderation/screens/moderator_dashboard_screen.dart';
import 'package:peer_learn_hub/features/learning/models/learning_course.dart';
import 'package:peer_learn_hub/features/learning/screens/learning_screens.dart';
import 'package:peer_learn_hub/features/skill_exchange/skill_exchange.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/create_lesson_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/edit_lesson_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/my_lessons_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/skill_provider_dashboard_screen.dart';
import 'package:peer_learn_hub/models/lesson.dart';
import 'package:peer_learn_hub/screens/loading_screen.dart';
import 'package:peer_learn_hub/screens/login_screen.dart';
import 'package:peer_learn_hub/screens/register_screen.dart';

class RouterClass {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!AppAuth.instance.canAccess(location)) {
        return AppAuth.instance.getHomeRoute();
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoadingScreen()),
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/skill-exchange',
        builder: (context, state) => const SkillExchangeDashboardScreen(),
      ),
      GoRoute(
        path: '/learning',
        builder: (context, state) => const DiscoverScreen(),
      ),
      GoRoute(
        path: '/learning/my-courses',
        builder: (context, state) => const MyLearningScreen(),
      ),
      GoRoute(
        path: '/learning/course',
        builder: (context, state) {
          final course = state.extra;
          return course is LearningCourse
              ? CourseDetailsScreen(course: course)
              : const DiscoverScreen();
        },
      ),
      GoRoute(
        path: '/learning/lesson',
        builder: (context, state) {
          final course = state.extra;
          return course is LearningCourse
              ? LessonViewScreen(course: course)
              : const MyLearningScreen();
        },
      ),
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
      GoRoute(
        path: '/moderation',
        builder: (context, state) => const ModeratorDashboardScreen(),
      ),
    ],
  );
}
