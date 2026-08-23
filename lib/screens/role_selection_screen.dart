import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/core/auth/app_auth.dart';
import 'package:peer_learn_hub/core/auth/auth_service.dart';
import 'package:peer_learn_hub/core/theme/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  AppUserRole? _selectedRole;
  bool _isSaving = false;

  Future<void> _saveRole() async {
    final selectedRole = _selectedRole;
    if (selectedRole == null || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    final saved = await AppAuth.instance.saveGoogleRole(selectedRole);

    if (!mounted) {
      return;
    }

    if (saved) {
      context.go(AppAuth.instance.getHomeRoute());
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthService.instance.lastError ??
                'Unable to save your role. Please try again.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your role',
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select how you want to use PeerLearnHub. This choice is saved to your account.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _RoleCard(
                    role: AppUserRole.student,
                    icon: Icons.school_outlined,
                    title: 'Student',
                    description: 'Discover courses and learn new skills.',
                    selected: _selectedRole == AppUserRole.student,
                    onTap: () =>
                        setState(() => _selectedRole = AppUserRole.student),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    role: AppUserRole.teacher,
                    icon: Icons.co_present_outlined,
                    title: 'Teacher',
                    description: 'Share your knowledge and manage lessons.',
                    selected: _selectedRole == AppUserRole.teacher,
                    onTap: () =>
                        setState(() => _selectedRole = AppUserRole.teacher),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    role: AppUserRole.admin,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin',
                    description:
                        'Moderate users, reports, and community safety.',
                    selected: _selectedRole == AppUserRole.admin,
                    onTap: () =>
                        setState(() => _selectedRole = AppUserRole.admin),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selectedRole == null || _isSaving
                          ? null
                          : _saveRole,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save & Continue',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final AppUserRole role;
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Radio<AppUserRole>(
              value: role,
              groupValue: selected ? role : null,
              onChanged: (_) => onTap(),
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
