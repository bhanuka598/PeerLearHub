import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../skill_provider/models/provider_session.dart';
import '../../skill_provider/services/review_service.dart';
import '../../skill_provider/services/session_service.dart';
import '../../skill_provider/utils/display_utils.dart';
import '../../skill_provider/utils/provider_id_helper.dart';
import '../../skill_provider/widgets/app_header.dart';

class LearnerSessionsScreen extends StatefulWidget {
  const LearnerSessionsScreen({super.key});

  @override
  State<LearnerSessionsScreen> createState() => _LearnerSessionsScreenState();
}

class _LearnerSessionsScreenState extends State<LearnerSessionsScreen> {
  final _service = SessionService.instance;
  List<ProviderSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _service.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _service.getSessionsByLearner(getCurrentProviderId());
    if (mounted) {
      setState(() {
        _sessions = list;
        _loading = false;
      });
    }
  }

  Future<void> _open(ProviderSession session) async {
    if (session.status == SessionStatus.completed) {
      context.push('/learning/session-feedback', extra: session);
      return;
    }
    context.push('/skill-provider/session', extra: session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(title: 'My Sessions'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _sessions.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No sessions yet.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final reviewed = ReviewService.instance
                                .existingReviewForSession(session.id) !=
                            null;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: AppTheme.cardDecoration,
                          child: ListTile(
                            leading: const Icon(
                              Icons.event,
                              color: AppTheme.primaryColor,
                            ),
                            title: Text(
                              session.lessonTitle,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${formatDateTime(session.scheduledAt)}\n${session.status.label}',
                            ),
                            isThreeLine: true,
                            trailing: session.status == SessionStatus.completed
                                ? Text(
                                    reviewed ? 'Reviewed' : 'Rate',
                                    style: TextStyle(
                                      color: reviewed
                                          ? AppTheme.textSecondary
                                          : AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : Text(session.duration),
                            onTap: () => _open(session),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
