import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/app_auth.dart';
import '../theme/app_theme.dart';

/// A role-switcher widget that lives in an AppBar''s actions list.
///
/// Uses [ListenableBuilder] on [AppAuth.instance] so it always reflects the
/// current role and rebuilds instantly when the role changes.
///
/// Tapping it opens a popup menu with "Student" and "Teacher" options.
/// Selecting a role calls [AppAuth.instance.switchRole] and navigates to
/// the appropriate home route.
class RoleSwitcherButton extends StatelessWidget {
  const RoleSwitcherButton({super.key, this.onDark = false});

  /// Set [true] when the button sits on a dark/teal background so colours
  /// adapt (white text/border instead of primary-colour).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppAuth.instance,
      builder: (context, _) {
        final role = AppAuth.instance.currentRole;
        final isStudent = role == AppUserRole.student;
        final isTeacher = role == AppUserRole.teacher;
        final label = isTeacher ? 'TEACHER' : 'STUDENT';

        return SizedBox(
          width: 136,
          height: kToolbarHeight,
          child: PopupMenuButton<AppUserRole>(
            tooltip: 'Switch role',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            onSelected: (newRole) {
              AppAuth.instance.switchRole(newRole);
              context.go(AppAuth.instance.getHomeRoute());
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<AppUserRole>(
                value: AppUserRole.student,
                child: _RoleItem(
                  icon: Icons.school_outlined,
                  label: 'Student',
                  active: isStudent,
                ),
              ),
              PopupMenuItem<AppUserRole>(
                value: AppUserRole.teacher,
                child: _RoleItem(
                  icon: Icons.cast_for_education_outlined,
                  label: 'Teacher',
                  active: isTeacher,
                ),
              ),
            ],
            child: Align(
              alignment: Alignment.center,
              child: Container(
                height: 32,
                width: 128,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: onDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isStudent
                          ? Icons.school_outlined
                          : Icons.cast_for_education_outlined,
                      size: 15,
                      color: onDark ? Colors.white : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: onDark ? Colors.white : AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 17,
                      color: onDark ? Colors.white : AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoleItem extends StatelessWidget {
  const _RoleItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: active ? AppTheme.primaryColor : null),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              color: active ? AppTheme.primaryColor : null,
            ),
          ),
        ),
        if (active)
          const Icon(Icons.check, size: 16, color: AppTheme.primaryColor),
      ],
    );
  }
}
