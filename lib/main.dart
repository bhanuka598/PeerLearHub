import 'package:flutter/material.dart';
import 'package:peer_learn_hub/screens/loading_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PeerLearnHub());
}

class PeerLearnHub extends StatelessWidget {
  const PeerLearnHub({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoadingScreen(),
    );
  }
}