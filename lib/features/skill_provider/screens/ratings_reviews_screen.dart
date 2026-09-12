import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../utils/provider_id_helper.dart';
import '../widgets/app_header.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(title: 'Ratings & Reviews'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_summary != null)
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 32),
                                  Text(
                                    _summary!.averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Text('Average Rating'),
                            ],
                          ),
                          Column(
                            children: [
                              Text('${_summary!.totalReviews}',
                                  style: const TextStyle(
                                      fontSize: 28, fontWeight: FontWeight.bold)),
                              const Text('Reviews'),
                            ],
                          ),
                          Column(
                            children: [
                              Text('${_summary!.completedSessions}',
                                  style: const TextStyle(
                                      fontSize: 28, fontWeight: FontWeight.bold)),
                              const Text('Completed'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_reviews.isEmpty)
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(24),
                      child: const Text(
                        'No student ratings yet. When a student rates one of your lessons, it will show up here.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  else
                    ..._reviews.map((r) => ReviewCard(review: r)),
                ],
              ),
            ),
    );
  }
}
