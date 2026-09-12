import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_learn_hub/core/auth/app_auth.dart';
import 'package:peer_learn_hub/features/moderation/widgets/navigation_card.dart';
import 'package:peer_learn_hub/features/moderation/widgets/stat_card.dart';
import 'package:peer_learn_hub/features/moderation/widgets/moderator_bottom_nav.dart';
import '../../../core/constants/app_colors.dart';
import '../services/verification_service.dart';
import '../services/moderation_service.dart';
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

  Map<String, int> _verificationStats = {};
  Map<String, int> _reportStats = {};
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
      
      setState(() {
        _verificationStats = verificationStats;
        _reportStats = reportStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderator Dashboard'),
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.go('/profile');
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AppAuth.instance.logout();
              context.go('/');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F766E),
                            const Color(0xFF14B8A6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F766E).withOpacity(0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Manage verifications and reports',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white.withOpacity(0.12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                'assets/images/moderation_hero.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Verification Statistics
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Verification Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.4,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        StatCard(
                          title: 'Pending Requests',
                          value: '${_verificationStats['pending'] ?? 0}',
                          icon: Icons.hourglass_empty,
                          color: AppColors.pending,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const VerificationRequestsScreen(
                                  initialFilter: 'Pending',
                                ),
                              ),
                            ).then((_) => _loadStatistics());
                          },
                        ),
                        StatCard(
                          title: 'Approved',
                          value: '${_verificationStats['approved'] ?? 0}',
                          icon: Icons.check_circle_outline,
                          color: AppColors.approved,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Report Statistics
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Report Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.4,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        StatCard(
                          title: 'Open Reports',
                          value: '${_reportStats['open'] ?? 0}',
                          icon: Icons.report_problem_outlined,
                          color: AppColors.error,
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
                        StatCard(
                          title: 'High Severity',
                          value: '${_reportStats['highSeverity'] ?? 0}',
                          icon: Icons.priority_high,
                          color: AppColors.severityHigh,
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
                        StatCard(
                          title: 'Resolved',
                          value: '${_reportStats['resolved'] ?? 0}',
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    NavigationCard(
                      title: 'Verification Management',
                      subtitle: 'Review and approve verification requests',
                      icon: Icons.verified_user,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const VerificationRequestsScreen(),
                          ),
                        ).then((_) => _loadStatistics());
                      },
                    ),
                    
                    NavigationCard(
                      title: 'Report Management',
                      subtitle: 'Review flagged content and user reports',
                      icon: Icons.flag,
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
                      title: 'Community Safety',
                      subtitle: 'Monitor trust scores and safety trends',
                      icon: Icons.security_outlined,
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
                      title: 'Moderation Actions',
                      subtitle: 'Review warnings, bans, and moderator decisions',
                      icon: Icons.gavel_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ModerationActionsScreen(),
                          ),
                        ).then((_) => _loadStatistics());
                      },
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
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
}
