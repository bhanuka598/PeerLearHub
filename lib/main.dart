import 'package:flutter/material.dart';
import 'package:peer_learn_hub/core/theme/app_theme.dart';
import 'package:peer_learn_hub/core/router/app_router.dart';

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
