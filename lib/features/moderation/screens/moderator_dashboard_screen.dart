import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/core/auth/app_auth.dart';
import 'package:peer_learn_hub/features/moderation/widgets/navigation_card.dart';
import 'package:peer_learn_hub/features/moderation/widgets/moderator_bottom_nav.dart';
import '../../../core/constants/app_colors.dart';
import '../services/verification_service.dart';
import '../services/moderation_service.dart';
import '../services/community_safety_service.dart';
import 'verification_requests_screen.dart';
import 'reports_screen.dart';
import 'moderator_profile_screen.dart';
import 'activity_log_screen.dart';
import 'community_safety_screen.dart';
import 'moderation_actions_screen.dart';

class ModeratorDashboardScreen extends StatefulWidget {
  const ModeratorDashboardScreen({super.key});

  @override
  State<ModeratorDashboardScreen> createState() =>
      _ModeratorDashboardScreenState();
}

class _ModeratorDashboardScreenState extends State<ModeratorDashboardScreen> {
  final VerificationService _verificationService = VerificationService();
  final ModerationService _moderationService = ModerationService();
  final CommunitySafetyService _safetyService = CommunitySafetyService();

  Map<String, int> _verificationStats = {};
  Map<String, int> _reportStats = {};
  List<int> _reportVolume = [];
  Map<String, int> _topCategories = {};
  double _trustIndex = 88.0;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      final verificationStats = await _verificationService.getVerificationStatistics();
      final reportStats = await _moderationService.getReportStatistics();
      final trustIndex = await _safetyService.calculateTrustIndex();
      final reportVolume = await _safetyService.getReportVolume();
      final topCategories = await _safetyService.getTopCategories();

