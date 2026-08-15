import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/theme/app_spacing.dart';
import 'package:peer_learn_hub/widgets/section_title.dart';
import 'package:peer_learn_hub/widgets/interaction_button.dart';
import 'package:peer_learn_hub/widgets/interaction_button_invert.dart';
import 'package:peer_learn_hub/widgets/text_box.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SectionTitle(title: 'Login'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.md),

            TextBox(
              label: 'Username',
              controller: TextEditingController(),
            ),

            const SizedBox(height: AppSpacing.md),

            TextBox(
              label: 'Password',
              controller: TextEditingController(),
              obscureText: true,
            ),

            const SizedBox(height: AppSpacing.xl),

            InteractionButton(
              label: 'Login',
              onPressed: () {
                // Navigate to the loading screen
                context.go('/loading');
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            InteractionButtonInvert(
              label: 'Register',
              onPressed: () {
                // Navigate to the registration screen
                context.go('/register');
              },
            ),
          ],
        ),
      ),
    );
  }
}