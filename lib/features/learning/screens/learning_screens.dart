import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/auth/app_auth.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../../../core/utils/lesson_image.dart';
import '../../../core/widgets/role_switcher_button.dart';
import '../../../models/lesson.dart';
import '../../notifications/widgets/notification_bell_button.dart';
import '../../skill_provider/models/provider_session.dart';
import '../../skill_provider/services/firebase_lesson_service.dart';
import '../../skill_provider/services/review_service.dart';
import '../../skill_provider/services/session_service.dart';
import '../../skill_provider/utils/display_utils.dart';
import '../data/learning_quiz_data.dart';
import '../data/learning_store.dart';
import '../data/student_lesson_store.dart';
import '../models/learning_course.dart';
import '../models/learning_quiz.dart';
import '../../moderation/models/moderation_report.dart';
import '../../moderation/services/moderation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../skill_exchange/services/ai_suggestion_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _category = 'All';
  String _level = 'All Levels';
  String _query = '';
  List<Lesson> _teacherLessons = [];
  bool _loadingLessons = true;

  static const _levels = ['All Levels', 'Beginner', 'Intermediate', 'Advanced'];
  List<Map<String, dynamic>> _aiRecommendations = [];
  bool _loadingAiRecommendations = true;
  Map<String, dynamic>? _skillGapData;
  bool _loadingSkillGap = true;
  String _trendingSort = 'Trending'; // 'Trending', 'Most Enrolled', 'Highest Rated', 'Newest'

  @override
  void initState() {
    super.initState();
    FirebaseLessonService.instance.addListener(_loadTeacherLessons);
    ReviewService.instance.addListener(_onReviewsChanged);
    StudentLessonStore.instance.load();
    ReviewService.instance.refresh();
    _loadTeacherLessons();
    LearningStore.instance.loadEnrollments().then((_) {
      _loadAiRecommendations(LearningStore.instance.value);
    });
  }

  List<String> _userInterests = [];
  String _userGoal = '';
  String _userSkillLevel = 'Beginner';
  List<String> _userSearchHistory = [];

  Future<void> _recordSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userRef.set({
          'searchHistory': FieldValue.arrayUnion([trimmed.toLowerCase()]),
          'lastSearchedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (!_userSearchHistory.contains(trimmed.toLowerCase())) {
          _userSearchHistory.insert(0, trimmed.toLowerCase());
          if (_userSearchHistory.length > 8) _userSearchHistory.removeLast();
        }
      } catch (e) {
        debugPrint('Error recording search query: $e');
      }
    }
    // Re-trigger personalized recommendations with updated search signal
    _loadAiRecommendations(LearningStore.instance.value);
  }

  Future<void> _loadAiRecommendations(List<LearningCourse> courses) async {
    final user = FirebaseAuth.instance.currentUser;
    Map<String, dynamic> learnerProfile = {
      'uid': user?.uid ?? 'guest',
      'email': user?.email ?? '',
      'displayName': user?.displayName ?? 'Learner',
      'learningGoal': _userGoal,
      'skillLevel': _userSkillLevel,
      'interests': _userInterests,
      'searchHistory': _userSearchHistory,
    };

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          learnerProfile.addAll(data);
          _userGoal = (data['learningGoal'] ?? data['goal'] ?? '').toString();
          _userSkillLevel = (data['skillLevel'] ?? data['level'] ?? 'Beginner').toString();
          _userInterests = (data['interests'] as List?)?.map((e) => e.toString()).toList() ?? [];
          _userSearchHistory = (data['searchHistory'] as List?)?.map((e) => e.toString()).toList() ?? [];
        }

        final assignmentsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('assignments')
            .get();
        final completedLessonIds = assignmentsSnap.docs.map((d) => d.id).toList();
        learnerProfile['completedLessons'] = completedLessonIds;

        final enrollmentsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('enrollments')
            .get();
        final enrolledLessonIds = enrollmentsSnap.docs.map((d) => d.id).toList();
        learnerProfile['enrolledLessons'] = enrolledLessonIds;
      } catch (e) {
        debugPrint('Error loading learner profile: $e');
      }
    }

    final courseDataList = courses.map((c) => {
      'id': c.id,
      'title': c.title,
      'category': c.category,
      'level': c.level,
      'tags': c.modules.map((m) => m.title).toList(),
    }).toList();

    final recs = await AISuggestionService.getPersonalizedRecommendations(
      learnerProfile: learnerProfile,
      courses: courseDataList,
    );

    // Load Skill-Gap recommendations for target role vs current skills & completed courses
    final targetRole = _userGoal.isNotEmpty ? _userGoal : 'Mobile Developer';
    final completedCourseObjs = courses.where((c) => (learnerProfile['completedLessons'] as List? ?? []).contains(c.id)).map((c) => {
      'id': c.id,
      'title': c.title,
      'category': c.category,
    }).toList();

    final gapResult = await AISuggestionService.getSkillGapRecommendations(
      targetRole: targetRole,
      currentSkills: _userInterests,
      completedCourses: completedCourseObjs,
      candidateCourses: courseDataList,
    );

    if (mounted) {
      setState(() {
        _aiRecommendations = recs;
        _loadingAiRecommendations = false;
        _skillGapData = gapResult;
        _loadingSkillGap = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    FirebaseLessonService.instance.removeListener(_loadTeacherLessons);
    ReviewService.instance.removeListener(_onReviewsChanged);
    super.dispose();
  }

  void _onReviewsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTeacherLessons() async {
    final lessons = await FirebaseLessonService.instance.getPublishedLessons();
    if (mounted) {
      setState(() {
        _teacherLessons = lessons;
        _loadingLessons = false;
      });
    }
  }

  List<String> _categoryOptions(List<LearningCourse> courses) {
    final values = <String>{
      ..._teacherLessons.map((lesson) => lesson.category.label),
      ...courses.map((course) => course.category),
    };
    if (values.isEmpty) {
      values.addAll(LessonCategory.values.map((category) => category.label));
    }
    final sorted = values.toList()..sort();
    return ['All', ...sorted];
  }

  bool _matchesSearch(LearningCourse course) {
    final searchableText = [
      course.title,
      course.description,
      course.category,
      course.level,
      course.instructor,
      ...course.modules.map((module) => module.title),
    ].join(' ').toLowerCase();
    final terms = _query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    return terms.every(searchableText.contains);
  }

  List<Lesson> _visibleTeacherLessonsFor(String category) {
    final query = _query.toLowerCase();
    return _teacherLessons.where((lesson) {
      final matchesCategory =
          category == 'All' || lesson.category.label == category;
      final matchesLevel =
          _level == 'All Levels' || lesson.skillLevel.label == _level;
      final matchesQuery = query.isEmpty ||
          '${lesson.title} ${lesson.category.label} ${lesson.description}'
              .toLowerCase()
              .contains(query);
      return matchesCategory && matchesLevel && matchesQuery;
    }).toList();
  }

  void _showPreferenceTunerDialog() {
    final goalController = TextEditingController(text: _userGoal);
    String selectedLevel = _userSkillLevel;
    final Set<String> currentInterests = Set<String>.from(_userInterests);
    const availableInterests = [
      'Mobile Development',
      'Flutter',
      'React Native',
      'Python',
      'Go',
      'Rust',
      'C# & .NET',
      'Dart',
      'Java',
      'UI/UX Design',
      'Figma',
      'Web Development',
      'HTML & CSS',
      'Tailwind CSS',
      'JavaScript',
      'React',
      'Node.js',
      'FastAPI',
      'Spring Boot',
      'Database Management',
      'SQL & NoSQL',
      'PostgreSQL',
      'MongoDB',
      'Oracle Database',
      'API Design & Development',
      'RESTful APIs',
      'GraphQL',
      'Machine Learning',
      'Cloud & DevOps',
      'Linux & Docker',
      'Kubernetes',
      'Containerization',
      'CI/CD Pipelines',
      'Git & GitHub',
      'AWS & Azure',
      'Cyber Security',
      'Artificial Intelligence',
      'Blockchain',
      'Game Development',
      'Data Science',
      'Big Data',
      'Project Management',
      'Agile & Scrum',
      'System Architecture',
      'Microservices Architecture',
      'MicroKernel Architecture',
      'Event-Driven Architecture',
      'Soft Skills',
      'Communication Skills',
      'English Proficiency',
      'Leadership & Teamwork',
      'Problem Solving',
      'Critical Thinking',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Customize My Learning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Learning Goal / Career Ambition', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: goalController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Become a Mobile Developer',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Your Current Skill Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: ['Beginner', 'Intermediate', 'Advanced'].contains(selectedLevel) ? selectedLevel : 'Beginner',
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: ['Beginner', 'Intermediate', 'Advanced']
                        .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedLevel = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Topic Interests', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: availableInterests.map((interest) {
                      final isSelected = currentInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              currentInterests.add(interest);
                            } else {
                              currentInterests.remove(interest);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final newGoal = goalController.text.trim();
                  Navigator.pop(ctx);
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                      'learningGoal': newGoal,
                      'skillLevel': selectedLevel,
                      'interests': currentInterests.toList(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                  }
                  if (mounted) {
                    setState(() {
                      _userGoal = newGoal;
                      _userSkillLevel = selectedLevel;
                      _userInterests = currentInterests.toList();
                    });
                    _loadAiRecommendations(LearningStore.instance.value);
                  }
                },
                child: const Text('Save & Update Feed'),
              ),
            ],
          );
        },
      ),
    );
  }

  String get _firstName {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (name == null || name.isEmpty) return '';
    return name.split(' ').first;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<LearningCourse>>(
        valueListenable: LearningStore.instance,
        builder: (context, courses, _) {
          final categories = _categoryOptions(courses);
          final selectedCategory =
              categories.contains(_category) ? _category : 'All';
          final visibleCourses = courses
              .where(
                (course) =>
                    (selectedCategory == 'All' ||
                        course.category == selectedCategory) &&
                    (_level == 'All Levels' || course.level == _level) &&
                    _matchesSearch(course),
              )
              .toList();

          // Sort by Enrollments, Ratings, Recency
          visibleCourses.sort((a, b) {
            if (_trendingSort == 'Most Enrolled') {
              return b.enrollmentCount.compareTo(a.enrollmentCount);
            } else if (_trendingSort == 'Highest Rated') {
              return b.rating.compareTo(a.rating);
            } else if (_trendingSort == 'Newest') {
              final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            } else {
              // 'Trending' Hybrid Score: Enrollments (50%) + Ratings (30%) + Recency (20%)
              final aEnrollScore = a.enrollmentCount * 10.0;
              final bEnrollScore = b.enrollmentCount * 10.0;
              final aRatingScore = a.rating * 15.0;
              final bRatingScore = b.rating * 15.0;
              final now = DateTime.now();
              final aAgeDays = a.createdAt != null ? now.difference(a.createdAt!).inDays : 60;
              final bAgeDays = b.createdAt != null ? now.difference(b.createdAt!).inDays : 60;
              final aRecencyScore = (30.0 - aAgeDays.clamp(0, 30)).toDouble();
              final bRecencyScore = (30.0 - bAgeDays.clamp(0, 30)).toDouble();

              final aScore = aEnrollScore + aRatingScore + aRecencyScore;
              final bScore = bEnrollScore + bRatingScore + bRecencyScore;
              return bScore.compareTo(aScore);
            }
          });

          final teacherLessons = _visibleTeacherLessonsFor(selectedCategory);
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () async {
                await Future.wait([
                  _loadTeacherLessons(),
                  LearningStore.instance.loadEnrollments(),
                ]);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _DiscoverHeader(
                      greeting: _firstName.isEmpty
                          ? _greeting
                          : '$_greeting, $_firstName',
                      searchController: _searchController,
                      onQueryChanged: (value) =>
                          setState(() => _query = value),
                      onSubmitted: (value) => _recordSearchQuery(value),
                      onProfile: () => context.push('/profile'),
                      onLogout: () {
                        AppAuth.instance.logout();
                        context.go('/login');
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Personalized Learner Goal & Interests Summary Banner
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.track_changes_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Personalized For You',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          _userGoal.isNotEmpty
                                              ? 'Goal: $_userGoal • Level: $_userSkillLevel'
                                              : 'Set your learning goal to get tailored courses',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onPressed: _showPreferenceTunerDialog,
                                    icon: const Icon(Icons.tune_rounded, size: 16),
                                    label: const Text('Edit Goal', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                              if (_userInterests.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: _userInterests.map((interest) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '#$interest',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (_userSearchHistory.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.history_rounded, size: 14, color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Recent searches: ',
                                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: _userSearchHistory.take(3).map((term) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: InkWell(
                                                onTap: () {
                                                  _searchController.text = term;
                                                  setState(() => _query = term);
                                                },
                                                child: Text(
                                                  '"$term"',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.primaryColor,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const _DiscoverSectionHeader(
                          title: 'Categories',
                          subtitle: 'Filter by what you want to learn',
                        ),
                        const SizedBox(height: 12),
                        _DiscoverCategoryBar(
                          categories: categories,
                          selected: selectedCategory,
                          onSelected: (value) =>
                              setState(() => _category = value),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _levels.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final level = _levels[index];
                              return ChoiceChip(
                                label: Text(level),
                                selected: _level == level,
                                selectedColor:
                                    AppTheme.primaryColor.withValues(alpha: .18),
                                onSelected: (_) =>
                                    setState(() => _level = level),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        _DiscoverSectionHeader(
                          title: 'Lessons from teachers',
                          subtitle: teacherLessons.isEmpty
                              ? 'Live sessions you can join'
                              : '${teacherLessons.length} available',
                        ),
                        const SizedBox(height: 12),
                        if (_loadingLessons)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        else if (teacherLessons.isEmpty)
                          _DiscoverEmptyState(
                            icon: Icons.menu_book_outlined,
                            title: _query.isNotEmpty ||
                                    selectedCategory != 'All' ||
                                    _level != 'All Levels'
                                ? 'No lessons match'
                                : 'No lessons yet',
                            message: _query.isNotEmpty ||
                                    selectedCategory != 'All' ||
                                    _level != 'All Levels'
                                ? 'Try another search or category.'
                                : 'Teachers can publish a lesson from Create Lesson.',
                          )
                        else
                          ...teacherLessons.map(
                            (lesson) => TeacherLessonCard(
                              lesson: lesson,
                              onTap: () => context.push(
                                '/learning/provider-lesson',
                                extra: lesson,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        const _DiscoverSectionHeader(
                          title: '✨ Personalized Course Feed',
                          subtitle: 'Courses matching your goal, skill level, and interests',
                        ),
                        const SizedBox(height: 12),
                        if (_loadingAiRecommendations)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        else if (_aiRecommendations.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppTheme.textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Set your learning goals and search for topics to view tailored course suggestions.',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._aiRecommendations.map((rec) {
                            final courseId = rec['courseId']?.toString();
                            final reasoning = rec['reasoning']?.toString() ?? '';
                            final matchScore = rec['matchScore'] ?? 85;
                            final section = rec['section']?.toString() ?? 'goal';
                            final course = courses.firstWhere(
                              (c) => c.id == courseId,
                              orElse: () => courses.first,
                            );

                            String badgeText = 'Top Goal Match';
                            IconData badgeIcon = Icons.auto_awesome;
                            Color badgeColor = AppTheme.primaryColor;

                            if (section == 'past_search') {
                              badgeText = 'Based on Recent Search';
                              badgeIcon = Icons.search_rounded;
                              badgeColor = Colors.deepOrange;
                            } else if (section == 'interests') {
                              badgeText = 'Matched with Interests';
                              badgeIcon = Icons.favorite_border_rounded;
                              badgeColor = Colors.purple;
                            } else if (section == 'skill_level') {
                              badgeText = 'Fits Skill Level';
                              badgeIcon = Icons.trending_up_rounded;
                              badgeColor = Colors.teal;
                            } else if (section == 'continue') {
                              badgeText = 'Continue Enrolled Path';
                              badgeIcon = Icons.play_arrow_rounded;
                              badgeColor = Colors.blue;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(badgeIcon, color: badgeColor, size: 14),
                                            const SizedBox(width: 5),
                                            Text(
                                              badgeText,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: badgeColor,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$matchScore% Match',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    reasoning,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  CourseCard(
                                    course: course,
                                    onTap: () => context.push(
                                      '/learning/course',
                                      extra: course,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 28),

                        // 🎯 Skill-Gap Recommendations: Bridging missing skills for Target Job
                        _DiscoverSectionHeader(
                          title: '🎯 Career Skill-Gap Recommendations',
                          subtitle: _userGoal.isNotEmpty
                              ? 'Skills needed to become a $_userGoal'
                              : 'Bridge missing skills for your target job role',
                        ),
                        const SizedBox(height: 12),
                        if (_loadingSkillGap)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(color: AppTheme.primaryColor),
                            ),
                          )
                        else if (_skillGapData != null)
                          Builder(builder: (context) {
                            final targetRole = _skillGapData!['targetRole']?.toString() ?? 'Software Developer';
                            final readinessScore = (_skillGapData!['readinessScore'] as num?)?.toInt() ?? 50;
                            final masteredSkills = (_skillGapData!['masteredSkills'] as List?)?.map((e) => e.toString()).toList() ?? [];
                            final missingSkills = (_skillGapData!['missingSkills'] as List?)?.map((e) => e.toString()).toList() ?? [];
                            final gapCourses = (_skillGapData!['recommendedCourses'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.work_outline_rounded, color: Colors.blue, size: 20),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Target Role: $targetRole',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  'Role Readiness: $readinessScore%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: readinessScore >= 70 ? Colors.green : Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: (readinessScore >= 70 ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$readinessScore% Ready',
                                              style: TextStyle(
                                                color: readinessScore >= 70 ? Colors.green : Colors.orange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: readinessScore / 100.0,
                                          minHeight: 7,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            readinessScore >= 70 ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Mastered vs Missing Skill breakdown
                                      if (masteredSkills.isNotEmpty) ...[
                                        const Text(
                                          '✅ Mastered Skills (from Profile & Completed Courses):',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.green),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: masteredSkills.map((s) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('✓ $s', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                                          )).toList(),
                                        ),
                                        const SizedBox(height: 10),
                                      ],

                                      if (missingSkills.isNotEmpty) ...[
                                        const Text(
                                          '⚠️ Identified Skill Gap (Missing for Role):',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.deepOrange),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: missingSkills.map((s) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.deepOrange.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('! $s', style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.w600)),
                                          )).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Courses recommended to bridge these gaps
                                if (gapCourses.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      'Recommended Courses to Bridge This Gap:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...gapCourses.map((gc) {
                                    final cid = gc['courseId']?.toString();
                                    final reasoning = gc['reasoning']?.toString() ?? '';
                                    final covered = (gc['coveredSkills'] as List?)?.map((e) => e.toString()).toList() ?? [];
                                    final course = courses.firstWhere((c) => c.id == cid, orElse: () => courses.first);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.03),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Bridges Skill Gap',
                                                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                              ),
                                              const Spacer(),
                                              if (covered.isNotEmpty)
                                                Text(
                                                  'Covers: ${covered.take(2).join(', ')}',
                                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 11),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            reasoning,
                                            style: const TextStyle(fontSize: 12.5, color: AppTheme.textPrimary, height: 1.35),
                                          ),
                                          const SizedBox(height: 10),
                                          CourseCard(
                                            course: course,
                                            onTap: () => context.push(
                                              '/learning/course',
                                              extra: course,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            );
                          }),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Expanded(
                              child: _DiscoverSectionHeader(
                                title: '🔥 Trending & Popular Courses',
                                subtitle: 'What local learners are taking right now',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Filter Pills for Trending Criteria
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              'Trending',
                              'Most Enrolled',
                              'Highest Rated',
                              'Newest',
                            ].map((sortOption) {
                              final isSelected = _trendingSort == sortOption;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (sortOption == 'Trending')
                                        const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.deepOrange),
                                      if (sortOption == 'Most Enrolled')
                                        const Icon(Icons.people_alt_rounded, size: 14, color: Colors.blue),
                                      if (sortOption == 'Highest Rated')
                                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                      if (sortOption == 'Newest')
                                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      Text(sortOption, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                  onSelected: (_) => setState(() => _trendingSort = sortOption),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (visibleCourses.isEmpty)
                          const _DiscoverEmptyState(
                            icon: Icons.school_outlined,
                            title: 'No courses match',
                            message:
                                'Adjust your search or pick another category.',
                          )
                        else
                          ...visibleCourses.map(
                            (course) => CourseCard(
                              course: course,
                              onTap: () => context.push(
                                '/learning/course',
                                extra: course,
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const _LearningNav(index: 0),
          );
        },
      );
}

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({
    super.key,
    required this.course,
    this.isReportPreview = false,
  });
  final LearningCourse course;
  final bool isReportPreview;

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  List<Map<String, dynamic>> _similarCourses = [];
  bool _loadingSimilar = true;

  @override
  void initState() {
    super.initState();
    _trackViewAndLoadSimilar();
  }

  Future<void> _trackViewAndLoadSimilar() async {
    final user = FirebaseAuth.instance.currentUser;
    final course = widget.course;

    // 1. Log course view in Firestore for collaborative filtering
    if (user != null) {
      try {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userRef.set({
          'viewedCourses': FieldValue.arrayUnion([course.id]),
          'lastViewedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Increment course global view count
        final courseRef = FirebaseFirestore.instance.collection('courses').doc(course.id);
        await courseRef.set({
          'viewCount': FieldValue.increment(1),
          'viewerIds': FieldValue.arrayUnion([user.uid]),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error logging course view: $e');
      }
    }

    // 2. Fetch behavioral co-views and co-enrollments
    List<String> coViewedIds = [];
    List<String> coEnrolledIds = [];
    try {
      final courseDoc = await FirebaseFirestore.instance.collection('courses').doc(course.id).get();
      if (courseDoc.exists) {
        final cData = courseDoc.data() ?? {};
        coViewedIds = (cData['coViewedCourses'] as List?)?.map((e) => e.toString()).toList() ?? [];
        coEnrolledIds = (cData['coEnrolledCourses'] as List?)?.map((e) => e.toString()).toList() ?? [];
      }
    } catch (e) {
      debugPrint('Error loading course co-views: $e');
    }

    // 3. Format current and candidate courses
    final allCourses = LearningStore.instance.value;
    final currentCourseData = {
      'id': course.id,
      'title': course.title,
      'category': course.category,
      'level': course.level,
      'instructor': course.instructor,
      'tags': course.modules.map((m) => m.title).toList(),
    };

    final candidateCoursesData = allCourses.map((c) => {
      'id': c.id,
      'title': c.title,
      'category': c.category,
      'level': c.level,
      'instructor': c.instructor,
      'tags': c.modules.map((m) => m.title).toList(),
    }).toList();

    // 4. Request AI similar course suggestions
    final recs = await AISuggestionService.getSimilarCourses(
      currentCourse: currentCourseData,
      allCourses: candidateCoursesData,
      coEnrolledCourseIds: coEnrolledIds,
      coViewedCourseIds: coViewedIds,
    );

    if (mounted) {
      setState(() {
        _similarCourses = recs;
        _loadingSimilar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final isReportPreview = widget.isReportPreview;
    final allCourses = LearningStore.instance.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(isReportPreview ? 'Reported Course Preview' : 'Course details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: isReportPreview ? 'Back to Report' : 'Back',
          onPressed: () => isReportPreview
              ? Navigator.pop(context)
              : popOrGo(context, '/learning'),
        ),
        actions: [
          if (!isReportPreview)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'report') {
                  _showReportDialog(context, course);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Report Course', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isReportPreview)
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
                      'You are viewing this course as a moderator in preview mode.',
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
          _CourseHero(course: course),
          const SizedBox(height: 24),
          Text(
            'Course Modules',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < course.modules.length; i++)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.iconBackground,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                    title: Text(course.modules[i].title),
                    subtitle: Text(
                      '${course.modules[i].lessonCount} lessons • ${course.modules[i].duration}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // AI Suggestion: Similar Courses ("Students who viewed this also viewed...")
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups_rounded, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Students who viewed this also viewed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Based on views, enrollments, and shared topic tags',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_loadingSimilar)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            )
          else if (_similarCourses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'Explore more courses from Discover to view peer recommendations.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            )
          else
            ..._similarCourses.map((sim) {
              final simCourseId = sim['courseId']?.toString();
              final simScore = sim['similarityScore'] ?? 85;
              final reasoning = sim['reasoning']?.toString() ?? 'Popular similar course explored by students';
              final matchingCourse = allCourses.firstWhere(
                (c) => c.id == simCourseId,
                orElse: () => allCourses.first,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded, size: 12, color: AppTheme.primaryColor),
                              SizedBox(width: 4),
                              Text(
                                'Co-Viewed',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$simScore% Similarity',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reasoning,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CourseCard(
                      course: matchingCourse,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailsScreen(
                              course: matchingCourse,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () async {
              await LearningStore.instance.enroll(course);
              if (!context.mounted) {
                return;
              }
              context.go('/learning/my-courses');
            },
            child:
                Text(course.enrolled ? 'Go to My Learning' : 'Enroll Now'),
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, LearningCourse course) {
    ReportReason reason = ReportReason.spam;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Report Course'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ReportReason>(
                    initialValue: reason,
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
                    reportedUserId: 'provider_123', // Dummy provider ID for mock course
                    reportedUserName: course.instructor,
                    relatedContentId: course.id,
                    relatedContentType: 'Course',
                    relatedContentTitle: course.title,
                    reason: reason,
                    description: descriptionController.text,
                    severity: ReportSeverity.medium,
                  );
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully.')));
                    
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Block Instructor?'),
                        content: Text('Would you also like to block ${course.instructor} so you no longer see their content?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('No'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${course.instructor} blocked.')),
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
}

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key});

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  List<Lesson> _published = [];
  List<ProviderSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    FirebaseLessonService.instance.addListener(_load);
    StudentLessonStore.instance.addListener(_onStoreChanged);
    SessionService.instance.addListener(_load);
    LearningStore.instance.loadEnrollments();
    _load();
  }

  @override
  void dispose() {
    FirebaseLessonService.instance.removeListener(_load);
    StudentLessonStore.instance.removeListener(_onStoreChanged);
    SessionService.instance.removeListener(_load);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  String get _learnerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _firstName {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (name == null || name.isEmpty) return '';
    return name.split(' ').first;
  }

  Future<void> _load() async {
    final lessons = await FirebaseLessonService.instance.getPublishedLessons();
    await StudentLessonStore.instance.load();
    final learnerId = _learnerId;
    final sessions = learnerId.isEmpty
        ? <ProviderSession>[]
        : await SessionService.instance.getSessionsByLearner(learnerId);
    if (!mounted) return;
    setState(() {
      _published = lessons;
      _sessions = sessions;
      _loading = false;
    });
  }

  ProviderSession? _nextSessionFor(String lessonId) {
    final upcoming = _sessions
        .where(
          (session) =>
              session.lessonId == lessonId &&
              session.status == SessionStatus.upcoming,
        )
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<void> _removeLesson(Lesson lesson) async {
    await StudentLessonStore.instance.unenroll(lesson.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${lesson.title} removed from My Learning.')),
    );
  }

  Future<void> _downloadCertificateForCourse(LearningCourse course) async {
    try {
      final document = pw.Document();
      document.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'CERTIFICATE OF COMPLETION',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 24),
                pw.Text('This certifies that the learner successfully completed'),
                pw.SizedBox(height: 8),
                pw.Text(
                  course.title,
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
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
      final bytes = await document.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'peerlearnhub-course-${course.id}-certificate.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download certificate: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LearningCourse>>(
      valueListenable: LearningStore.instance,
      builder: (context, courses, _) {
        final enrolledCourses =
            courses.where((course) => course.enrolled).toList();
        final teacherLessons =
            StudentLessonStore.instance.enrolledFrom(_published);
        final upcomingSessions = _sessions
            .where((session) => session.status == SessionStatus.upcoming)
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        final isEmpty = teacherLessons.isEmpty && enrolledCourses.isEmpty;
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              await Future.wait([
                _load(),
                LearningStore.instance.loadEnrollments(),
              ]);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _MyLearningHeader(
                    greeting: _firstName.isEmpty
                        ? 'Keep learning'
                        : 'Keep going, $_firstName',
                    onProfile: () => context.push('/profile'),
                    onLogout: () {
                      AppAuth.instance.logout();
                      context.go('/login');
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SessionsShortcutCard(
                        upcomingCount: upcomingSessions.length,
                        nextSession: upcomingSessions.isEmpty
                            ? null
                            : upcomingSessions.first,
                        onTap: () => context.push('/learning/sessions'),
                      ),
                      const SizedBox(height: 20),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      else if (isEmpty)
                        _MyLearningEmptyState(
                          onBrowse: () => context.go('/learning'),
                        )
                      else ...[
                        if (teacherLessons.isNotEmpty) ...[
                          _DiscoverSectionHeader(
                            title: 'My lessons',
                            subtitle: teacherLessons.length == 1
                                ? '1 lesson you added'
                                : '${teacherLessons.length} lessons you added',
                          ),
                          const SizedBox(height: 12),
                          ...teacherLessons.map(
                            (lesson) => _EnrolledLessonCard(
                              lesson: lesson,
                              nextSession: _nextSessionFor(lesson.id),
                              onOpen: () => context.push(
                                '/learning/provider-lesson',
                                extra: lesson,
                              ),
                              onRemove: () => _removeLesson(lesson),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (enrolledCourses.isNotEmpty) ...[
                          _DiscoverSectionHeader(
                            title: 'My courses',
                            subtitle: enrolledCourses.length == 1
                                ? '1 course in progress'
                                : '${enrolledCourses.length} courses in progress',
                          ),
                          const SizedBox(height: 12),
                          ...enrolledCourses.map(
                            (course) => Column(
                              children: [
                                LearningCourseCard(
                                  course: course,
                                  onContinue: () => context.push(
                                    '/learning/lesson',
                                    extra: course,
                                  ),
                                  onTap: () => context.push(
                                    '/learning/course',
                                    extra: course,
                                  ),
                                ),
                                if (course.progress >= 100)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: FilledButton.icon(
                                        onPressed: () => _downloadCertificateForCourse(course),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        icon: const Icon(Icons.workspace_premium),
                                        label: const Text('Download Certificate (PDF)'),
                                      ),
                                    ),
                                  )
                                else if (LearningStore.instance
                                    .canSubmitAssignment(course))
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: OutlinedButton.icon(
                                        onPressed: () => context.push(
                                          '/learning/assignment',
                                          extra: course,
                                        ),
                                        icon: const Icon(
                                          Icons.assignment_outlined,
                                        ),
                                        label: const Text('Submit assignment'),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const _LearningNav(index: 1),
        );
      },
    );
  }
}

class LessonViewScreen extends StatefulWidget {
  const LessonViewScreen({super.key, required this.course});

  final LearningCourse course;

  @override
  State<LessonViewScreen> createState() => _LessonViewScreenState();
}

class _LessonViewScreenState extends State<LessonViewScreen> {
  bool _playing = false;
  int _selectedLesson = 0;
  final _message = TextEditingController();
  final List<String> _messages = ['Great explanation of widget composition!'];

  List<MiniVideoLesson> get _lessons => widget.course.videoLessons;

  MiniVideoLesson? get _currentLesson =>
      _lessons.isEmpty ? null : _lessons[_selectedLesson];

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _currentLesson;
    final completedProgress = _lessons.isEmpty
        ? 0
        : (((_selectedLesson + 1) / _lessons.length) * 100).round();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrGo(context, '/learning/my-courses'),
        ),
        actions: const [RoleSwitcherButton(), SizedBox(width: 4)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Course lessons',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _lessons.isEmpty
                ? 'Lessons are being prepared.'
                : 'Lesson ${_selectedLesson + 1} of ${_lessons.length}',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF102A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _playing = !_playing),
                    iconSize: 64,
                    color: Colors.white,
                    icon: Icon(
                      _playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 16,
                    right: 16,
                    child: LinearProgressIndicator(
                      value: completedProgress / 100,
                      color: AppTheme.primaryLight,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (lesson != null) ...[
            Text(
              lesson.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${lesson.duration} · ${lesson.description}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
          ],
          if (_lessons.isNotEmpty) ...[
            Text(
              'Up next',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(_lessons.length, (index) {
              final item = _lessons[index];
              final selected = index == _selectedLesson;
              return Card(
                color: selected
                    ? AppTheme.primaryColor.withValues(alpha: .10)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(item.title),
                  subtitle: Text('${item.duration} · ${item.description}'),
                  trailing: Icon(
                    selected ? Icons.play_circle_fill : Icons.play_circle_outline,
                    color: AppTheme.primaryColor,
                  ),
                  onTap: () => setState(() {
                    _selectedLesson = index;
                    _playing = false;
                  }),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
          Text(
            'Discussion',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          ..._messages.map(
            (message) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Learner'),
              subtitle: Text(message),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _message,
                  decoration: const InputDecoration(hintText: 'Discussion...'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                onPressed: () {
                  if (_message.text.trim().isNotEmpty) {
                    setState(() {
                      _messages.add(_message.text.trim());
                      _message.clear();
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: lesson == null
                ? null
                : () async {
                    await LearningStore.instance.updateProgress(
                      widget.course,
                      completedProgress,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    context.push(
                      '/learning/quiz',
                      extra: quizForModule(
                        widget.course,
                        _selectedLesson % widget.course.modules.length,
                      ),
                    );
                  },
            child: Text(
              lesson == null
                  ? 'Course lessons coming soon'
                  : 'Complete lesson and take quiz',
            ),
          ),
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.quiz});

  final LearningQuiz quiz;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _questionIndex = 0;
  int _attemptsForQuestion = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _checking = false;

  QuizQuestion get _question => widget.quiz.questions[_questionIndex];

  Future<void> _submitAnswer() async {
    final selected = _selectedIndex;
    if (selected == null || _checking) {
      return;
    }

    setState(() => _checking = true);
    final correct = selected == _question.correctIndex;
    if (!correct) {
      setState(() {
        _attemptsForQuestion++;
        _selectedIndex = null;
        _checking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not quite. Try this question again.')),
      );
      return;
    }

    final earned = _attemptsForQuestion == 0 ? 5 : 3;
    final newScore = _score + earned;
    if (_questionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _score = newScore;
        _questionIndex++;
        _attemptsForQuestion = 0;
        _selectedIndex = null;
        _checking = false;
      });
      return;
    }

    final total = await LearningStore.instance.saveQuizPoints(
      course: _courseForQuiz,
      moduleId: widget.quiz.moduleId,
      points: newScore,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _score = newScore;
      _checking = false;
    });
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz complete!'),
        content: Text(
          'You earned $newScore points. Your total is $total points.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/learning/my-courses');
            },
            child: const Text('Back to My Courses'),
          ),
        ],
      ),
    );
  }

  LearningCourse get _courseForQuiz => LearningStore.instance.value.firstWhere(
        (course) => course.id == widget.quiz.courseId,
      );

  @override
  Widget build(BuildContext context) {
    final progress = (_questionIndex + 1) / widget.quiz.questions.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.quiz.moduleTitle} Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrGo(context, '/learning/my-courses'),
        ),
        actions: const [RoleSwitcherButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinearProgressIndicator(
            value: progress,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Question ${_questionIndex + 1} of ${widget.quiz.questions.length}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _question.question,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          RadioGroup<int>(
            groupValue: _selectedIndex,
            onChanged: (value) {
              if (_checking) return;             // early exit instead of null
              setState(() => _selectedIndex = value);
            },
            child: Column(
              children: [
                for (var i = 0; i < _question.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RadioListTile<int>(
                      value: i,
                      title: Text(_question.options[i]),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: _selectedIndex == i
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed:
                _selectedIndex == null || _checking ? null : _submitAnswer,
            child: Text(
              _questionIndex == widget.quiz.questions.length - 1
                  ? 'Finish Quiz'
                  : 'Check Answer',
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text('Quiz points: $_score')),
        ],
      ),
    );
  }
}

class TeacherLessonCard extends StatelessWidget {
  const TeacherLessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = ReviewService.instance.averageForLesson(lesson.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CatalogThumb(
                  image: lessonImageProvider(lesson.imageUrl),
                  icon: _categoryIcon(lesson.category.label),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              lesson.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PriceBadge(
                            label: formatLessonPrice(lesson),
                            emphasize: lesson.isFree,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            icon: _categoryIcon(lesson.category.label),
                            label: lesson.category.label,
                          ),
                          _InfoChip(label: lesson.skillLevel.label),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CatalogMetaRow(
                        rating: rating,
                        duration: lesson.duration,
                        extra: lesson.lessonType.label,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, required this.onTap});

  final LearningCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CatalogThumb(
                  icon: _categoryIcon(course.category),
                  backgroundColor: Color(course.colorValue),
                  iconColor: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            icon: _categoryIcon(course.category),
                            label: course.category,
                          ),
                          _InfoChip(label: course.level),
                          if (course.enrollmentCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${course.enrollmentCount} local ${course.enrollmentCount == 1 ? 'learner' : 'learners'}',
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CatalogMetaRow(
                        rating: course.rating,
                        duration: course.duration,
                        extra: 'By ${course.instructor}',
                        isInstructorVerified: course.isInstructorVerified,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LearningCourseCard extends StatelessWidget {
  const LearningCourseCard({
    super.key,
    required this.course,
    required this.onContinue,
    required this.onTap,
  });

  final LearningCourse course;
  final VoidCallback onContinue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(course.colorValue),
                      child: const Icon(Icons.school, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${course.progress}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: course.progress / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.primaryColor,
                  backgroundColor: AppTheme.iconBackground,
                ),
                const SizedBox(height: 8),
                Text(
                  course.progress == 0
                      ? 'Not started yet'
                      : '${course.progress}% complete',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: onContinue,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyLearningHeader extends StatelessWidget {
  const _MyLearningHeader({
    required this.greeting,
    required this.onProfile,
    required this.onLogout,
  });

  final String greeting;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Learning',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const NotificationBellButton(onDark: true),
                  const RoleSwitcherButton(onDark: true),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onProfile,
                    icon: const Icon(Icons.person, color: Colors.white),
                    tooltip: 'Profile',
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                greeting,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lessons you added and sessions you booked',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionsShortcutCard extends StatelessWidget {
  const _SessionsShortcutCard({
    required this.upcomingCount,
    required this.nextSession,
    required this.onTap,
  });

  final int upcomingCount;
  final ProviderSession? nextSession;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = nextSession == null
        ? 'Upcoming classes, reminders, and feedback'
        : 'Next: ${nextSession!.lessonTitle} · ${formatDateTime(nextSession!.scheduledAt)}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: AppTheme.cardDecoration.copyWith(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: AppTheme.iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_available_outlined,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Sessions',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: upcomingCount == 0
                        ? AppTheme.backgroundColor
                        : AppTheme.iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    upcomingCount == 0 ? 'None' : '$upcomingCount upcoming',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: upcomingCount == 0
                          ? AppTheme.textSecondary
                          : AppTheme.primaryDark,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyLearningEmptyState extends StatelessWidget {
  const _MyLearningEmptyState({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppTheme.iconBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nothing in My Learning yet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Open a lesson on Discover and tap Add to My Learning. It will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onBrowse,
            child: const Text('Browse lessons'),
          ),
        ],
      ),
    );
  }
}

class _EnrolledLessonCard extends StatefulWidget {
  const _EnrolledLessonCard({
    required this.lesson,
    required this.onOpen,
    required this.onRemove,
    this.nextSession,
  });

  final Lesson lesson;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final ProviderSession? nextSession;

  @override
  State<_EnrolledLessonCard> createState() => _EnrolledLessonCardState();
}

class _EnrolledLessonCardState extends State<_EnrolledLessonCard> {
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkCompletion();
  }

  Future<void> _checkCompletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('assignments')
          .doc(widget.lesson.id)
          .get();
      if (doc.exists && mounted) {
        setState(() => _isCompleted = true);
      }
    } catch (e) {
      debugPrint('Error checking lesson completion: $e');
    }
  }

  Future<void> _downloadCertificate() async {
    try {
      final document = pw.Document();
      document.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'CERTIFICATE OF COMPLETION',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 24),
                pw.Text('This certifies that the learner successfully completed'),
                pw.SizedBox(height: 8),
                pw.Text(
                  widget.lesson.title,
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
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
      final bytes = await document.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'peerlearnhub-lesson-${widget.lesson.id}-certificate.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download certificate: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CatalogThumb(
                      image: lessonImageProvider(widget.lesson.imageUrl),
                      icon: _categoryIcon(widget.lesson.category.label),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.lesson.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (_isCompleted) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _InfoChip(
                                icon: _categoryIcon(widget.lesson.category.label),
                                label: widget.lesson.category.label,
                              ),
                              _InfoChip(label: widget.lesson.skillLevel.label),
                            ],
                          ),
                          if (widget.nextSession != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Next session · ${formatDateTime(widget.nextSession!.scheduledAt)}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Lesson options',
                      onSelected: (value) {
                        if (value == 'remove') widget.onRemove();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove from My Learning'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: widget.onOpen,
                        child: const Text('Continue'),
                      ),
                    ),
                    if (_isCompleted) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _downloadCertificate,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          icon: const Icon(Icons.workspace_premium, size: 18),
                          label: const Text('Certificate'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseHero extends StatelessWidget {
  const _CourseHero({required this.course});

  final LearningCourse course;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: Color(course.colorValue),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 70),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          course.title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          course.description,
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 8),
            Text(course.instructor),
            const Spacer(),
            const Icon(Icons.star_rounded, color: Colors.amber),
            Text(' ${course.rating}'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(course.level)),
            Chip(label: Text(course.duration)),
          ],
        ),
      ],
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader({
    required this.greeting,
    required this.searchController,
    required this.onQueryChanged,
    this.onSubmitted,
    required this.onProfile,
    required this.onLogout,
  });

  final String greeting;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Discover',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const NotificationBellButton(onDark: true),
                  const RoleSwitcherButton(onDark: true),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onProfile,
                    icon: const Icon(Icons.person, color: Colors.white),
                    tooltip: 'Profile',
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                greeting,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find a skill and start learning today',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search lessons, skills, or topics',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            searchController.clear();
                            onQueryChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white, width: 0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverSectionHeader extends StatelessWidget {
  const _DiscoverSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DiscoverCategoryBar extends StatelessWidget {
  const _DiscoverCategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(category),
              borderRadius: BorderRadius.circular(21),
              child: Ink(
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : const Color(0xFFE2E6EA),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _categoryIcon(category),
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DiscoverEmptyState extends StatelessWidget {
  const _DiscoverEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppTheme.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogThumb extends StatelessWidget {
  const _CatalogThumb({
    this.image,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
  });

  final ImageProvider? image;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 88,
        height: 88,
        child: image == null
            ? _placeholder()
            : Image(
                image: image!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: backgroundColor ?? AppTheme.iconBackground,
      child: Icon(
        icon,
        color: iconColor ?? AppTheme.primaryColor,
        size: 32,
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.label, required this.emphasize});

  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: emphasize ? AppTheme.statusActiveBg : AppTheme.iconBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: emphasize ? AppTheme.statusActiveText : AppTheme.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({this.icon, required this.label});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogMetaRow extends StatelessWidget {
  const _CatalogMetaRow({
    required this.rating,
    required this.duration,
    this.extra,
    this.isInstructorVerified = false,
  });

  final double rating;
  final String duration;
  final String? extra;
  final bool isInstructorVerified;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          rating == 0 ? Icons.auto_awesome_rounded : Icons.star_rounded,
          color: rating == 0 ? AppTheme.primaryColor : const Color(0xFFF5A623),
          size: 15,
        ),
        const SizedBox(width: 3),
        Text(
          rating == 0 ? 'New' : rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        if (duration.trim().isNotEmpty) ...[
          _metaDot(),
          Flexible(
            child: Text(
              duration,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
        if (extra != null && extra!.trim().isNotEmpty) ...[
          _metaDot(),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    extra!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                if (isInstructorVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 14, color: Colors.blue),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _metaDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 3,
        height: 3,
        decoration: const BoxDecoration(
          color: AppTheme.textSecondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'all':
      return Icons.apps_rounded;
    case 'mobile':
      return Icons.smartphone_rounded;
    case 'web':
      return Icons.language_rounded;
    case 'ai':
      return Icons.auto_awesome_rounded;
    case 'ui/ux':
    case 'design':
      return Icons.palette_outlined;
    case 'backend':
    case 'database':
      return Icons.storage_rounded;
    case 'programming':
      return Icons.code_rounded;
    case 'business':
      return Icons.work_outline_rounded;
    case 'languages':
      return Icons.translate_rounded;
    case 'music':
      return Icons.music_note_rounded;
    case 'photography':
      return Icons.photo_camera_outlined;
    case 'cooking':
      return Icons.restaurant_rounded;
    default:
      return Icons.category_outlined;
  }
}

class _LearningNav extends StatelessWidget {
  const _LearningNav({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.iconBackground,
      onDestinationSelected: (value) {
        if (value == 0) {
          context.go('/learning');
        } else if (value == 1) {
          context.go('/learning/my-courses');
        } else if (value == 2) {
          context.go('/skill-exchange');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore, color: AppTheme.primaryColor),
          label: 'Discover',
        ),
        NavigationDestination(
          icon: Icon(Icons.play_lesson_outlined),
          selectedIcon: Icon(Icons.play_lesson, color: AppTheme.primaryColor),
          label: 'My Learning',
        ),
        NavigationDestination(
          icon: Icon(Icons.swap_horiz_outlined),
          selectedIcon: Icon(Icons.swap_horiz, color: AppTheme.primaryColor),
          label: 'Skill Exchange',
        ),
      ],
    );
  }
}
