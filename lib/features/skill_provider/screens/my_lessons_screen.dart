import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/lesson.dart';
import '../../../services/lesson_service.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_lessons_state.dart';
import '../widgets/lesson_list_card.dart';

class MyLessonsScreen extends StatefulWidget {
  const MyLessonsScreen({super.key});

  @override
  State<MyLessonsScreen> createState() => _MyLessonsScreenState();
}

class _MyLessonsScreenState extends State<MyLessonsScreen> {
  final _lessonService = DemoLessonService.instance;
  final _searchController = TextEditingController();

  List<Lesson> _lessons = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  static const _filters = ['All', 'Active', 'Draft', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _lessonService.addListener(_loadLessons);
    _loadLessons();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _lessonService.removeListener(_loadLessons);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    final lessons = await _lessonService.getLessonsByProvider(
      AppConstants.demoProviderId,
    );
    if (mounted) {
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    }
  }

  List<Lesson> get _filteredLessons {
    return _lessons.where((lesson) {
      final matchesSearch =
          _searchQuery.isEmpty || lesson.title.toLowerCase().contains(_searchQuery);

      final matchesFilter = switch (_selectedFilter) {
        'Active' => lesson.status == LessonStatus.active,
        'Draft' => lesson.status == LessonStatus.draft,
        'Inactive' => lesson.status == LessonStatus.inactive,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _confirmDelete(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Lesson'),
        content: Text(
          'Are you sure you want to delete "${lesson.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.statusInactiveText,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _lessonService.deleteLesson(lesson.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${lesson.title}" has been deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: TealPageHeader(
        title: 'My Lessons',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TealFilterBar(
            filters: _filters,
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
        ),
      ),
      floatingActionButton: _lessons.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.createLesson);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Lesson'),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _lessons.isEmpty
              ? const EmptyLessonsState()
              : RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: _loadLessons,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search lessons by title...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: _searchController.clear,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_filteredLessons.isEmpty)
                              _buildNoResultsState()
                            else
                              ..._filteredLessons.map(
                                (lesson) => LessonListCard(
                                  lesson: lesson,
                                  onEdit: () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.editLesson,
                                      arguments: lesson,
                                    );
                                  },
                                  onDelete: () => _confirmDelete(lesson),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No lessons match your search or filter.',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
