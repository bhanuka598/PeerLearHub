import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/screens/loading_screen.dart';

class RouterClass {
  final router = GoRouter(
    routes: [
      // Login Screen
      GoRoute(
        path: '/',
        builder: (context, state) {
          return const LoadingScreen();
        },
      ),
    ],
  );
}