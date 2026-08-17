import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 72,
                color: Color(0xFF0F766E),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  // Navigate to the Skill Exchange Dashboard
                  context.go('/skill-exchange');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: const Text('Login to Skill Exchange Hub', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  context.go('/');
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}