import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../notifications/widgets/notification_bell_button.dart';
import '../models/provider_session.dart';
import '../services/session_service.dart';
import '../utils/provider_id_helper.dart';
import '../utils/session_time_utils.dart';
import '../widgets/app_header.dart';
import '../widgets/session_card.dart';

class UpcomingSessionsScreen extends StatefulWidget {
  const UpcomingSessionsScreen({super.key});

  @override
  State<UpcomingSessionsScreen> createState() => _UpcomingSessionsScreenState();
}

class _UpcomingSessionsScreenState extends State<UpcomingSessionsScreen> {
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
    final list = await _service.getUpcomingSessions(getCurrentProviderId());
    if (mounted) setState(() { _sessions = list; _loading = false; });
  }

  int get _readyToComplete => _sessions
      .where((s) => s.status == SessionStatus.upcoming && hasSessionEnded(s))
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(
        title: 'Upcoming Sessions',
        actions: [NotificationBellButton(onDark: true)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              child: _sessions.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 80),
                      Center(child: Text('No upcoming sessions.')),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sessions.length + (_readyToComplete > 0 ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (_readyToComplete > 0 && i == 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: AppTheme.cardDecoration,
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '$_readyToComplete session${_readyToComplete == 1 ? '' : 's'} ended and ready to complete.',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        }
                        final session = _sessions[_readyToComplete > 0 ? i - 1 : i];
                        return SessionCard(session: session);
                      },
                    ),
            ),
    );
  }
}
