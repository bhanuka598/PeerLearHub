import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/core/auth/app_auth.dart';
import 'package:peer_learn_hub/core/theme/app_spacing.dart';
import 'package:peer_learn_hub/widgets/section_title.dart';
import 'package:peer_learn_hub/widgets/interaction_button.dart';
import 'package:peer_learn_hub/widgets/interaction_button_invert.dart';
import 'package:peer_learn_hub/widgets/text_box.dart';
import 'package:peer_learn_hub/widgets/dropdown_menu.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _selectedRole = 'Student';

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
                options: ['Student', 'Teacher', 'Admin'],
                selectedOption: _selectedRole,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedRole = newValue);
                  }
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
                  final role = _selectedRole;
                  if (role.toLowerCase().contains('admin')) {
                    AppAuth.instance.setRole(AppUserRole.admin);
                  } else if (role.toLowerCase().contains('teacher')) {
                    AppAuth.instance.setRole(AppUserRole.teacher);
                  } else {
                    AppAuth.instance.setRole(AppUserRole.student);
                  }

                  context.go(AppAuth.instance.getHomeRoute());
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
