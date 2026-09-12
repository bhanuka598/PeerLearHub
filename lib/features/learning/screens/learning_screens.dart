import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_auth.dart';
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

  @override
  void initState() {
    super.initState();
    FirebaseLessonService.instance.addListener(_loadTeacherLessons);
    ReviewService.instance.addListener(_onReviewsChanged);
    StudentLessonStore.instance.load();
    ReviewService.instance.refresh();
    _loadTeacherLessons();
    LearningStore.instance.loadEnrollments();
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
                      onProfile: () => context.go('/profile'),
                      onLogout: () {
                        AppAuth.instance.logout();
                        context.go('/');
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
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
                        _DiscoverSectionHeader(
                          title: 'Popular courses',
                          subtitle: visibleCourses.isEmpty
                              ? 'Self-paced learning paths'
                              : '${visibleCourses.length} to explore',
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

class CourseDetailsScreen extends StatelessWidget {
  const CourseDetailsScreen({super.key, required this.course});
  final LearningCourse course;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Course details')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    onProfile: () => context.go('/profile'),
                    onLogout: () {
                      AppAuth.instance.logout();
                      context.go('/');
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
                                if (LearningStore.instance
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
  final _message = TextEditingController();
  final List<String> _messages = ['Great explanation of widget composition!'];

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.modules[2].title),
        actions: const [RoleSwitcherButton(), SizedBox(width: 4)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                      value: widget.course.progress / 100,
                      color: AppTheme.primaryLight,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
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
            onPressed: () async {
              await LearningStore.instance.updateProgress(
                widget.course,
                widget.course.progress + 5,
              );
              if (!context.mounted) {
                return;
              }
              context.push(
                '/learning/quiz',
                extra: quizForModule(widget.course, 2),
              );
            },
            child: const Text('Complete lesson and take quiz'),
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
          for (var i = 0; i < _question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RadioListTile<int>(
                value: i,
                groupValue: _selectedIndex,
                onChanged: _checking
                    ? null
                    : (value) => setState(() => _selectedIndex = value),
                title: Text(_question.options[i]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: _selectedIndex == i
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : null,
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
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CatalogMetaRow(
                        rating: course.rating,
                        duration: course.duration,
                        extra: 'By ${course.instructor}',
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

class _EnrolledLessonCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          Text(
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
                          if (nextSession != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Next session · ${formatDateTime(nextSession!.scheduledAt)}',
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
                        if (value == 'remove') onRemove();
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onOpen,
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
    required this.onProfile,
    required this.onLogout,
  });

  final String greeting;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
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
  });

  final double rating;
  final String duration;
  final String? extra;

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