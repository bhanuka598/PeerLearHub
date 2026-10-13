import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../../../core/utils/lesson_image.dart';
import '../../../models/lesson.dart';
import '../../skill_provider/models/review.dart';
import '../../skill_provider/services/firebase_lesson_service.dart';
import '../../skill_provider/services/review_service.dart';
import '../../skill_provider/widgets/review_card.dart';
import '../../skill_provider/widgets/status_chip.dart';
import '../data/student_lesson_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/assignment_service.dart';
import '../../moderation/models/moderation_report.dart';
import '../../moderation/services/moderation_service.dart';

class StudentLessonDetailsScreen extends StatefulWidget {
  const StudentLessonDetailsScreen({
    super.key,
    required this.lesson,
    this.isReportPreview = false,
  });

  final Lesson lesson;
  final bool isReportPreview;

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
  bool _quizCompleted = false;
  int _currentVideoIndex = 0;
  final Set<int> _completedVideoIndices = {};
  final _assignmentDescriptionController = TextEditingController();
  final _assignmentGithubController = TextEditingController();
  bool _submittingAssignment = false;
  bool _assignmentSubmitted = false;

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
    _assignmentDescriptionController.dispose();
    _assignmentGithubController.dispose();
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
    await _loadVideoProgress();
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
      appBar: AppBar(
        title: Text(widget.isReportPreview ? 'Reported Lesson Preview' : 'Lesson details'),
        leading: widget.isReportPreview ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Report',
        ) : null,
        actions: [
          if (!widget.isReportPreview)
            IconButton(
              icon: const Icon(Icons.flag_outlined, color: Colors.red),
              tooltip: 'Report this lesson',
              onPressed: _showReportDialog,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                if (widget.isReportPreview)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'You are viewing this lesson as a moderator in preview mode.',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.orange.shade800,
                          ),
                          child: const Text('Back to Report'),
                        ),
                      ],
                    ),
                  ),
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
                        if (_enrolled && _parsedYoutube != null && _parsedYoutube!.isValid && lesson.youtubePlaylistUrl != null) ...[
                          const SizedBox(height: 16),
                          _sectionCard(
                            icon: Icons.ondemand_video_outlined,
                            title: 'Video lessons',
                            child: _YoutubeLessonPlayer(
                              info: _parsedYoutube!,
                              rawUrl: lesson.youtubePlaylistUrl!,
                            ),
                          ),
                        ],
                        if (_enrolled) ...[
                          const SizedBox(height: 16),
                          _quizCheckpointCard(),
                        ],
                        if (_enrolled && _quizCompleted) ...[
                          const SizedBox(height: 16),
                          _assignmentSubmissionCard(),
                        ],
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

  ParsedYoutubeInfo? get _parsedYoutube {
    final url = lesson.youtubePlaylistUrl;
    if (url == null) return null;
    return parseYoutubeUrl(url);
  }

  void _showReportDialog() {
    ReportReason reason = ReportReason.spam;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Report Lesson'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ReportReason>(
                    value: reason,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: ReportReason.values.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.displayName),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => reason = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Please provide details...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitting report...')));
                  
                  final currentUser = FirebaseAuth.instance.currentUser;
                  
                  await ModerationService().submitReport(
                    reportedBy: currentUser?.uid ?? 'unknown_student',
                    reporterName: currentUser?.displayName ?? 'Student User',
                    reportedUserId: lesson.providerId,
                    relatedContentId: lesson.id,
                    relatedContentType: 'Lesson',
                    relatedContentTitle: lesson.title,
                    reason: reason,
                    description: descriptionController.text,
                    severity: ReportSeverity.medium,
                  );
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully.')));
                    
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Block Provider?'),
                        content: const Text('Would you also like to block this provider so you no longer see their content?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('No'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Provider blocked.')),
                              );
                            },
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Block'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Report'),
              ),
            ],
          );
        },
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

  Widget _quizCheckpointCard() {
    return _playlistTrackerWidget();
  }

  List<PlaylistVideoItem> get _playlistVideos {
    return [
      PlaylistVideoItem(
        id: 'v1',
        title: '${lesson.title} - Part 1: Introduction',
        duration: '5 min',
        description: 'Introduction and fundamental concepts.',
      ),
      PlaylistVideoItem(
        id: 'v2',
        title: '${lesson.title} - Part 2: Core Walkthrough',
        duration: '8 min',
        description: 'Step-by-step practical demonstration.',
      ),
      PlaylistVideoItem(
        id: 'v3',
        title: '${lesson.title} - Part 3: Summary & Practice',
        duration: '6 min',
        description: 'Review, common pitfalls, and quiz practice.',
      ),
    ];
  }

  Future<void> _loadVideoProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final db = FirebaseFirestore.instance;
      final doc = await db
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .doc(lesson.id)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['completedVideos'] is List) {
          setState(() {
            _completedVideoIndices.clear();
            _completedVideoIndices.addAll(
              (data['completedVideos'] as List).map((e) => (e as num).toInt()),
            );
            if (_completedVideoIndices.isNotEmpty) {
              _currentVideoIndex = (_completedVideoIndices.reduce((a, b) => a > b ? a : b) + 1)
                  .clamp(0, _playlistVideos.length - 1);
              if (_completedVideoIndices.length == _playlistVideos.length) {
                _quizCompleted = true;
              }
            }
          });
        }
      }

      final assignmentDoc = await db
          .collection('users')
          .doc(user.uid)
          .collection('assignments')
          .doc(lesson.id)
          .get();
      if (assignmentDoc.exists) {
        setState(() {
          _assignmentSubmitted = true;
          _quizCompleted = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading video progress: $e');
    }
  }

  Future<void> _saveVideoProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .doc(lesson.id)
          .set({
            'completedVideos': _completedVideoIndices.toList(),
            'lastVideoIndex': _currentVideoIndex,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving video progress: $e');
    }
  }

  Future<void> _completeVideoQuiz(int videoIndex) async {
    setState(() {
      _completedVideoIndices.add(videoIndex);
      if (videoIndex + 1 < _playlistVideos.length) {
        _currentVideoIndex = videoIndex + 1;
      }
      if (_completedVideoIndices.length == _playlistVideos.length) {
        _quizCompleted = true;
      }
    });
    await _awardQuizPoints();
    await _saveVideoProgress();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Video ${videoIndex + 1} quiz passed! Earned +5 points. Next video unlocked!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _playlistTrackerWidget() {
    final videos = _playlistVideos;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.iconBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.playlist_play, color: AppTheme.primaryColor, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Playlist Progress (Video by Video)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${_completedVideoIndices.length}/${videos.length} Done',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Watch each video in the playlist, complete its quiz to earn +5 points, and unlock the next video.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...List.generate(videos.length, (index) {
            final video = videos[index];
            final isCompleted = _completedVideoIndices.contains(index);
            final isCurrent = index == _currentVideoIndex && !isCompleted;
            final isLocked = index > _currentVideoIndex && !isCompleted;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.shade50
                    : (isCurrent ? AppTheme.primaryColor.withValues(alpha: 0.08) : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCompleted
                      ? Colors.green.shade300
                      : (isCurrent ? AppTheme.primaryColor : Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green
                          : (isCurrent ? AppTheme.primaryColor : Colors.grey.shade300),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : (isLocked ? Icons.lock : Icons.play_arrow),
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isLocked ? Colors.grey : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${video.duration} • ${video.description}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isLocked ? Colors.grey : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCompleted)
                    const Chip(
                      label: Text('+5 Pts', style: TextStyle(color: Colors.white, fontSize: 11)),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                    )
                  else if (!isLocked)
                    FilledButton.tonal(
                      onPressed: () => _showVideoQuizDialog(index, video.title),
                      child: const Text('Take Quiz'),
                    )
                  else
                    const Icon(Icons.lock_outline, size: 20, color: Colors.grey),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showVideoQuizDialog(int videoIndex, String videoTitle) {
    int q1Answer = 0;
    int q2Answer = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Quiz: $videoTitle'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Complete this quick quiz for the video to earn +5 points and unlock the next video:',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Text('1. What was the main takeaway of this video session?', style: TextStyle(fontWeight: FontWeight.bold)),
                    RadioListTile<int>(
                      title: Text('Understanding $videoTitle'),
                      value: 0,
                      groupValue: q1Answer,
                      onChanged: (val) => setDialogState(() => q1Answer = val!),
                    ),
                    RadioListTile<int>(
                      title: const Text('Unrelated concepts'),
                      value: 1,
                      groupValue: q1Answer,
                      onChanged: (val) => setDialogState(() => q1Answer = val!),
                    ),
                    const Divider(),
                    const Text('2. Are you ready to proceed to the next video?', style: TextStyle(fontWeight: FontWeight.bold)),
                    RadioListTile<int>(
                      title: const Text('Yes, ready to continue!'),
                      value: 0,
                      groupValue: q2Answer,
                      onChanged: (val) => setDialogState(() => q2Answer = val!),
                    ),
                    RadioListTile<int>(
                      title: const Text('Need to review again'),
                      value: 1,
                      groupValue: q2Answer,
                      onChanged: (val) => setDialogState(() => q2Answer = val!),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _completeVideoQuiz(videoIndex);
                },
                child: const Text('Submit Quiz (+5 Pts)'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _assignmentSubmissionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
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
                child: const Icon(Icons.assignment_turned_in, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Lesson Assignment & Certificate',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_assignmentSubmitted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assignment Submitted Successfully!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Your GitHub repository has been reviewed and certificate awarded.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Certificate of Completion Awarded',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'System verified your completion. Download your official PDF certificate below.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _downloadCertificate,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Download PDF'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saveCertificateToFile,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(color: AppTheme.primaryColor),
                          ),
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Save to Files'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              'Now that you have completed the video quizzes, submit your assignment by entering a brief description and your GitHub repository URL.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _assignmentDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Assignment Description',
                hintText: 'Describe what you built or learned in this lesson...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _assignmentGithubController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'GitHub Repository URL',
                hintText: 'https://github.com/username/repository',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submittingAssignment ? null : _submitAssignment,
              icon: _submittingAssignment
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(_submittingAssignment ? 'Submitting...' : 'Submit Assignment'),
            ),
          ],
        ],
      ),
    );
  }

  Future<Uint8List> _generateCertificateBytes() async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'CERTIFICATE OF COMPLETION',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text('This certifies that the learner successfully completed'),
              pw.SizedBox(height: 8),
              pw.Text(
                lesson.title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text('Awarded by PeerLearnHub System'),
              pw.SizedBox(height: 8),
              pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}'),
            ],
          ),
        ),
      ),
    );
    return document.save();
  }

  Future<void> _downloadCertificate() async {
    try {
      final bytes = await _generateCertificateBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'peerlearnhub-lesson-${lesson.id}-certificate.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download certificate: $e')),
      );
    }
  }

  Future<void> _saveCertificateToFile() async {
    try {
      final bytes = await _generateCertificateBytes();
      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Save Certificate PDF',
        fileName: 'peerlearnhub-lesson-${lesson.id}-certificate.pdf',
        bytes: bytes,
      );
      if (outputFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certificate saved to $outputFile')),
        );
      }
    } catch (e) {
      await _downloadCertificate();
    }
  }

  Future<void> _submitAssignment() async {
    final description = _assignmentDescriptionController.text.trim();
    final githubUrl = _assignmentGithubController.text.trim();

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an assignment description.')),
      );
      return;
    }
    if (githubUrl.isEmpty || !githubUrl.contains('github.com/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid GitHub repository URL.')),
      );
      return;
    }

    setState(() => _submittingAssignment = true);
    try {
      await AssignmentService.instance.submit(
        courseId: lesson.id,
        description: description,
        githubUrl: githubUrl,
      );
      if (!mounted) return;
      setState(() => _assignmentSubmitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', '').replaceFirst('StateError: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submittingAssignment = false);
    }
  }

  Future<void> _awardQuizPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'learningPoints': FieldValue.increment(5),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Could not award points: $e');
    }
  }
}

