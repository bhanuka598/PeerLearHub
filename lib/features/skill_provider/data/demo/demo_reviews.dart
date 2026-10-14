import '../../../../core/constants/app_constants.dart';
import '../../models/review.dart';

List<ProviderReview> createDemoReviews() {
  final now = DateTime.now();
  return [
    ProviderReview(
      id: 'review_1',
      providerId: AppConstants.demoProviderId,
      learnerName: 'Maria Garcia',
      lessonTitle: 'English Conversation Skills',
      rating: 5,
      comment: 'Excellent teacher! Very patient and helpful.',
      createdAt: now.subtract(const Duration(days: 5)),
      sessionId: 'session_3',
    ),
    ProviderReview(
      id: 'review_2',
      providerId: AppConstants.demoProviderId,
      learnerName: 'Tom Anderson',
      lessonTitle: 'Introduction to Flutter',
      rating: 4.5,
      comment: 'Great introduction to Flutter. Clear explanations.',
      createdAt: now.subtract(const Duration(days: 14)),
    ),
    ProviderReview(
      id: 'review_3',
      providerId: AppConstants.demoProviderId,
      learnerName: 'Lisa Chen',
      lessonTitle: 'Beginner Photography',
      rating: 5,
      comment: 'Learned so much about composition and lighting!',
      createdAt: now.subtract(const Duration(days: 21)),
    ),
  ];
}

ReviewSummary createDemoReviewSummary() {
  return const ReviewSummary(
    averageRating: 4.8,
    totalReviews: 12,
    completedSessions: 8,
  );
}
