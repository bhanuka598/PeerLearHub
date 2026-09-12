import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../../../core/utils/lesson_image.dart';
import '../../../models/lesson.dart';
import '../widgets/app_header.dart';
import '../widgets/status_chip.dart';

class LessonDetailsScreen extends StatelessWidget {
  const LessonDetailsScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(title: 'Lesson Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(context),
                const SizedBox(height: 16),
                _buildSectionCard(
                  context,
                  icon: Icons.info_outline,
                  title: 'About this lesson',
                  child: Text(
                    lesson.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  context,
                  icon: Icons.tune_outlined,
                  title: 'Lesson information',
                  child: Column(
                    children: [
                      _infoTile(
                        Icons.category_outlined,
                        'Category',
                        lesson.category.label,
                      ),
                      _infoTile(
                        Icons.signal_cellular_alt,
                        'Skill Level',
                        lesson.skillLevel.label,
                      ),
                      _infoTile(
                        Icons.schedule_outlined,
                        'Duration',
                        lesson.duration,
                      ),
                      _infoTile(
                        Icons.videocam_outlined,
                        'Lesson Type',
                        lesson.lessonType.label,
                      ),
                      _infoTile(
                        Icons.swap_horiz,
                        'Exchange Type',
                        lesson.exchangeType.label,
                      ),
                      _infoTile(
                        Icons.payments_outlined,
                        'Price',
                        formatLessonPrice(lesson),
                      ),
                      _infoTile(
                        Icons.place_outlined,
                        'Location',
                        lesson.location,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  context,
                  icon: Icons.calendar_month_outlined,
                  title: 'Availability',
                  child: Column(
                    children: [
                      _infoTile(
                        Icons.event_available_outlined,
                        'Available Days',
                        lesson.availability.availableDays.join(', '),
                      ),
                      _infoTile(
                        Icons.access_time,
                        'Preferred Time',
                        lesson.availability.preferredTime,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                if (lesson.learningOutcomes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    icon: Icons.flag_outlined,
                    title: 'Learning outcomes',
                    child: Column(
                      children: lesson.learningOutcomes
                          .map(_bulletRow)
                          .toList(),
                    ),
                  ),
                ],
                if (lesson.learningMaterials.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    icon: Icons.folder_open_outlined,
                    title: 'Learning materials',
                    child: Column(
                      children: lesson.learningMaterials.map((material) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.iconBackground,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.attach_file,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  material,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/skill-provider/edit', extra: lesson),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Lesson'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildThumbnail(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x99000000)],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: StatusChip(status: lesson.status),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    LessonMetaChip(
                      icon: Icons.category_outlined,
                      label: lesson.category.label,
                    ),
                    LessonMetaChip(
                      icon: Icons.signal_cellular_alt,
                      label: lesson.skillLevel.label,
                    ),
                    LessonMetaChip(
                      icon: Icons.schedule_outlined,
                      label: lesson.duration,
                    ),
                    LessonMetaChip(
                      icon: Icons.payments_outlined,
                      label: formatLessonPrice(lesson),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final image = lessonImageProvider(lesson.imageUrl);
    if (image == null) return _thumbnailPlaceholder();

    return Image(
      image: image,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => _thumbnailPlaceholder(),
    );
  }

  Widget _thumbnailPlaceholder() {
    return ColoredBox(
      color: AppTheme.iconBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 40,
              color: AppTheme.primaryColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            const Text(
              'No thumbnail added',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 7, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
