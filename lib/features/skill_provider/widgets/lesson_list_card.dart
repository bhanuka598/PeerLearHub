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
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.iconBackground,
                  child: Text(
                    lesson.title.isNotEmpty
                        ? lesson.title[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
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
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatDate(lesson.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: lesson.status),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Category: ${lesson.category.label}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Level: ${lesson.skillLevel.label} · ${lesson.duration} · ${formatLessonPrice(lesson)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
            ),
            if (lesson.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                lesson.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onView ??
                      () => context.push('/skill-provider/lesson',
                          extra: lesson),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppTheme.statusInactiveText,
                  ),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.statusInactiveText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
