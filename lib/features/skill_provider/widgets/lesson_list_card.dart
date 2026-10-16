import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../../../models/lesson.dart';
import 'status_chip.dart';

class LessonListCard extends StatelessWidget {
  const LessonListCard({
    super.key,
    required this.lesson,
    required this.onEdit,
    required this.onDelete,
    this.onView,
  });

  final Lesson lesson;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.teacherCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          return Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, compact ? 10 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.teacherHeaderGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        lesson.title.isNotEmpty
                            ? lesson.title[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  height: 1.25,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDate(lesson.createdAt),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(status: lesson.status),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MetaPill(
                      icon: Icons.menu_book_outlined,
                      label: lesson.category.label,
                    ),
                    _MetaPill(
                      icon: Icons.bar_chart_rounded,
                      label: lesson.skillLevel.label,
                    ),
                    _MetaPill(
                      icon: Icons.schedule_rounded,
                      label: lesson.duration,
                    ),
                    _MetaPill(
                      icon: Icons.sell_outlined,
                      label: formatLessonPrice(lesson),
                    ),
                  ],
                ),
                if (lesson.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    lesson.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                _LessonActions(
                  compact: compact,
                  onView: onView ??
                      () => context.push(
                            '/skill-provider/lesson',
                            extra: lesson,
                          ),
                  onManage: () => context.push(
                    '/skill-provider/lesson/${lesson.id}/manage',
                    extra: lesson,
                  ),
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.iconBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _LessonActions extends StatelessWidget {
  const _LessonActions({
    required this.compact,
    required this.onView,
    required this.onManage,
    required this.onEdit,
    required this.onDelete,
  });

  final bool compact;
  final VoidCallback onView;
  final VoidCallback onManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionSpec(
        icon: Icons.visibility_outlined,
        label: 'View',
        onTap: onView,
        color: AppTheme.primaryColor,
      ),
      _ActionSpec(
        icon: Icons.settings_outlined,
        label: 'Manage',
        onTap: onManage,
        color: AppTheme.primaryColor,
      ),
      _ActionSpec(
        icon: Icons.edit_outlined,
        label: 'Edit',
        onTap: onEdit,
        color: AppTheme.primaryColor,
      ),
      _ActionSpec(
        icon: Icons.delete_outline,
        label: 'Delete',
        onTap: onDelete,
        color: AppTheme.statusInactiveText,
      ),
    ];

    if (!compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (final action in actions)
            TextButton.icon(
              onPressed: action.onTap,
              icon: Icon(action.icon, size: 18, color: action.color),
              label: Text(action.label),
              style: TextButton.styleFrom(
                foregroundColor: action.color,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3EEEC)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 28,
                color: const Color(0xFFE3EEEC),
              ),
            Expanded(child: _CompactAction(action: actions[i])),
          ],
        ],
      ),
    );
  }
}

class _ActionSpec {
  const _ActionSpec({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
}

class _CompactAction extends StatelessWidget {
  const _CompactAction({required this.action});

  final _ActionSpec action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 18, color: action.color),
            const SizedBox(height: 2),
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: action.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
