import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../skill_provider/services/session_service.dart';
import '../../skill_provider/widgets/app_header.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService.instance;
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.addListener(_load);
    AppAuth.instance.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _service.removeListener(_load);
    AppAuth.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _service.getForCurrentUser();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _open(AppNotification notification) async {
    await _service.markRead(notification.id);
    final session =
        await SessionService.instance.getSessionById(notification.sessionId);
    if (!mounted) return;

    if (notification.type == NotificationType.feedbackRequest) {
      if (session == null) return;
      context.push('/learning/session-feedback', extra: session);
      return;
    }

    if (session == null) return;
    if (AppAuth.instance.currentRole == AppUserRole.teacher) {
      context.push('/skill-provider/session', extra: session);
    } else {
      context.push('/learning/sessions');
    }
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.reminder24h:
        return Icons.event_available_outlined;
      case NotificationType.reminder1h:
        return Icons.schedule;
      case NotificationType.completeSession:
        return Icons.task_alt_outlined;
      case NotificationType.feedbackRequest:
        return Icons.star_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(title: 'Notifications'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No notifications yet.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: AppTheme.cardDecoration,
                          child: ListTile(
                            leading: Icon(
                              _iconFor(item.type),
                              color: AppTheme.primaryColor,
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.read
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(item.body),
                            trailing: item.read
                                ? null
                                : const Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: AppTheme.primaryColor,
                                  ),
                            onTap: () => _open(item),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
