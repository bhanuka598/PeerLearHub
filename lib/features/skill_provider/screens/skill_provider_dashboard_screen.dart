import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/lesson.dart';
import '../../../models/provider_dashboard_stats.dart';
import '../models/teacher_profile.dart';
import '../services/firebase_lesson_service.dart';
import '../services/teacher_profile_service.dart';
import '../utils/provider_id_helper.dart';
import '../widgets/app_header.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_lesson_tile.dart';
import '../widgets/stat_card.dart';

class SkillProviderDashboardScreen extends StatefulWidget {
  const SkillProviderDashboardScreen({super.key});

  @override
  State<SkillProviderDashboardScreen> createState() =>
      _SkillProviderDashboardScreenState();
}

class _SkillProviderDashboardScreenState
    extends State<SkillProviderDashboardScreen> {
  final _lessonService = FirebaseLessonService.instance;
  final _profileService = TeacherProfileService.instance;
  ProviderDashboardStats? _stats;
  List<Lesson> _recentLessons = [];
  TeacherProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _lessonService.addListener(_onDataChanged);
    _profileService.addListener(_onProfileChanged);
    _loadStats();
  }

  @override
  void dispose() {
    _lessonService.removeListener(_onDataChanged);
    _profileService.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onDataChanged() {
    _loadStats();
  }

  void _onProfileChanged() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    final providerId = await ensureProviderId();
    try {
      final stats = await _lessonService.getDashboardStats(providerId);
      final recent = await _lessonService.getRecentLessons(providerId);
      final profile = await _profileService.getProfile(providerId);
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentLessons = recent;
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/skill-provider/create'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadStats,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ListenableBuilder(
                listenable: _profileService,
                builder: (context, _) {
                  final profile = _profileService.currentProfile ?? _profile;
                  return TealDashboardHeader(
                    title: 'Dashboard',
                    welcomeTitle: 'Welcome back',
                    welcomeSubtitle:
                        'Share your skills and manage your lessons.',
                    profileImageUrl: profile?.profileImageUrl,
                    profileInitial: (profile?.displayName.isNotEmpty ?? false)
                        ? profile!.displayName[0].toUpperCase()
                        : 'T',
                    onProfileTap: () =>
                        context.push('/skill-provider/profile'),
                    onRefresh: _loadStats,
                    onLogout: () {
                      AppAuth.instance.logout();
                      context.go('/');
                    },
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle(title: 'Overview'),
                        _buildStatsSection(context),
                        const SizedBox(height: 22),
                        const SectionTitle(title: 'Quick actions'),
                        _buildQuickActions(context),
                        const SizedBox(height: 22),
                        _buildRecentLessons(context, _recentLessons),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    if (_isLoading || _stats == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final stats = _stats!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total lessons',
                value: '${stats.totalLessons}',
                icon: Icons.menu_book_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Active',
                value: '${stats.activeLessons}',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Pending',
                value: '${stats.pendingRequests}',
                icon: Icons.hourglass_empty,
                color: const Color(0xFFEF6C00),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Completed',
                value: '${stats.completedLessons}',
                icon: Icons.task_alt_outlined,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = <(String, String, IconData, String)>[
      (
        'Create lesson',
        'Publish a new offering',
        Icons.add_circle_outline,
        '/skill-provider/create',
      ),
      (
        'My lessons',
        'Manage your listings',
        Icons.list_alt_outlined,
        '/skill-provider/my-lessons',
      ),
      (
        'Bookings',
        'Review learner requests',
        Icons.pending_actions_outlined,
        '/skill-provider/bookings',
      ),
      (
        'Sessions',
        'Upcoming classes',
        Icons.event_outlined,
        '/skill-provider/sessions',
      ),
      (
        'Notifications',
        'Reminders and alerts',
        Icons.notifications_outlined,
        '/notifications',
      ),
      (
        'Messages',
        'Chat with learners',
        Icons.message_outlined,
        '/skill-provider/messages',
      ),
      (
        'Reviews',
        'Student feedback',
        Icons.star_outline,
        '/skill-provider/reviews',
      ),
      (
        'Profile',
        'Skills and bio',
        Icons.person_outline,
        '/skill-provider/profile',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 118,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return QuickActionCard(
          title: action.$1,
          subtitle: action.$2,
          icon: action.$3,
          onTap: () => context.push(action.$4),
        );
      },
    );
  }

  Widget _buildRecentLessons(BuildContext context, List<Lesson> lessons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Recent Lessons',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            if (lessons.isNotEmpty)
              TextButton(
                onPressed: () {
                  context.push('/skill-provider/my-lessons');
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (lessons.isEmpty)
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No lessons yet. Create your first lesson to get started!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ),
          )
        else
          ...lessons.map(
            (lesson) => RecentLessonTile(lesson: lesson),
          ),
      ],
    );
  }
}
