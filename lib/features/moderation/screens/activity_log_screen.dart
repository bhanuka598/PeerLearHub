import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../models/moderation_activity.dart';
import '../screens/moderation_actions_screen.dart';
import '../screens/moderator_dashboard_screen.dart';
import '../services/activity_log_service.dart';
import '../services/auth_service.dart';
import '../widgets/moderator_bottom_nav.dart';
import '../widgets/moderator_app_bar.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final ActivityLogService _activityLogService = ActivityLogService();
  final ModeratorAuthService _authService = ModeratorAuthService();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  DateTime? _selectedDate;

  final List<String> _filterCategories = [
    'All',
    'Verifications',
    'Reports',
    'Warnings',
    'Bans',
  ];

  Map<String, int> _stats = {
    'today': 0,
    'thisWeek': 0,
    'thisMonth': 0,
    'total': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      final stats = await _activityLogService.getModeratorStats(userId);
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedFilter = 'All';
      _selectedDate = null;
    });
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && now.day == timestamp.day) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1 || (now.day - timestamp.day == 1 && difference.inHours < 48)) {
      return 'Yesterday, ${DateFormat('h:mm a').format(timestamp)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }

  String _getActionDisplayName(String actionType) {
    switch (actionType) {
      case 'verification_approved':
        return 'Verification Approved';
      case 'verification_rejected':
        return 'Verification Rejected';
      case 'report_resolved':
        return 'Report Resolved';
      case 'report_dismissed':
        return 'Report Dismissed';
      case 'warning_issued':
        return 'Warning Issued';
      case 'user_banned':
        return 'Account Suspended';
      default:
        return actionType
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
            .join(' ');
    }
  }

  void _showActivityDetails(BuildContext context, ModerationActivity activity) {
    final color = activity.getActionColor();
    final icon = activity.getActionIcon();
    final actionTitle = _getActionDisplayName(activity.actionType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(sheetContext).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actionTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 13, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMMM d, yyyy • h:mm:ss a').format(activity.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      activity.actionType.split('_').last.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTION DESCRIPTION / REASON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activity.description.isNotEmpty
                          ? activity.description
                          : 'No detailed description recorded.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Target & Context Details
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildModalDetailRow(
                      icon: Icons.person_outline,
                      label: 'Target User ID',
                      value: activity.targetUserId.isNotEmpty ? activity.targetUserId : 'N/A',
                      isCopyable: activity.targetUserId.isNotEmpty,
                    ),
                    const Divider(height: 18),
                    _buildModalDetailRow(
                      icon: Icons.fingerprint,
                      label: 'Target Item ID',
                      value: activity.targetId.isNotEmpty ? activity.targetId : 'N/A',
                      isCopyable: activity.targetId.isNotEmpty,
                    ),
                    const Divider(height: 18),
                    _buildModalDetailRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Moderator Name',
                      value: activity.moderatorName.isNotEmpty
                          ? activity.moderatorName
                          : 'System / Moderator',
                    ),
                  ],
                ),
              ),

              // Metadata if available
              if (activity.metadata != null && activity.metadata!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'METADATA / ADDITIONAL ATTRIBUTES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: activity.metadata!.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isCopyable = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isCopyable)
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: AppColors.primaryTeal),
            tooltip: 'Copy',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied $label to clipboard'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
      ],
    );
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
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: ModeratorAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            tooltip: 'Refresh Stats',
            onPressed: () {
              _loadStats();
              setState(() {});
            },
          ),
        ],
      ),
      bottomNavigationBar: const ModeratorBottomNav(currentIndex: 3),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadStats();
          },
          color: AppColors.primaryTeal,
          child: Column(
            children: [
              // Header Row with Back button & Subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ModeratorDashboardScreen(),
                              ),
                            );
                          }
                        },
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Activity Audit Log',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Chronological log of moderation decisions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Date Filter Chip / Indicator
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppColors.primaryTeal,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedDate != null
                                ? AppColors.primaryTeal.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedDate != null
                                  ? AppColors.primaryTeal
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: _selectedDate != null
                                    ? AppColors.primaryTeal
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedDate == null
                                    ? 'All Time'
                                    : DateFormat('MMM d').format(_selectedDate!),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedDate != null
                                      ? AppColors.primaryTeal
                                      : Colors.grey[700],
                                ),
                              ),
                              if (_selectedDate != null) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(() => _selectedDate = null),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // KPI Metric Cards Row (UX High Visual Appeal)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'TODAY',
                        count: '${_stats['today'] ?? 0}',
                        subtitle: 'Actions',
                        gradientColors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
                        icon: Icons.today_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'THIS WEEK',
                        count: '${_stats['thisWeek'] ?? 0}',
                        subtitle: 'Past 7 days',
                        gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        icon: Icons.date_range_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'LIFETIME',
                        count: '${_stats['total'] ?? 0}',
                        subtitle: 'Recorded',
                        gradientColors: const [Color(0xFF0284C7), Color(0xFF0369A1)],
                        icon: Icons.all_inclusive_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // Punitive Actions Shortcut Banner (UX Discovery)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModerationActionsScreen(),
                        ),
                      ).then((_) => _loadStats());
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.gavel_rounded,
                              color: Color(0xFFD97706),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Punitive & Disciplinary Archive',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'View warnings, account bans & dismissed reports',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Search Bar (UX Findability)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by action, user ID, reason...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),

              // Filter Chips Row
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _filterCategories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filterCategories[index];
                    final isSelected = filter == _selectedFilter;

                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.primaryTeal,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryTeal : Colors.grey.shade300,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // Activity Stream List
              Expanded(
                child: StreamBuilder<List<ModerationActivity>>(
                  stream: _activityLogService.getModeratorActivities(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryTeal),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load audit activities',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }

                    final activities = snapshot.data ?? [];

                    // Apply Date Filter
                    var displayActivities = activities;
                    if (_selectedDate != null) {
                      displayActivities = displayActivities.where((a) {
                        return a.timestamp.year == _selectedDate!.year &&
                            a.timestamp.month == _selectedDate!.month &&
                            a.timestamp.day == _selectedDate!.day;
                      }).toList();
                    }

                    // Apply Category Filter
                    if (_selectedFilter == 'Verifications') {
                      displayActivities = displayActivities
                          .where((a) => a.actionType.startsWith('verification_'))
                          .toList();
                    } else if (_selectedFilter == 'Reports') {
                      displayActivities = displayActivities
                          .where((a) => a.actionType.startsWith('report_'))
                          .toList();
                    } else if (_selectedFilter == 'Warnings') {
                      displayActivities = displayActivities
                          .where((a) => a.actionType.contains('warning'))
                          .toList();
                    } else if (_selectedFilter == 'Bans') {
                      displayActivities = displayActivities
                          .where((a) => a.actionType.contains('ban'))
                          .toList();
                    }

                    // Apply Search Query
                    final query = _searchQuery.trim().toLowerCase();
                    if (query.isNotEmpty) {
                      displayActivities = displayActivities.where((a) {
                        return a.description.toLowerCase().contains(query) ||
                            a.targetUserId.toLowerCase().contains(query) ||
                            a.targetId.toLowerCase().contains(query) ||
                            a.moderatorName.toLowerCase().contains(query) ||
                            a.actionType.toLowerCase().contains(query);
                      }).toList();
                    }

                    // Empty state when filters yield no items
                    if (displayActivities.isEmpty) {
                      final hasActiveFilters = _searchQuery.isNotEmpty ||
                          _selectedFilter != 'All' ||
                          _selectedDate != null;

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  hasActiveFilters
                                      ? Icons.search_off_rounded
                                      : Icons.history_toggle_off_rounded,
                                  size: 48,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                hasActiveFilters
                                    ? 'No Matching Activities'
                                    : 'No Moderation Activities Yet',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hasActiveFilters
                                    ? 'Try modifying your search or clearing selected filters.'
                                    : 'All moderation actions, verifications and warnings will be recorded here for compliance.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                              if (hasActiveFilters) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _resetFilters,
                                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                                  label: const Text('Reset All Filters'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryTeal,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    // Group activities by date
                    final today = DateTime.now();
                    final todayStart = DateTime(today.year, today.month, today.day);
                    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

                    final todayActivities = displayActivities
                        .where((a) =>
                            a.timestamp.isAfter(todayStart) ||
                            a.timestamp.isAtSameMomentAs(todayStart))
                        .toList();

                    final yesterdayActivities = displayActivities
                        .where((a) =>
                            (a.timestamp.isAfter(yesterdayStart) ||
                                a.timestamp.isAtSameMomentAs(yesterdayStart)) &&
                            a.timestamp.isBefore(todayStart))
                        .toList();

                    final olderActivities = displayActivities
                        .where((a) => a.timestamp.isBefore(yesterdayStart))
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      children: [
                        if (_selectedDate != null) ...[
                          _buildSectionHeader(
                            DateFormat('MMMM d, yyyy').format(_selectedDate!).toUpperCase(),
                            displayActivities.length,
                          ),
                          ...displayActivities.map((activity) => _buildActivityItem(activity)),
                        ] else ...[
                          // Today Section
                          if (todayActivities.isNotEmpty) ...[
                            _buildSectionHeader('TODAY', todayActivities.length),
                            ...todayActivities.map((activity) => _buildActivityItem(activity)),
                            const SizedBox(height: 16),
                          ],

                          // Yesterday Section
                          if (yesterdayActivities.isNotEmpty) ...[
                            _buildSectionHeader('YESTERDAY', yesterdayActivities.length),
                            ...yesterdayActivities.map((activity) => _buildActivityItem(activity)),
                            const SizedBox(height: 16),
                          ],

                          // Older Section
                          if (olderActivities.isNotEmpty) ...[
                            _buildSectionHeader('EARLIER', olderActivities.length),
                            ...olderActivities.map((activity) => _buildActivityItem(activity)),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey[700],
              letterSpacing: 0.6,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count action${count > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ModerationActivity activity) {
    final color = activity.getActionColor();
    final icon = activity.getActionIcon();
    final actionTitle = _getActionDisplayName(activity.actionType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showActivityDetails(context, activity),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Icon with soft circular background
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              actionTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatRelativeTime(activity.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.description.isNotEmpty
                            ? activity.description
                            : 'Moderation decision recorded.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // User / Target context chip
                      Row(
                        children: [
                          if (activity.targetUserId.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_outline, size: 12, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'User: ${activity.targetUserId}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.primaryTeal,
                          ),
                        ],
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

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtitle,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 15),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
