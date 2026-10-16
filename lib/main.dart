import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:peer_learn_hub/core/auth/welcome_store.dart';
import 'package:peer_learn_hub/core/router/app_router.dart';
import 'package:peer_learn_hub/core/theme/app_theme.dart';
import 'package:peer_learn_hub/features/notifications/services/session_reminder_scheduler.dart';
import 'package:peer_learn_hub/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WelcomeStore.load();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization error: $error\n$stackTrace');
  }

  try {
    await SessionReminderScheduler.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('Reminder scheduler initialization error: $error\n$stackTrace');
  }

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
