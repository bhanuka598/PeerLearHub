import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../services/activity_log_service.dart';
import '../services/auth_service.dart';
import '../models/moderation_activity.dart';

class ModerationActionsScreen extends StatefulWidget {
  const ModerationActionsScreen({super.key});

  @override
  State<ModerationActionsScreen> createState() => _ModerationActionsScreenState();
}

class _ModerationActionsScreenState extends State<ModerationActionsScreen> {
  final ActivityLogService _activityLogService = ActivityLogService();
  final ModeratorAuthService _authService = ModeratorAuthService();
  
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Warnings', 'Bans', 'Dismissed'];

  @override
  Widget build(BuildContext context) {
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
          'Moderation Actions',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: AppColors.primaryTeal,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Stats Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem('THIS WEEK', '23 Actions', Colors.black87),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: _buildStatItem('AVG RESPONSE', '2.4 Hours', Colors.orange),
                ),
              ],
            ),
          ),

          // Actions List
          Expanded(
            child: StreamBuilder<List<ModerationActivity>>(
              stream: _activityLogService.getModeratorActivities(_authService.getCurrentUserId()!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading actions'));
                }

                var activities = snapshot.data ?? [];

                // Filter activities based on selected filter
                if (_selectedFilter != 'All') {
                  activities = activities.where((activity) {
                    if (_selectedFilter == 'Warnings' && activity.actionType == 'warning_issued') {
                      return true;
                    }
                    if (_selectedFilter == 'Bans' && 
                        (activity.actionType == 'user_banned' || 
                         activity.actionType.contains('ban'))) {
                      return true;
                    }
                    if (_selectedFilter == 'Dismissed' && 
                        activity.actionType == 'report_dismissed') {
                      return true;
                    }
                    return false;
                  }).toList();
                }

                if (activities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No actions yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActionItem(
                      activity.description,
                      'Target: ${activity.targetUserId}',
                      'By ${activity.moderatorName} • ${_getTimeAgo(activity.timestamp)}',
                      activity.getActionColor(),
                      _getActionBadge(activity.actionType),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
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

  Widget _buildActionItem(
    String title,
    String reason,
    String metadata,
    Color indicatorColor,
    String badge,
  ) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: indicatorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              badge.contains('BAN')
                  ? Icons.block
                  : badge == 'WARNING'
                      ? Icons.warning_amber
                      : Icons.check_circle_outline,
              color: indicatorColor,
              size: 24,
            ),
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
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: indicatorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: indicatorColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metadata,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: 20,
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getActionBadge(String actionType) {
    switch (actionType) {
      case 'warning_issued':
        return 'WARNING';
      case 'user_banned':
        return 'PERM BAN';
      case 'report_dismissed':
        return 'DISMISSED';
      case 'report_resolved':
        return 'RESOLVED';
      case 'verification_approved':
        return 'APPROVED';
      case 'verification_rejected':
        return 'REJECTED';
      default:
        return 'ACTION';
    }
  }
}
