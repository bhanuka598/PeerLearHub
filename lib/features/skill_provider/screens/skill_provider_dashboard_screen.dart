import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/lesson.dart';
import '../../../models/provider_dashboard_stats.dart';
import '../../../services/lesson_service.dart';
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
  final _lessonService = DemoLessonService.instance;
  ProviderDashboardStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _lessonService.addListener(_onDataChanged);
    _loadStats();
  }

  @override
  void dispose() {
    _lessonService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _lessonService.getDashboardStats(
      AppConstants.demoProviderId,
    );
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentLessons = _lessonService.getRecentLessons(
      AppConstants.demoProviderId,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadStats,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: TealDashboardHeader(
                title: 'Skill Provider Dashboard',
                welcomeTitle: 'Welcome Back!',
                welcomeSubtitle:
                    'Share your knowledge and help others learn new skills.',
                onRefresh: _loadStats,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle(title: 'Lesson Overview'),
                        _buildStatsSection(context),
                        const SizedBox(height: 24),
                        const SectionTitle(title: 'Quick Actions'),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildRecentLessons(context, recentLessons),
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
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final stats = _stats!;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          title: 'Total Lessons',
          value: '${stats.totalLessons}',
          icon: Icons.menu_book_outlined,
          color: AppTheme.primaryColor,
        ),
        StatCard(
          title: 'Active Lessons',
          value: '${stats.activeLessons}',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF2E7D32),
        ),
        StatCard(
          title: 'Pending Requests',
          value: '${stats.pendingRequests}',
          icon: Icons.hourglass_empty,
          color: const Color(0xFFEF6C00),
        ),
        StatCard(
          title: 'Completed Lessons',
          value: '${stats.completedLessons}',
          icon: Icons.task_alt_outlined,
          color: const Color(0xFF2E7D32),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        QuickActionCard(
          title: 'Create New Lesson',
          subtitle: 'Publish a new skill or lesson offering',
          icon: Icons.add_circle_outline,
          onTap: () {
            context.push('/skill-provider/create');
          },
        ),
        QuickActionCard(
          title: 'My Lessons',
          subtitle: 'Manage all your lesson listings',
          icon: Icons.list_alt_outlined,
          onTap: () {
            context.push('/skill-provider/my-lessons');
          },
        ),
      ],
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
