import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/activity_log_service.dart';
import '../services/auth_service.dart';
import '../models/moderation_activity.dart';
import 'package:intl/intl.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final ActivityLogService _activityLogService = ActivityLogService();
  final ModeratorAuthService _authService = ModeratorAuthService();
  Map<String, int> _stats = {'today': 0, 'thisWeek': 0, 'thisMonth': 0};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      final stats = await _activityLogService.getModeratorStats(userId);
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.getCurrentUserId();
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Activity',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Aug 2025',
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('TODAY', '${_stats['today']} Actions', Colors.black87),
                ),
                Expanded(
                  child: _buildStatCard('THIS WEEK', '${_stats['thisWeek']} Actions', Colors.orange),
                ),
                Expanded(
                  child: _buildStatCard('THIS MONTH', '${_stats['thisMonth']} Acts', Colors.black87),
                ),
              ],
            ),
          ),

          // View Link
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Text(
                  'View warnings, bans & dismissed reports',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),

          // Activity List
          Expanded(
            child: StreamBuilder<List<ModerationActivity>>(
              stream: _activityLogService.getModeratorActivities(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading activities'));
                }

                final activities = snapshot.data ?? [];

                if (activities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No activities yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Group activities by date
                final today = DateTime.now();
                final todayStart = DateTime(today.year, today.month, today.day);
                final yesterdayStart = todayStart.subtract(const Duration(days: 1));

                final todayActivities = activities
                    .where((a) => a.timestamp.isAfter(todayStart))
                    .toList();
                final yesterdayActivities = activities
                    .where((a) =>
                        a.timestamp.isAfter(yesterdayStart) &&
                        a.timestamp.isBefore(todayStart))
                    .toList();
                final olderActivities = activities
                    .where((a) => a.timestamp.isBefore(yesterdayStart))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Today Section
                    if (todayActivities.isNotEmpty) ...[
                      _buildSectionHeader('TODAY'),
                      ...todayActivities.map((activity) => _buildActivityItem(activity)),
                      const SizedBox(height: 24),
                    ],

                    // Yesterday Section
                    if (yesterdayActivities.isNotEmpty) ...[
                      _buildSectionHeader('YESTERDAY'),
                      ...yesterdayActivities.map((activity) => _buildActivityItem(activity)),
                      const SizedBox(height: 24),
                    ],

                    // Older Section
                    if (olderActivities.isNotEmpty) ...[
                      _buildSectionHeader('EARLIER'),
                      ...olderActivities.map((activity) => _buildActivityItem(activity)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActivityItem(ModerationActivity activity) {
    final timeFormat = DateFormat('h:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with colored dot
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.getActionColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity.getActionIcon(),
              color: activity.getActionColor(),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(activity.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
