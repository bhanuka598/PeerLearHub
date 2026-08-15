import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/theme/app_spacing.dart';
import 'package:peer_learn_hub/widgets/section_title.dart';
import 'package:peer_learn_hub/widgets/interaction_button.dart';
import 'package:peer_learn_hub/widgets/interaction_button_invert.dart';
import 'package:peer_learn_hub/widgets/text_box.dart';
import 'package:peer_learn_hub/widgets/dropdown_menu.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SectionTitle(title: 'Register'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              TextBox(
                label: 'Full Name',
                controller: TextEditingController(),
              ),

              const SizedBox(height: AppSpacing.md),

              DropdownMenu(
                label: 'Role',
                options: ['Student', 'Teacher', 'Skill Exchange Member', 'Moderator'],
                selectedOption: null,
                onChanged: (String? newValue) {
                  // Handle role selection change
                },
              ),

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

              const SizedBox(height: AppSpacing.md),

              TextBox(
                label: 'Confirm Password',
                controller: TextEditingController(),
                obscureText: true,
              ),

              const SizedBox(height: AppSpacing.xl),

              InteractionButton(
                label: 'Register',
                onPressed: () {
                  // Navigate to the loading screen
                  context.go('/register');
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              InteractionButtonInvert(
                label: 'Login',
                onPressed: () {
                  // Navigate to the registration screen
                  context.go('/login');
                },
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}