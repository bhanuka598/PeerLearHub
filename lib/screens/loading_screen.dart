import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/app_auth.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.hub_outlined,
                  size: 64,
                  color: Color(0xFF0F766E),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to\nPeer Learn Hub',
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F766E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Community Skill-Exchange & Micro-Learning Platform',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                _HubButton(
                  label: 'Login',
                  icon: Icons.login,
                  filled: true,
                  onPressed: () => context.go('/login'),
                ),
                const SizedBox(height: 14),
                _HubButton(
                  label: 'Register',
                  icon: Icons.person_add_outlined,
                  onPressed: () => context.go('/register'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Demo roles',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _RoleDemoButton(
                      label: 'Student',
                      onPressed: () {
                        AppAuth.instance.setRole(AppUserRole.student);
                        context.go(AppAuth.instance.getHomeRoute());
                      },
                    ),
                    _RoleDemoButton(
                      label: 'Teacher',
                      onPressed: () {
                        AppAuth.instance.setRole(AppUserRole.teacher);
                        context.go(AppAuth.instance.getHomeRoute());
                      },
                    ),
                    _RoleDemoButton(
                      label: 'Admin',
                      onPressed: () {
                        AppAuth.instance.setRole(AppUserRole.admin);
                        context.go(AppAuth.instance.getHomeRoute());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleDemoButton extends StatelessWidget {
  const _RoleDemoButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(label),
    );
  }
}

class _HubButton extends StatelessWidget {
  const _HubButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF0F766E);
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: teal,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return SizedBox(
      width: 280,
      child: filled
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: buttonStyle,
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: teal,
                side: const BorderSide(color: teal),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}
