import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../../../models/lesson.dart';
import 'status_chip.dart';

class RecentLessonTile extends StatelessWidget {
  const RecentLessonTile({
    super.key,
    required this.lesson,
    this.onEdit,
  });

  final Lesson lesson;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/skill-provider/lesson', extra: lesson),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              _thumb(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lesson.category.label} · ${lesson.duration}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(status: lesson.status),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onEdit ??
                    () => context.push('/skill-provider/edit', extra: lesson),
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppTheme.primaryColor,
                tooltip: 'Edit',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb() {
    final url = lesson.imageUrl?.trim();
    final hasImage = url != null &&
        url.isNotEmpty &&
        !url.contains('placeholder.peerlearnhub.com');

    Widget image;
    if (hasImage && url.startsWith('data:image/')) {
      final data = Uri.tryParse(url)?.data;
      image = data != null
          ? Image.memory(
              data.contentAsBytes(),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          : _placeholder();
    } else if (hasImage && url.startsWith('http')) {
      image = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      image = _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: 52, height: 52, child: image),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppTheme.iconBackground,
      child: Center(
        child: Text(
          lesson.title.isNotEmpty ? lesson.title[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
