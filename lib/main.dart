import 'package:flutter/material.dart';
import 'package:peer_learn_hub/router/app_router.dart';
import 'package:peer_learn_hub/theme/app_theme.dart';

void main() {
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
