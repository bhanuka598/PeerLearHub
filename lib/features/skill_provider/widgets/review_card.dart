import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../models/review.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final ProviderReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.iconBackground,
                child: Text(
                    review.learnerName.isNotEmpty
                        ? review.learnerName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(color: AppTheme.primaryColor)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.learnerName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(review.lessonTitle,
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  Text(' ${review.rating}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment),
          const SizedBox(height: 8),
          Text(formatDate(review.createdAt),
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
