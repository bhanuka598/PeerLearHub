import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:peer_learn_hub/core/router/app_router.dart';
import 'package:peer_learn_hub/core/theme/app_theme.dart';
import 'package:peer_learn_hub/features/skill_provider/services/session_automation_service.dart';
import 'package:peer_learn_hub/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError catch (_) {
    // The UI can run while platform-specific Firebase configuration is added.
  }

  SessionAutomationService.instance.start();
  runApp(const PeerLearnHub());
}

class PeerLearnHub extends StatelessWidget {
  const PeerLearnHub({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'PeerLearnHub',
      theme: AppTheme.lightTheme,
      routerConfig: RouterClass.router,
    );
  }
}
