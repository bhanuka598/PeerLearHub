import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../utils/provider_id_helper.dart';
import '../widgets/app_header.dart';
import '../widgets/rating_stars.dart';
import '../widgets/review_card.dart';

class RatingsReviewsScreen extends StatefulWidget {
  const RatingsReviewsScreen({super.key});

  @override
  State<RatingsReviewsScreen> createState() => _RatingsReviewsScreenState();
}

class _RatingsReviewsScreenState extends State<RatingsReviewsScreen> {
  final _service = ReviewService.instance;
  List<ProviderReview> _reviews = [];
  ReviewSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _service.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final providerId = await resolveProviderId();
    final reviews = await _service.getReviews(providerId);
    final summary = await _service.getReviewSummary(providerId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _summary = summary;
        _loading = false;
      });
    }
  }

  Map<int, int> get _distribution {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in _reviews) {
      final star = review.rating.round().clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.teacherPageBackground,
      appBar: const TealPageHeader(title: 'Ratings & Reviews'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_summary != null) _summaryCard(_summary!),
                          const SizedBox(height: 18),
                          _reviewsHeader(),
                          const SizedBox(height: 10),
                          if (_reviews.isEmpty)
                            _emptyState()
                          else
                            ...List.generate(
                              _reviews.length,
                              (index) => ReviewCard(
                                review: _reviews[index],
                                index: index,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(ReviewSummary summary) {
    final counts = _distribution;
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 14, end: 0),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, dy, child) {
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: Container(
        decoration: AppTheme.teacherTintedCard(AppTheme.teacherAccentAmber),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 460;
                final score = _scoreBlock(summary, centered: stacked);
                final bars = _bars(counts, maxCount);
                if (stacked) {
                  return Column(
                    children: [
                      score,
                      const SizedBox(height: 14),
                      bars,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    score,
                    const SizedBox(width: 16),
                    Expanded(child: bars),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _statChip(
                    summary.averageRating.toStringAsFixed(1),
                    'Average',
                    Icons.star_rounded,
                    kRatingGold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statChip(
                    '${summary.totalReviews}',
                    'Reviews',
                    Icons.forum_outlined,
                    AppTheme.teacherAccentIndigo,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statChip(
                    '${summary.completedSessions}',
                    'Completed',
                    Icons.task_alt,
                    AppTheme.teacherAccentEmerald,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBlock(ReviewSummary summary, {required bool centered}) {
    return SizedBox(
      width: centered ? double.infinity : 132,
      child: Column(
        children: [
          Text(
            summary.totalReviews == 0
                ? '—'
                : summary.averageRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          RatingStars(
            value: summary.totalReviews == 0 ? 0 : summary.averageRating,
            size: 18,
          ),
          const SizedBox(height: 8),
          Text(
            ratingMood(summary.totalReviews == 0 ? 0 : summary.averageRating),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bars(Map<int, int> counts, int maxCount) {
    return Column(
      children: [
        for (final star in [5, 4, 3, 2, 1])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  child: Text(
                    '$star',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const Icon(Icons.star_rounded, size: 12, color: kRatingGold),
                const SizedBox(width: 6),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: maxCount == 0 ? 0 : (counts[star] ?? 0) / maxCount,
                    ),
                    duration: Duration(milliseconds: 700 + (5 - star) * 80),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF4E7C8),
                          color: kRatingGold,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  child: Text(
                    '${counts[star] ?? 0}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _statChip(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewsHeader() {
    final count = _reviews.length;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppTheme.teacherHeaderGradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Learner reviews',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          count == 0 ? 'Be the first story' : '$count shared',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      decoration: AppTheme.teacherCardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: const Column(
        children: [
          Icon(Icons.star_rounded, color: kRatingGold, size: 42),
          SizedBox(height: 10),
          Text(
            'No student ratings yet',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'When a student rates one of your lessons, the score and their note will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
