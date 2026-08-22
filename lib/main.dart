import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:peer_learn_hub/core/router/app_router.dart';
import 'package:peer_learn_hub/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase config is required for Google auth to work on Android/iOS.
  }

  runApp(const PeerLearnHub());
}

class PeerLearnHub extends StatelessWidget {
  const PeerLearnHub({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Peer Learn Hub',
      theme: AppTheme.lightTheme,
      routerConfig: RouterClass.router,
    );
  }
}
