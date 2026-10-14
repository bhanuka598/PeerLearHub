import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../screens/activity_log_screen.dart';
import '../screens/moderator_dashboard_screen.dart';
import '../screens/moderator_profile_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/verification_requests_screen.dart';

class ModeratorBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const ModeratorBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    if (index == currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const ModeratorDashboardScreen();
        break;
      case 1:
        destination = const VerificationRequestsScreen();
        break;
      case 2:
        destination = const ReportsScreen();
        break;
      case 3:
        destination = const ActivityLogScreen();
        break;
      case 4:
        destination = const ModeratorProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primaryTeal,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) => _handleTap(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_user),
          label: 'Verify',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.flag),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Activity',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
