import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../models/review.dart';
import 'rating_stars.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.index = 0});

  final ProviderReview review;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 18, end: 0),
      duration: Duration(milliseconds: 420 + (index * 70).clamp(0, 420)),
      curve: Curves.easeOutCubic,
      builder: (context, dy, child) {
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: _card(context),
    );
  }

  Widget _card(BuildContext context) {
    final comment = review.comment.trim();
    final initial = review.learnerName.isNotEmpty
        ? review.learnerName[0].toUpperCase()
        : 'S';
    final accent = _accentFor(review.learnerName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.teacherCardDecoration,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withValues(alpha: 0.14),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.learnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.lessonTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RatingStars(value: review.rating, size: 16),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comment,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                formatDate(review.createdAt),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                review.rating.toStringAsFixed(
                  review.rating == review.rating.roundToDouble() ? 0 : 1,
                ),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _accentFor(String name) {
    const colors = [
      AppTheme.teacherAccentViolet,
      AppTheme.primaryColor,
      AppTheme.teacherAccentIndigo,
      AppTheme.teacherAccentSky,
      AppTheme.teacherAccentEmerald,
    ];
    if (name.isEmpty) return colors.first;
    return colors[name.codeUnits.fold<int>(0, (a, b) => a + b) % colors.length];
  }
}
