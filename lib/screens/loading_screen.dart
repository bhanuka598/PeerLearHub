import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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

              // Feature: Skill Exchange Hub Button
              FilledButton.icon(
                onPressed: () {
                  context.go('/skill-exchange');
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text(
                  'Open Skill Exchange Hub',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: () {
                  context.go('/skill-provider');
                },
                icon: const Icon(Icons.school_outlined),
                label: const Text('Open Skill Provider Hub'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF0F766E)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: () {
                  context.go('/moderation');
                },
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Open Moderation Hub'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF0F766E)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Secondary: Go to Login
              OutlinedButton.icon(
                onPressed: () {
                  context.go('/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Go to Login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF0F766E)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
