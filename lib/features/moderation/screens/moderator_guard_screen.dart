import 'package:flutter/material.dart';
import 'package:peer_learn_hub/core/auth/auth_service.dart';
import 'moderator_dashboard_screen.dart';

class ModeratorGuardScreen extends StatefulWidget {
  const ModeratorGuardScreen({super.key});

  @override
  State<ModeratorGuardScreen> createState() => _ModeratorGuardScreenState();
}

class _ModeratorGuardScreenState extends State<ModeratorGuardScreen> {
  bool _isLoading = true;
  bool _isModerator = false;

  @override
  void initState() {
    super.initState();
    _checkModeratorStatus();
  }

  Future<void> _checkModeratorStatus() async {
    final isModerator = await AuthService.instance.isModerator();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isModerator = isModerator;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isModerator) {
      return const ModeratorDashboardScreen();
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You do not have permission to access this page.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Only users with moderator role can access the moderation dashboard.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
