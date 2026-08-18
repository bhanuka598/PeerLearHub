import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/moderation/screens/moderator_dashboard_screen.dart';

void main() {
  runApp(const PeerLearnHubApp());
}

class PeerLearnHubApp extends StatelessWidget {
  const PeerLearnHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeerLearn Hub - Moderation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ModeratorDashboardScreen(),
    );
  }
}
