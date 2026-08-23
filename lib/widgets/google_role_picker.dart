import 'package:flutter/material.dart';
import 'package:peer_learn_hub/core/auth/app_auth.dart';

class GoogleRolePicker {
  const GoogleRolePicker._();

  static Future<AppUserRole?> show(BuildContext context) {
    return showDialog<AppUserRole>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Choose your PeerLearnHub role'),
        content: const Text('Select how you want to use PeerLearnHub.'),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actions: [
          _RoleOption(
            role: AppUserRole.student,
            icon: Icons.school_outlined,
            label: 'Student',
            description: 'Learn skills and join courses',
          ),
          _RoleOption(
            role: AppUserRole.teacher,
            icon: Icons.co_present_outlined,
            label: 'Teacher',
            description: 'Share skills and manage lessons',
          ),
          _RoleOption(
            role: AppUserRole.admin,
            icon: Icons.admin_panel_settings_outlined,
            label: 'Admin',
            description: 'Moderate the community',
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.icon,
    required this.label,
    required this.description,
  });

  final AppUserRole role;
  final IconData icon;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(description),
      contentPadding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).pop(role),
    );
  }
}
