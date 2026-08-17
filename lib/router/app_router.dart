import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/features/skill_exchange/skill_exchange.dart';
import 'package:peer_learn_hub/screens/loading_screen.dart';
import 'package:peer_learn_hub/screens/login_screen.dart';

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
    ],
  );
}