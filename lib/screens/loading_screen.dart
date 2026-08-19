import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                  label: 'Open Skill Exchange Hub',
                  icon: Icons.swap_horiz_rounded,
                  filled: true,
                  onPressed: () => context.go('/skill-exchange'),
                ),
                const SizedBox(height: 14),
                _HubButton(
                  label: 'Open Skill Provider Hub',
                  icon: Icons.school_outlined,
                  onPressed: () => context.go('/skill-provider'),
                ),
                const SizedBox(height: 14),
                _HubButton(
                  label: 'Open Moderation Hub',
                  icon: Icons.verified_user_outlined,
                  onPressed: () => context.go('/moderation'),
                ),
                const SizedBox(height: 14),
                _HubButton(
                  label: 'Go to Login',
                  icon: Icons.login,
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      ),
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
