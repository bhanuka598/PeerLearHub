import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/widgets/section_title.dart';
import 'package:peer_learn_hub/widgets/interaction_button.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SectionTitle(title: 'Welcome to \nPeer Learn Hub', center: true),
            const SizedBox(height: 16),
            InteractionButton(
              label: 'Go to Login',
              onPressed: () {
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}