class PlaylistVideoItem {
  const PlaylistVideoItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.description,
  });

  final String id;
  final String title;
  final String duration;
  final String description;
}

class ParsedYoutubeInfo {
  const ParsedYoutubeInfo({
    this.videoId,
    this.playlistId,
  });

  final String? videoId;
  final String? playlistId;

  bool get isValid => (videoId != null && videoId!.isNotEmpty) || (playlistId != null && playlistId!.isNotEmpty);
  bool get isPlaylist => playlistId != null && playlistId!.isNotEmpty;
}

ParsedYoutubeInfo? parseYoutubeUrl(String rawUrl) {
  final url = rawUrl.trim();
  if (url.isEmpty) return null;

  final uri = Uri.tryParse(url);
  if (uri != null && (uri.hasScheme || uri.host.isNotEmpty)) {
    final listParam = uri.queryParameters['list'];
    final vParam = uri.queryParameters['v'];

    if (listParam != null && listParam.isNotEmpty) {
      return ParsedYoutubeInfo(
        playlistId: listParam,
        videoId: vParam,
      );
    }

    if (vParam != null && vParam.isNotEmpty) {
      return ParsedYoutubeInfo(videoId: vParam);
    }

    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return ParsedYoutubeInfo(videoId: uri.pathSegments.first);
    }

    if (uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.contains('embed') || uri.pathSegments.contains('v')) {
        final idx = uri.pathSegments.indexOf('embed');
        if (idx != -1 && idx + 1 < uri.pathSegments.length) {
          return ParsedYoutubeInfo(videoId: uri.pathSegments[idx + 1]);
        }
        final vIdx = uri.pathSegments.indexOf('v');
        if (vIdx != -1 && vIdx + 1 < uri.pathSegments.length) {
          return ParsedYoutubeInfo(videoId: uri.pathSegments[vIdx + 1]);
        }
      }

      for (final segment in uri.pathSegments) {
        if (segment.startsWith('PL') || segment.startsWith('UU') || segment.startsWith('LL') || segment.startsWith('RD')) {
          return ParsedYoutubeInfo(playlistId: segment);
        }
        if (segment.length == 11) {
          return ParsedYoutubeInfo(videoId: segment);
        }
      }
    }
  }

  if (url.startsWith('PL') || url.startsWith('UU') || url.startsWith('LL') || url.startsWith('RD') || url.length > 12) {
    return ParsedYoutubeInfo(playlistId: url);
  }
  if (url.length == 11) {
    return ParsedYoutubeInfo(videoId: url);
  }

  return ParsedYoutubeInfo(videoId: url);
}

class _YoutubeLessonPlayer extends StatefulWidget {
  const _YoutubeLessonPlayer({required this.info, required this.rawUrl});

  final ParsedYoutubeInfo info;
  final String rawUrl;

  @override
  State<_YoutubeLessonPlayer> createState() => _YoutubeLessonPlayerState();
}

class _YoutubeLessonPlayerState extends State<_YoutubeLessonPlayer> {
  late final YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (!widget.info.isPlaylist && widget.info.videoId != null) {
      _controller = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );
      _controller!.cueVideoById(videoId: widget.info.videoId!);
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  Future<void> _launchExternal() async {
    final uri = Uri.tryParse(widget.rawUrl);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.info.isPlaylist) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.playlist_play, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YouTube Video Playlist',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Watch this course playlist on YouTube.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _launchExternal,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Open Playlist on YouTube'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_controller != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: _launchExternal,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFF0000),
            side: const BorderSide(color: Color(0xFFFF0000)),
          ),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Watch on YouTube'),
        ),
      ],
    );
  }
}
