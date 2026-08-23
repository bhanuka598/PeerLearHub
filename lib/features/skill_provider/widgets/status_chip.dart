import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../../../models/lesson.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final LessonStatus status;

  (Color bg, Color text) get _colors {
    switch (status) {
      case LessonStatus.active:
        return (AppTheme.statusActiveBg, AppTheme.statusActiveText);
      case LessonStatus.draft:
        return (AppTheme.statusDraftBg, AppTheme.statusDraftText);
      case LessonStatus.inactive:
        return (AppTheme.statusInactiveBg, AppTheme.statusInactiveText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, text) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: text,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class LessonMetaChip extends StatelessWidget {
  const LessonMetaChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
