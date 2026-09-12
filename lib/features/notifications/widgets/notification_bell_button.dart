import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_auth.dart';
import '../services/notification_service.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    this.onDark = false,
  });

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : null;
    return ListenableBuilder(
      listenable: Listenable.merge([
        NotificationService.instance,
        AppAuth.instance,
      ]),
      builder: (context, _) {
        final unread = NotificationService.instance.unreadCountForCurrentUser();
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 9 ? '9+' : '$unread'),
            child: Icon(Icons.notifications_outlined, color: color),
          ),
        );
      },
    );
  }
}
