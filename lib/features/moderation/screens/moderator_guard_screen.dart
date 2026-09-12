import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'moderator_dashboard_screen.dart';

class ModeratorGuardScreen extends StatefulWidget {
  const ModeratorGuardScreen({super.key});

  @override
  State<ModeratorGuardScreen> createState() => _ModeratorGuardScreenState();
}

class _ModeratorGuardScreenState extends State<ModeratorGuardScreen> {
  final ModeratorAuthService _authService = ModeratorAuthService();
  bool _isLoading = true;
  bool _isModerator = false;

  @override
  void initState() {
    super.initState();
    _checkModeratorAccess();
  }

  Future<void> _checkModeratorAccess() async {
    final isModerator = await _authService.isCurrentUserModerator();
    setState(() {
      _isModerator = isModerator;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isModerator) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.red[300],
              ),
              const SizedBox(height: 24),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You must be a moderator to access this area.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const ModeratorDashboardScreen();
  }
}
