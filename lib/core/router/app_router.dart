import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/core/auth/app_auth.dart';
import 'package:peer_learn_hub/features/moderation/screens/moderator_guard_screen.dart';
import 'package:peer_learn_hub/features/learning/models/learning_course.dart';
import 'package:peer_learn_hub/features/learning/screens/learner_sessions_screen.dart';
import 'package:peer_learn_hub/features/learning/screens/learning_screens.dart';
import 'package:peer_learn_hub/features/learning/screens/session_feedback_screen.dart';
import 'package:peer_learn_hub/features/learning/screens/student_lesson_details_screen.dart';
import 'package:peer_learn_hub/features/notifications/screens/notifications_screen.dart';
import 'package:peer_learn_hub/features/learning/models/learning_quiz.dart';
import 'package:peer_learn_hub/features/learning/screens/assignment_screen.dart';
import 'package:peer_learn_hub/features/skill_exchange/skill_exchange.dart';
import 'package:peer_learn_hub/features/skill_provider/models/booking_request.dart';
import 'package:peer_learn_hub/features/skill_provider/models/provider_session.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/booking_details_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/booking_requests_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/create_lesson_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/edit_lesson_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/lesson_details_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/messages_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/my_lessons_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/ratings_reviews_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/reschedule_session_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/session_details_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/skill_provider_dashboard_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/teacher_profile_screen.dart';
import 'package:peer_learn_hub/features/skill_provider/screens/upcoming_sessions_screen.dart';
import 'package:peer_learn_hub/models/lesson.dart';
import 'package:peer_learn_hub/screens/forgot_password_screen.dart';
import 'package:peer_learn_hub/screens/loading_screen.dart';
import 'package:peer_learn_hub/screens/login_screen.dart';
import 'package:peer_learn_hub/screens/splash_screen.dart';
import 'package:peer_learn_hub/screens/moderator_register_screen.dart';
import 'package:peer_learn_hub/screens/otp_verification_screen.dart';
import 'package:peer_learn_hub/screens/profile_screen.dart';
import 'package:peer_learn_hub/screens/register_screen.dart';

class RouterClass {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: AppAuth.instance,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!AppAuth.instance.canAccess(location)) {
        return AppAuth.instance.getHomeRoute();
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/loading',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/moderation/register',
        builder: (context, state) => const ModeratorRegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) => OtpVerificationScreen(
          email: state.uri.queryParameters['email'],
          isPasswordReset: state.uri.queryParameters['mode'] == 'reset',
        ),
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
        path: '/learning/provider-lesson',
        builder: (context, state) {
          final lesson = state.extra;
          return lesson is Lesson
              ? StudentLessonDetailsScreen(lesson: lesson)
              : const DiscoverScreen();
        },
      ),
      GoRoute(
        path: '/learning/sessions',
        builder: (context, state) => const LearnerSessionsScreen(),
      ),
      GoRoute(
        path: '/learning/session-feedback',
        builder: (context, state) {
          final session = state.extra;
          return session is ProviderSession
              ? SessionFeedbackScreen(session: session)
              : const LearnerSessionsScreen();
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/learning/quiz',
        builder: (context, state) => {
          final quiz = state.extra;
          return quiz is LearningQuiz
              ? QuizScreen(quiz: quiz)
              : const MyLearningScreen();
        },
      ),
      GoRoute(
        path: '/learning/assignment',
        builder: (context, state) {
          final course = state.extra;
          return course is LearningCourse
              ? AssignmentScreen(course: course)
              : const MyLearningScreen();
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
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
        path: '/skill-provider/lesson',
        builder: (context, state) {
          final lesson = state.extra;
          return lesson is Lesson
              ? LessonDetailsScreen(lesson: lesson)
              : const SkillProviderDashboardScreen();
        },
      ),
      GoRoute(
        path: '/skill-provider/bookings',
        builder: (context, state) => const BookingRequestsScreen(),
      ),
      GoRoute(
        path: '/skill-provider/booking',
        builder: (context, state) {
          final booking = state.extra;
          return booking is BookingRequest
              ? BookingDetailsScreen(booking: booking)
              : const BookingRequestsScreen();
        },
      ),
      GoRoute(
        path: '/skill-provider/reschedule',
        builder: (context, state) {
          final booking = state.extra;
          return booking is BookingRequest
              ? RescheduleSessionScreen(booking: booking)
              : const BookingRequestsScreen();
        },
      ),
      GoRoute(
        path: '/skill-provider/messages',
        builder: (context, state) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/skill-provider/sessions',
        builder: (context, state) => const UpcomingSessionsScreen(),
      ),
      GoRoute(
        path: '/skill-provider/session',
        builder: (context, state) {
          final session = state.extra;
          return session is ProviderSession
              ? SessionDetailsScreen(session: session)
              : const UpcomingSessionsScreen();
        },
      ),
      GoRoute(
        path: '/skill-provider/reviews',
        builder: (context, state) => const RatingsReviewsScreen(),
      ),
      GoRoute(
        path: '/skill-provider/profile',
        builder: (context, state) => const TeacherProfileScreen(),
      ),
      GoRoute(
        path: '/moderation',
        builder: (context, state) => const ModeratorGuardScreen(),
      ),
    ],
  );
}