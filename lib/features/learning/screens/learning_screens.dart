import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../../../core/widgets/role_switcher_button.dart';
import '../../notifications/widgets/notification_bell_button.dart';
import '../../../models/lesson.dart';
import '../../skill_provider/services/firebase_lesson_service.dart';
import '../../skill_provider/services/review_service.dart';
import '../data/learning_store.dart';
import '../data/student_lesson_store.dart';
import '../models/learning_course.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _category = 'All';
  String _query = '';
  List<Lesson> _teacherLessons = [];
  static const _categories = [
    'All',
    'Mobile',
    'Web',
    'AI',
    'UI/UX',
    'Backend',
    'Database',
  ];

  @override
  void initState() {
    super.initState();
    FirebaseLessonService.instance.addListener(_loadTeacherLessons);
    ReviewService.instance.addListener(_onReviewsChanged);
    StudentLessonStore.instance.load();
    ReviewService.instance.refresh();
    _loadTeacherLessons();
  }

  @override
  void dispose() {
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
      setState(() => _teacherLessons = lessons);
    }
  }

  List<Lesson> get _visibleTeacherLessons {
    final query = _query.toLowerCase();
    return _teacherLessons.where((lesson) {
      final matchesQuery = query.isEmpty ||
          '${lesson.title} ${lesson.category.label} ${lesson.description}'
              .toLowerCase()
              .contains(query);
      return matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<LearningCourse>>(
        valueListenable: LearningStore.instance,
        builder: (context, courses, _) {
          final visible = courses
              .where(
                (course) =>
                    (_category == 'All' || course.category == _category) &&
                    ('${course.title} ${course.category} ${course.instructor}'
                        .toLowerCase()
                        .contains(_query.toLowerCase())),
              )
              .toList();
          return Scaffold(
            appBar: AppBar(
              title: const Text('PeerLearnHub'),
              actions: [
                const NotificationBellButton(onDark: true),
                const RoleSwitcherButton(onDark: true),
                IconButton(
                  onPressed: () {
                    AppAuth.instance.logout();
                    context.go('/');
                  },
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Text(
                    'Find Your Next Skill',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search for courses, skills, topics...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Explore Categories',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          selectedColor: AppTheme.primaryColor.withValues(
                            alpha: .18,
                          ),
                          onSelected: (_) =>
                              setState(() => _category = category),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Lessons from teachers',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_visibleTeacherLessons.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'No published lessons yet. Teachers can add one from Create Lesson.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  else
                    ..._visibleTeacherLessons.map(
                      (lesson) => TeacherLessonCard(
                        lesson: lesson,
                        onTap: () => context.push(
                          '/learning/provider-lesson',
                          extra: lesson,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Popular courses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No courses match your search.'),
                      ),
                    ),
                  ...visible.map(
                    (course) => CourseCard(
                      course: course,
                      onTap: () =>
                          context.push('/learning/course', extra: course),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _LearningNav(index: 0),
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
          onPressed: () {
            LearningStore.instance.enroll(course);
            context.go('/learning/my-courses');
          },
          child: Text(course.enrolled ? 'Go to My Learning' : 'Enroll Now'),
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

  @override
  void initState() {
    super.initState();
    FirebaseLessonService.instance.addListener(_load);
    StudentLessonStore.instance.addListener(_onStoreChanged);
    StudentLessonStore.instance.load();
    _load();
  }

  @override
  void dispose() {
    FirebaseLessonService.instance.removeListener(_load);
    StudentLessonStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final lessons = await FirebaseLessonService.instance.getPublishedLessons();
    if (mounted) setState(() => _published = lessons);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LearningCourse>>(
      valueListenable: LearningStore.instance,
      builder: (context, courses, _) {
        final enrolled = courses.where((course) => course.enrolled).toList();
        final teacherLessons =
            StudentLessonStore.instance.enrolledFrom(_published);
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Courses'),
            actions: const [
              NotificationBellButton(),
              RoleSwitcherButton(),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.event_available_outlined,
                  color: AppTheme.primaryColor,
                ),
                title: const Text('My Sessions'),
                subtitle: const Text('Upcoming classes, reminders, and feedback'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/learning/sessions'),
              ),
              const SizedBox(height: 12),
              if (teacherLessons.isEmpty && enrolled.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('Add a lesson or enroll in a course to start learning.'),
                  ),
                ),
              if (teacherLessons.isNotEmpty) ...[
                Text(
                  'My lessons',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...teacherLessons.map(
                  (lesson) => TeacherLessonCard(
                    lesson: lesson,
                    onTap: () => context.push(
                      '/learning/provider-lesson',
                      extra: lesson,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              ...enrolled.map(
                (course) => LearningCourseCard(
                  course: course,
                  onContinue: () =>
                      context.push('/learning/lesson', extra: course),
                  onTap: () => context.push('/learning/course', extra: course),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _LearningNav(index: 1),
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
            onPressed: () {
              LearningStore.instance.updateProgress(
                widget.course,
                widget.course.progress + 5,
              );
              context.go('/learning/my-courses');
            },
            child: const Text('Mark lesson complete'),
          ),
        ),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 106,
              height: 132,
              child: _thumb(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${lesson.category.label} • ${lesson.skillLevel.label}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        Text(rating == 0 ? ' New' : ' ${rating.toStringAsFixed(1)}'),
                        const Spacer(),
                        Text(
                          lesson.duration,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatLessonPrice(lesson),
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget _thumb() {
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
          errorBuilder: (_, _, _) => _thumbPlaceholder(),
        );
      }
    }
    if (hasImage && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _thumbPlaceholder(),
      );
    }
    return _thumbPlaceholder();
  }

  Widget _thumbPlaceholder() {
    return const ColoredBox(
      color: AppTheme.iconBackground,
      child: Icon(Icons.image_outlined, color: AppTheme.primaryColor, size: 36),
    );
  }
}

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, required this.onTap});

  final LearningCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 106,
              height: 132,
              color: Color(course.colorValue),
              child: const Icon(
                Icons.play_lesson_outlined,
                color: Colors.white,
                size: 42,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${course.category} • ${course.level}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        Text(' ${course.rating}'),
                        const Spacer(),
                        Text(
                          course.duration,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By ${course.instructor}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text('${course.progress}%'),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: course.progress / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text(
                '${course.progress}% Complete',
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
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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

class _LearningNav extends StatelessWidget {
  const _LearningNav({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) =>
          context.go(value == 0 ? '/learning' : '/learning/my-courses'),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Discover',
        ),
        NavigationDestination(
          icon: Icon(Icons.play_lesson_outlined),
          selectedIcon: Icon(Icons.play_lesson),
          label: 'My Learning',
        ),
      ],
    );
  }
}
