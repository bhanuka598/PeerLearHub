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
  bool _loadInProgress = false;
  bool _reloadQueued = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _load(forceRefresh: false);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    _load(forceRefresh: true);
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (_loadInProgress) {
      _reloadQueued = true;
      return;
    }
    _loadInProgress = true;
    final showSpinner = _sessions.isEmpty;
    if (showSpinner && mounted) {
      setState(() => _loading = true);
    }
    try {
      final providerId = await resolveProviderId();
      final list = await _service.getUpcomingSessions(
        providerId,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _sessions = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    } finally {
      _loadInProgress = false;
      if (_reloadQueued) {
        _reloadQueued = false;
        await _load(forceRefresh: true);
      }
    }
  }

  int get _readyToComplete => _sessions
      .where((s) => s.status == SessionStatus.upcoming && hasSessionEnded(s))
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.teacherPageBackground,
      appBar: const TealPageHeader(
        title: 'Upcoming Sessions',
        actions: [NotificationBellButton(onDark: true)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: () => _load(forceRefresh: true),
              child: _sessions.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 72),
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: AppTheme.teacherTintedCard(
                              AppTheme.teacherAccentIndigo,
                            ),
                            child: const Text(
                              'No upcoming sessions.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sessions.length + (_readyToComplete > 0 ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (_readyToComplete > 0 && i == 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: AppTheme.teacherTintedCard(AppTheme.teacherAccentAmber),
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
