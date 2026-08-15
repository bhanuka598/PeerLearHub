import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/screens/loading_screen.dart';
import 'package:peer_learn_hub/screens/login_screen.dart';

class RouterClass {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Loading Screen
      GoRoute(
        path: '/',
        builder: (context, state) => const LoadingScreen(),
      ),

      // Login Screen
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
}