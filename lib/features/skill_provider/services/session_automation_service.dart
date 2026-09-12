import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../notifications/models/app_notification.dart';
import '../../notifications/services/notification_service.dart';
import '../models/provider_session.dart';
import '../utils/display_utils.dart';
import '../utils/session_time_utils.dart';
import 'session_service.dart';

class SessionAutomationService {
  SessionAutomationService._();

  static final SessionAutomationService instance = SessionAutomationService._();

  static const _tickInterval = Duration(seconds: 30);

  final _sessions = SessionService.instance;
  final _notifications = NotificationService.instance;

  Timer? _timer;
  bool _started = false;
  bool _running = false;

  void start() {
    if (_started) return;
    _started = true;
    _sessions.addListener(_onSessionsChanged);
    unawaited(processDueWork());
    _timer = Timer.periodic(_tickInterval, (_) {
      unawaited(processDueWork());
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_started) {
      _sessions.removeListener(_onSessionsChanged);
    }
    _started = false;
  }

  void _onSessionsChanged() {
    unawaited(processDueWork());
  }

  Future<void> processDueWork() async {
    if (_running) return;
    _running = true;
    try {
      final now = DateTime.now();
      final sessions = await _sessions.getSessionsForAutomation();
      for (final session in sessions) {
        await _processSession(session, now);
      }
    } catch (e) {
      debugPrint('Session automation tick skipped: $e');
    } finally {
      _running = false;
    }
  }

  Future<void> _processSession(ProviderSession session, DateTime now) async {
    if (session.status == SessionStatus.cancelled) return;

    if (session.status == SessionStatus.completed) {
      if (session.feedbackRequestedAt == null) {
        await _sendFeedbackRequest(session, now);
      }
      return;
    }

    if (session.status != SessionStatus.upcoming) return;

    if (isWithin24hReminderWindow(session.scheduledAt, now) &&
        session.reminder24hSentAt == null) {
      await _sendPair(
        session,
        type: NotificationType.reminder24h,
        title: 'Session in 24 hours',
        body:
            '${session.lessonTitle} is scheduled for ${formatDateTime(session.scheduledAt)}.',
      );
      await _sessions.setReminder24hSent(session.id, now);
    }

    if (isWithin1hReminderWindow(session.scheduledAt, now) &&
        session.reminder1hSentAt == null) {
      await _sendPair(
        session,
        type: NotificationType.reminder1h,
        title: 'Session in 1 hour',
        body:
            '${session.lessonTitle} starts at ${formatDateTime(session.scheduledAt)}.',
      );
      await _sessions.setReminder1hSent(session.id, now);
    }

    if (hasSessionEnded(session, now) && session.completePromptSentAt == null) {
      await _createNotification(
        session,
        type: NotificationType.completeSession,
        role: NotificationRecipientRole.teacher,
        recipientId: session.providerId,
        title: 'Complete Session',
        body:
            '${session.lessonTitle} on ${formatDateTime(session.scheduledAt)} has ended. Please mark it as completed.',
      );
      await _sessions.setCompletePromptSent(session.id, now);
    }
  }

  Future<void> _sendFeedbackRequest(ProviderSession session, DateTime now) async {
    await _createNotification(
      session,
      type: NotificationType.feedbackRequest,
      role: NotificationRecipientRole.learner,
      recipientId: session.learnerId,
      title: 'How was your session?',
      body:
          'Please rate and leave feedback for ${session.lessonTitle} (${formatDateTime(session.scheduledAt)}).',
    );
    await _sessions.setFeedbackRequested(session.id, now);
  }

  Future<void> _sendPair(
    ProviderSession session, {
    required NotificationType type,
    required String title,
    required String body,
  }) async {
    await _createNotification(
      session,
      type: type,
      role: NotificationRecipientRole.teacher,
      recipientId: session.providerId,
      title: title,
      body: body,
    );
    await _createNotification(
      session,
      type: type,
      role: NotificationRecipientRole.learner,
      recipientId: session.learnerId,
      title: title,
      body: body,
    );
  }

  Future<void> _createNotification(
    ProviderSession session, {
    required NotificationType type,
    required NotificationRecipientRole role,
    required String recipientId,
    required String title,
    required String body,
  }) async {
    final notification = AppNotification(
      id: AppNotification.buildId(
        sessionId: session.id,
        type: type,
        role: role,
        scheduledAt: session.scheduledAt,
      ),
      recipientId: recipientId,
      recipientRole: role,
      type: type,
      title: title,
      body: body,
      sessionId: session.id,
      createdAt: DateTime.now(),
    );
    await _notifications.createIfAbsent(notification);
  }
}
