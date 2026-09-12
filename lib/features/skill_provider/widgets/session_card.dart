import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/provider_session.dart';
import '../utils/display_utils.dart';
import '../utils/session_time_utils.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session});

  final ProviderSession session;

  @override
  Widget build(BuildContext context) {
    final needsComplete = session.status == SessionStatus.upcoming &&
        hasSessionEnded(session);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: () => context.push('/skill-provider/session', extra: session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.lessonTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(session.learnerName,
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    Text(formatDateTime(session.scheduledAt),
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(session.duration,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    needsComplete
                        ? 'Complete'
                        : session.status.label,
                    style: TextStyle(
                      color: needsComplete
                          ? AppTheme.statusActiveText
                          : session.status == SessionStatus.upcoming
                              ? AppTheme.primaryColor
                              : AppTheme.statusActiveText,
                      fontSize: 12,
                      fontWeight: needsComplete ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
