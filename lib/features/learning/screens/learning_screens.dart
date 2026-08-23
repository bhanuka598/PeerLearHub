import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../data/learning_store.dart';
import '../models/learning_course.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _category = 'All';
  String _query = '';
  static const _categories = ['All', 'Mobile', 'Web', 'AI', 'UI/UX', 'Backend', 'Database'];

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<LearningCourse>>(
        valueListenable: LearningStore.instance,
        builder: (context, courses, _) {
          final visible = courses.where((course) =>
              (_category == 'All' || course.category == _category) &&
              ('${course.title} ${course.category} ${course.instructor}'.toLowerCase().contains(_query.toLowerCase()))).toList();
          return Scaffold(
            appBar: AppBar(
              title: const Text('PeerLearnHub'),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    AppAuth.instance.currentRole?.name.toUpperCase() ?? 'GUEST',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/learning/my-courses'),
                  icon: const Icon(Icons.school_outlined),
                ),
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
            body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), children: [
              Text('Find Your Next Skill', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(onChanged: (value) => setState(() => _query = value), decoration: const InputDecoration(hintText: 'Search for courses, skills, topics...', prefixIcon: Icon(Icons.search))),
              const SizedBox(height: 24),
              Text('Explore Categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (context, index) { final category = _categories[index]; return ChoiceChip(label: Text(category), selected: _category == category, selectedColor: AppTheme.primaryColor.withValues(alpha: .18), onSelected: (_) => setState(() => _category = category)); })),
              const SizedBox(height: 24),
              Text('Popular courses', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (visible.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No courses match your search.'))),
              ...visible.map((course) => CourseCard(course: course, onTap: () => context.push('/learning/course', extra: course))),
            ])),
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
    body: ListView(padding: const EdgeInsets.all(16), children: [
      _CourseHero(course: course), const SizedBox(height: 24),
      Text('Course Modules', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 12),
      Card(child: Column(children: [for (var i = 0; i < course.modules.length; i++) ListTile(leading: CircleAvatar(backgroundColor: AppTheme.iconBackground, child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primaryColor))), title: Text(course.modules[i].title), subtitle: Text('${course.modules[i].lessonCount} lessons • ${course.modules[i].duration}'), trailing: const Icon(Icons.chevron_right))])),
    ]),
    bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton(onPressed: () { LearningStore.instance.enroll(course); context.go('/learning/my-courses'); }, child: Text(course.enrolled ? 'Go to My Learning' : 'Enroll Now')))),
  );
}

class MyLearningScreen extends StatelessWidget {
  const MyLearningScreen({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<LearningCourse>>(
    valueListenable: LearningStore.instance,
    builder: (context, courses, _) { final enrolled = courses.where((course) => course.enrolled).toList(); return Scaffold(appBar: AppBar(title: const Text('My Courses')), body: ListView(padding: const EdgeInsets.all(16), children: [if (enrolled.isEmpty) const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Enroll in a course to start learning.'))), ...enrolled.map((course) => LearningCourseCard(course: course, onContinue: () => context.push('/learning/lesson', extra: course), onTap: () => context.push('/learning/course', extra: course)))]), bottomNavigationBar: _LearningNav(index: 1)); },
  );
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
        actions: const [Icon(Icons.more_vert)],
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
                      _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
              child: const Icon(Icons.play_lesson_outlined, color: Colors.white, size: 42),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${course.category} • ${course.level}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
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
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
      onDestinationSelected: (value) => context.go(
        value == 0 ? '/learning' : '/learning/my-courses',
      ),
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
