import 'package:flutter/material.dart';
import '../models/skill_exchange_models.dart';
import '../providers/skill_exchange_provider.dart';
import '../widgets/ai_suggestion_card.dart';
import '../widgets/course_card.dart';
import '../widgets/create_exchange_dialog.dart';
import '../widgets/exchange_request_card.dart';

class SkillExchangeDashboardScreen extends StatefulWidget {
  const SkillExchangeDashboardScreen({super.key});

  @override
  State<SkillExchangeDashboardScreen> createState() => _SkillExchangeDashboardScreenState();
}

class _SkillExchangeDashboardScreenState extends State<SkillExchangeDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final SkillExchangeProvider _provider;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _provider = SkillExchangeProvider();
    _provider.addListener(_onProviderUpdate);
    _tabController = TabController(length: 3, vsync: this);
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    _provider.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateDialog([ExchangeCourse? targetCourse, ExchangeCourse? offeredCourse]) {
    showDialog(
      context: context,
      builder: (ctx) => CreateExchangeDialog(
        provider: _provider,
        preselectedTargetCourse: targetCourse,
        preselectedOfferedCourse: offeredCourse,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _provider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Exchange Hub'),
        elevation: 0,
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        actions: [
          // Role toggle for quick demo of Student vs Lecturer business rules
          PopupMenuButton<UserRole>(
            tooltip: 'Switch Simulated Role',
            icon: const Icon(Icons.switch_account),
            onSelected: (role) => _provider.switchRole(role),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: UserRole.lecturer,
                child: Row(
                  children: [
                    Icon(
                      Icons.school,
                      color: user.role == UserRole.lecturer ? Colors.teal : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Dr. Kavindu (Lecturer)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: UserRole.student,
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: user.role == UserRole.student ? Colors.teal : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Nirmal (Student)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _provider.loadInitialData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(icon: Icon(Icons.auto_awesome, size: 20), text: 'AI Matchmaker'),
            const Tab(icon: Icon(Icons.explore, size: 20), text: 'Marketplace'),
            Tab(
              icon: Badge(
                label: Text('${_provider.incomingRequests.length}'),
                isLabelVisible: _provider.incomingRequests.isNotEmpty,
                child: const Icon(Icons.swap_horizontal_circle, size: 20),
              ),
              text: 'My Swaps',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Propose Swap'),
      ),
      body: _provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAIMatchmakerTab(),
                _buildMarketplaceTab(),
                _buildMySwapsTab(),
              ],
            ),
    );
  }

  Widget _buildAIMatchmakerTab() {
    final myCourses = _provider.myCourses;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.white, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'AI Skill Synergy Engine',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Calculates curriculum compatibility, difficulty balance, and tag synergy to recommend peer courses with the highest learning return.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 14),
                if (myCourses.isNotEmpty) ...[
                  const Text(
                    'Match based on your course:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ExchangeCourse>(
                        value: _provider.selectedOfferedCourseForAI,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F766E)),
                        items: myCourses.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (course) {
                          if (course != null) {
                            _provider.selectCourseForAI(course);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 4),
            child: Text(
              'Top AI Match Recommendations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          if (_provider.aiSuggestions.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: const Text('No high-confidence AI swaps found for this course.'),
            )
          else
            ..._provider.aiSuggestions.map((suggestion) {
              return AISuggestionCard(
                suggestion: suggestion,
                onInitiateSwap: (offered, target) {
                  _openCreateDialog(target, offered);
                },
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMarketplaceTab() {
    final otherCourses = _provider.availableCourses
        .where((c) => c.ownerId != _provider.currentUser.id)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: otherCourses.length,
      itemBuilder: (context, index) {
        final course = otherCourses[index];
        return CourseCard(
          course: course,
          trailing: FilledButton.tonal(
            onPressed: () => _openCreateDialog(course),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: const Text('Request Swap', style: TextStyle(fontSize: 11)),
          ),
        );
      },
    );
  }

  Widget _buildMySwapsTab() {
    final incoming = _provider.incomingRequests;
    final outgoing = _provider.outgoingRequests;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade100,
            child: const TabBar(
              labelColor: Color(0xFF0F766E),
              indicatorColor: Color(0xFF0F766E),
              tabs: [
                Tab(text: 'Incoming Requests'),
                Tab(text: 'Sent Requests'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Incoming Requests
                incoming.isEmpty
                    ? const Center(child: Text('No incoming swap requests.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: incoming.length,
                        itemBuilder: (ctx, idx) {
                          final req = incoming[idx];
                          return ExchangeRequestCard(
                            request: req,
                            isIncoming: true,
                            onApprove: () => _provider.approveRequest(req.id),
                            onReject: () => _provider.rejectRequest(req.id),
                          );
                        },
                      ),

                // Outgoing Requests
                outgoing.isEmpty
                    ? const Center(child: Text('No outgoing swap requests sent yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: outgoing.length,
                        itemBuilder: (ctx, idx) {
                          final req = outgoing[idx];
                          return ExchangeRequestCard(
                            request: req,
                            isIncoming: false,
                            onCancel: () => _provider.cancelRequest(req.id),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