      if (!mounted) return;
      setState(() {
        _verificationStats = verificationStats;
        _reportStats = reportStats;
        _trustIndex = trustIndex;
        _reportVolume = reportVolume;
        _topCategories = topCategories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading statistics: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildCustomHeader(context),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadStatistics,
                color: AppColors.primaryTeal,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryTeal),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero Welcome Banner
                            _buildHeroBanner(),
                            const SizedBox(height: 20),

                            // Colorful Metric Cards Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Operations Overview',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'Tap card to inspect',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Colorful Metric Cards Grid
                            _buildMetricCardsGrid(),
                            const SizedBox(height: 24),

                            // Charts & Visual Analytics Section
                            _buildChartsSection(),
                            const SizedBox(height: 24),

                            // Operations & Quick Actions
                            const Text(
                              'Quick Management',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildQuickActionCards(),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ModeratorBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == _selectedIndex) return;
          setState(() => _selectedIndex = index);

          switch (index) {
            case 0:
              return;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const VerificationRequestsScreen(),
                ),
              );
              return;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportsScreen(),
                ),
              );
              return;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActivityLogScreen(),
                ),
              );
              return;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModeratorProfileScreen(),
                ),
              );
              return;
          }
        },
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Moderator Hub',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Active Operations',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppAuth.instance.currentRole?.name.toUpperCase() ?? 'MODERATOR',
              style: const TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87, size: 22),
            onPressed: _loadStatistics,
            tooltip: 'Refresh Stats',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black87, size: 22),
            onPressed: () {
              AppAuth.instance.logout();
              context.go('/login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    final pendingCount = _verificationStats['pending'] ?? 0;
    final openReportsCount = _reportStats['open'] ?? 0;
    final totalActionNeeded = pendingCount + openReportsCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F766E),
            Color(0xFF115E59),
            Color(0xFF042F2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Live Safety Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Trust Index: ${_trustIndex.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Community Governance Center',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalActionNeeded > 0
                ? 'You have $totalActionNeeded pending item${totalActionNeeded > 1 ? 's' : ''} requiring moderator attention.'
                : 'All queues are up to date! Community environment is healthy and safe.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(initialFilter: 'Open'),
                    ),
                  ).then((_) => _loadStatistics());
                },
                icon: const Icon(Icons.shield_outlined, size: 16),
                label: const Text('Review Reports'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F766E),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VerificationRequestsScreen(initialFilter: 'Pending'),
                    ),
                  ).then((_) => _loadStatistics());
                },
                icon: const Icon(Icons.verified_outlined, size: 16, color: Colors.white),
                label: const Text('Verify Users', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCardsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        // Card 1: Pending Verifications (Violet Gradient)
        _buildColorfulMetricCard(
          title: 'Pending Verifications',
          subtitle: 'Skill & Identity proofs',
          value: '${_verificationStats['pending'] ?? 0}',
          icon: Icons.hourglass_top_rounded,
          gradientColors: [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
          shadowColor: const Color(0xFF7C3AED),
          badgeText: 'Review Queue',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VerificationRequestsScreen(
                  initialFilter: 'Pending',
                ),
              ),
            ).then((_) => _loadStatistics());
          },
        ),

        // Card 2: Open Reports (Amber Orange Gradient)
        _buildColorfulMetricCard(
          title: 'Open Reports',
          subtitle: 'Unresolved issues',
          value: '${_reportStats['open'] ?? 0}',
          icon: Icons.flag_rounded,
          gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
          shadowColor: const Color(0xFFF59E0B),
          badgeText: 'Needs Action',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsScreen(
                  initialFilter: 'Open',
                ),
              ),
            ).then((_) => _loadStatistics());
          },
        ),

        // Card 3: High Severity (Crimson Red Gradient)
        _buildColorfulMetricCard(
          title: 'High Severity',
          subtitle: 'Urgent harassment / fraud',
          value: '${_reportStats['highSeverity'] ?? 0}',
          icon: Icons.crisis_alert_rounded,
          gradientColors: [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
          shadowColor: const Color(0xFFEF4444),
          badgeText: 'Critical',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsScreen(
                  initialFilter: 'High Severity',
                ),
              ),
            ).then((_) => _loadStatistics());
          },
        ),

        // Card 4: Resolved Reports (Emerald Green Gradient)
        _buildColorfulMetricCard(
          title: 'Resolved Reports',
          subtitle: 'Closed & handled',
          value: '${_reportStats['resolved'] ?? 0}',
          icon: Icons.check_circle_rounded,
          gradientColors: [const Color(0xFF10B981), const Color(0xFF047857)],
          shadowColor: const Color(0xFF10B981),
          badgeText: 'Completed',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsScreen(
                  initialFilter: 'Resolved',
                ),
              ),
            ).then((_) => _loadStatistics());
          },
        ),
      ],
    );
  }

  Widget _buildColorfulMetricCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required String badgeText,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analytics & Safety Trends',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),

        // Chart 1: 7-Day Moderation Ingestion Volume (Bar Graph)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Volume Trend',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Incoming reports over the last 7 days',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Past 7 Days',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildReportVolumeBarChart(),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Chart 2: Resolution Pipeline Distribution
        _buildResolutionRateCard(),
        if (_topCategories.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildTopCategoriesCard(),
        ],
      ],
    );
  }

  Widget _buildReportVolumeBarChart() {
    final volumes = _reportVolume.isNotEmpty ? _reportVolume : [2, 5, 3, 7, 4, 8, 3];
    final maxVal = volumes.reduce((a, b) => a > b ? a : b);
    final normalizedMax = maxVal == 0 ? 1 : maxVal;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: volumes.asMap().entries.map((entry) {
          final idx = entry.key;
          final val = entry.value;
          final heightPercent = (val / normalizedMax).clamp(0.12, 1.0);
          final isToday = idx == volumes.length - 1;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$val',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isToday ? AppColors.primaryTeal : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: 65 * heightPercent,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isToday
                            ? [const Color(0xFF0F766E), const Color(0xFF2DD4BF)]
                            : [Colors.grey.shade400, Colors.grey.shade300],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isToday ? 'Today' : '${volumes.length - idx}d ago',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? AppColors.primaryTeal : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResolutionRateCard() {
    final open = _reportStats['open'] ?? 0;
    final resolved = _reportStats['resolved'] ?? 0;
    final underReview = _reportStats['underReview'] ?? 0;
    final total = open + resolved + underReview;
    final resolutionRate = total == 0 ? 100 : ((resolved / total) * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
              const Text(
                'Resolution Pipeline',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$resolutionRate% Resolved',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stacked Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (resolved > 0)
                    Expanded(
                      flex: resolved,
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (underReview > 0)
                    Expanded(
                      flex: underReview,
                      child: Container(color: const Color(0xFFF59E0B)),
                    ),
                  if (open > 0)
                    Expanded(
                      flex: open,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                  if (total == 0)
                    Expanded(
                      child: Container(color: Colors.grey.shade300),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Resolved ($resolved)', const Color(0xFF10B981)),
              _buildLegendItem('Under Review ($underReview)', const Color(0xFFF59E0B)),
              _buildLegendItem('Open ($open)', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTopCategoriesCard() {
    final totalReports =
        _topCategories.values.fold<int>(0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
              const Text(
                'Top Incident Categories',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_topCategories.length} Categories',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._topCategories.entries.map((entry) {
            final percentage =
                totalReports > 0 ? (entry.value / totalReports) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${entry.value} (${(percentage * 100).toInt()}%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade100,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards() {
    final pendingVerifications = _verificationStats['pending'] ?? 0;
    final openReports = _reportStats['open'] ?? 0;

    return Column(
      children: [
        NavigationCard(
          title: 'Verification Management',
          subtitle: pendingVerifications > 0
              ? '$pendingVerifications pending request${pendingVerifications > 1 ? 's' : ''} awaiting review'
              : 'All teacher & learner verifications up to date',
          icon: Icons.verified_user_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VerificationRequestsScreen(),
              ),
            ).then((_) => _loadStatistics());
          },
        ),
        NavigationCard(
          title: 'Report Management',
          subtitle: openReports > 0
              ? '$openReports open incident${openReports > 1 ? 's' : ''} to resolve'
              : 'No open reports. Community is clean',
          icon: Icons.flag_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsScreen(),
              ),
            ).then((_) => _loadStatistics());
          },
        ),
        NavigationCard(
          title: 'Community Safety & Trust',
          subtitle: 'Trust index score ${_trustIndex.toInt()}% · Automated threshold alerts',
          icon: Icons.security_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CommunitySafetyScreen(),
              ),
            ).then((_) => _loadStatistics());
          },
        ),
        NavigationCard(
          title: 'Moderator Enforcement Actions',
          subtitle: 'Audit warnings, temporary suspensions, and dismissals',
          icon: Icons.gavel_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ModerationActionsScreen(),
              ),
            ).then((_) => _loadStatistics());
          },
        ),
      ],
    );
  }
}
