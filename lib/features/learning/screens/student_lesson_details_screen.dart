import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../../../models/lesson.dart';
import '../../skill_provider/models/review.dart';
import '../../skill_provider/services/firebase_lesson_service.dart';
import '../../skill_provider/services/review_service.dart';
import '../../skill_provider/widgets/review_card.dart';
import '../../skill_provider/widgets/status_chip.dart';
import '../data/student_lesson_store.dart';

class StudentLessonDetailsScreen extends StatefulWidget {
  const StudentLessonDetailsScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<StudentLessonDetailsScreen> createState() =>
      _StudentLessonDetailsScreenState();
}

class _StudentLessonDetailsScreenState
    extends State<StudentLessonDetailsScreen> {
  final _reviewService = ReviewService.instance;
  final _commentController = TextEditingController();
  late Lesson _lesson;
  List<ProviderReview> _reviews = [];
  int _rating = 0;
  bool _loading = true;
  bool _saving = false;
  bool _enrolled = false;

  Lesson get lesson => _lesson;

  @override
  void initState() {
    super.initState();
    _lesson = widget.lesson;
    _enrolled = StudentLessonStore.instance.isEnrolled(lesson.id);
    _reviewService.addListener(_onReviewsChanged);
    _load();
  }

  @override
  void dispose() {
    _reviewService.removeListener(_onReviewsChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _onReviewsChanged() {
    _loadReviews();
  }

  Future<void> _load() async {
    final fresh =
        await FirebaseLessonService.instance.getLessonById(widget.lesson.id);
    if (fresh != null) {
      _lesson = _mergeLesson(widget.lesson, fresh);
    }
    await _loadReviews();
  }

  Lesson _mergeLesson(Lesson passed, Lesson fetched) {
    final passedImage = passed.imageUrl;
    final fetchedImage = fetched.imageUrl;
    if ((fetchedImage == null || fetchedImage.isEmpty) &&
        passedImage != null &&
        passedImage.isNotEmpty) {
      return fetched.copyWith(imageUrl: passedImage);
    }
    return fetched;
  }

  Future<void> _loadReviews() async {
    final reviews = await _reviewService.getReviewsForLesson(lesson.id);
    final existing = _reviewService.existingReviewForLesson(lesson.id);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      if (existing != null) {
        _rating = existing.rating.round().clamp(1, 5);
        if (_commentController.text.isEmpty) {
          _commentController.text = existing.comment;
        }
      }
      _loading = false;
    });
  }

  String _valueOrDash(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Not specified' : trimmed;
  }

  String get _availableDays {
    if (lesson.availability.availableDays.isEmpty) return 'Not specified';
    return lesson.availability.availableDays.join(', ');
  }

  String get _preferredTime =>
      _valueOrDash(lesson.availability.preferredTime);

  Future<void> _submitRating() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a star rating first.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _reviewService.addReview(
        providerId: lesson.providerId,
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        rating: _rating.toDouble(),
        comment: _commentController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your rating was saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addToMyLearning() async {
    await StudentLessonStore.instance.enroll(lesson.id);
    if (!mounted) return;
    setState(() => _enrolled = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to My Learning.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Lesson details')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _heroCard(),
                        const SizedBox(height: 16),
                        _sectionCard(
                          icon: Icons.info_outline,
                          title: 'About this lesson',
                          child: Text(
                            _valueOrDash(lesson.description),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  height: 1.5,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          icon: Icons.event_outlined,
                          title: 'Date, time & location',
                          child: Column(
                            children: [
                              _infoTile(
                                Icons.event_available_outlined,
                                'Available days',
                                _availableDays,
                              ),
                              _infoTile(
                                Icons.access_time,
                                'Preferred time',
                                _preferredTime,
                              ),
                              _infoTile(
                                Icons.schedule_outlined,
                                'Duration',
                                _valueOrDash(lesson.duration),
                              ),
                              _infoTile(
                                Icons.videocam_outlined,
                                'Lesson type',
                                lesson.lessonType.label,
                              ),
                              _infoTile(
                                Icons.place_outlined,
                                'Location',
                                _valueOrDash(lesson.location),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          icon: Icons.tune_outlined,
                          title: 'Lesson details',
                          child: Column(
                            children: [
                              _infoTile(
                                Icons.category_outlined,
                                'Category',
                                lesson.category.label,
                              ),
                              _infoTile(
                                Icons.signal_cellular_alt,
                                'Skill level',
                                lesson.skillLevel.label,
                              ),
                              _infoTile(
                                Icons.swap_horiz,
                                'Exchange type',
                                lesson.exchangeType.label,
                              ),
                              _infoTile(
                                Icons.payments_outlined,
                                'Price',
                                formatLessonPrice(lesson),
                              ),
                              _infoTile(
                                Icons.calendar_today_outlined,
                                'Published date',
                                formatDate(lesson.createdAt),
                              ),
                              _infoTile(
                                Icons.update_outlined,
                                'Last updated',
                                formatDate(lesson.updatedAt),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        if (lesson.learningOutcomes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _sectionCard(
                            icon: Icons.flag_outlined,
                            title: 'What you will learn',
                            child: Column(
                              children: lesson.learningOutcomes
                                  .map(_bulletRow)
                                  .toList(),
                            ),
                          ),
                        ],
                        if (lesson.learningMaterials.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _sectionCard(
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
                                      Expanded(child: Text(material)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _enrolled ? null : _addToMyLearning,
                            icon: Icon(
                              _enrolled
                                  ? Icons.check_circle_outline
                                  : Icons.add_circle_outline,
                            ),
                            label: Text(
                              _enrolled ? 'In My Learning' : 'Add to My Learning',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _rateCard(),
                        const SizedBox(height: 16),
                        _reviewsCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _heroCard() {
    final average = _reviewService.averageForLesson(lesson.id);
    return Container(
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
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
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        _reviews.isEmpty
                            ? 'No ratings yet'
                            : '${average.toStringAsFixed(1)} (${_reviews.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      LessonMetaChip(
                        icon: Icons.payments_outlined,
                        label: formatLessonPrice(lesson),
                      ),
                    ],
                  ),
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
                      label: _valueOrDash(lesson.duration),
                    ),
                    LessonMetaChip(
                      icon: Icons.place_outlined,
                      label: _valueOrDash(lesson.location),
                    ),
                    LessonMetaChip(
                      icon: Icons.access_time,
                      label: _preferredTime,
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
    final url = lesson.imageUrl?.trim();
    final hasImage = url != null &&
        url.isNotEmpty &&
        !url.contains('placeholder.peerlearnhub.com');

    if (hasImage && url.startsWith('data:image/')) {
      final data = Uri.tryParse(url)?.data;
      if (data != null) {
        return Image.memory(
          data.contentAsBytes(),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, _, _) => _thumbnailPlaceholder(),
        );
      }
    }

    if (hasImage && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _thumbnailPlaceholder(),
      );
    }

    if (hasImage && !url.startsWith('http') && !url.startsWith('data:')) {
      try {
        return Image.memory(
          base64Decode(url),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, _, _) => _thumbnailPlaceholder(),
        );
      } catch (_) {}
    }

    return _thumbnailPlaceholder();
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

  Widget _sectionCard({
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

  Widget _rateCard() {
    return _sectionCard(
      icon: Icons.star_outline,
      title: 'Rate this lesson',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Your rating will appear on the teacher Ratings & Reviews page.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: _saving ? null : () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write a short review (optional)',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _saving ? null : _submitRating,
            child: Text(_saving ? 'Saving...' : 'Submit rating'),
          ),
        ],
      ),
    );
  }

  Widget _reviewsCard() {
    return _sectionCard(
      icon: Icons.reviews_outlined,
      title: 'Student reviews',
      child: _reviews.isEmpty
          ? const Text(
              'No ratings yet. Be the first to rate this lesson.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          : Column(
              children: _reviews
                  .map((review) => ReviewCard(review: review))
                  .toList(),
            ),
    );
  }
}
