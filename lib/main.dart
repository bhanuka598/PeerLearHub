import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const PeerLearHubApp());
}

class PeerLearHubApp extends StatelessWidget {
  const PeerLearHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.dashboard,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
