import 'package:flutter/material.dart';
import '../models/skill_exchange_models.dart';

class CourseCard extends StatelessWidget {
  final ExchangeCourse course;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showOwner;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.trailing,
    this.showOwner = true,
  });

  Color _getLevelColor(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return const Color(0xFF10B981);
      case SkillLevel.intermediate:
        return const Color(0xFFF59E0B);
      case SkillLevel.advanced:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.teal.shade800,
                  child: Image.network(
                    course.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.teal.shade700,
                      child: const Center(
                        child: Icon(Icons.school, size: 48, color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getLevelColor(course.level),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.level.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: course.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.teal.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (showOwner) ...[
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(course.ownerAvatar),
                          onBackgroundImageError: (_, __) {},
                          child: const Icon(Icons.person, size: 14),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            course.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.menu_book, size: 14, color: Colors.teal),
                        const SizedBox(width: 4),
                        Text(
                          '${course.totalLessons} Lessons • ${course.durationMinutes} mins',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const Spacer(),
                      ],
                      if (trailing != null) trailing!,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
