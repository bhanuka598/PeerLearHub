import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../skill_provider/models/provider_session.dart';
import '../../skill_provider/services/session_service.dart';
import '../../skill_provider/utils/display_utils.dart';
import '../../skill_provider/utils/session_time_utils.dart';

/// Schedules phone reminders that still fire after the app is closed.
///
/// The in-app notification list is still created by [SessionAutomationService]
/// while the app is open. This scheduler only adds the device alarm.
class SessionReminderScheduler {
  SessionReminderScheduler._();

  static final SessionReminderScheduler instance = SessionReminderScheduler._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _active = false;
  bool _permissionAsked = false;
  Future<void>? _initializing;

  /// Starts device reminders for the signed-in user.
  void activate() {
    _active = true;
  }

  /// Stops new device reminders. Pending alarms are cleared by [cancelAll].
  void deactivate() {
    _active = false;
  }

  bool get _supported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() {
    if (_ready || !_supported) return Future<void>.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      tz_data.initializeTimeZones();
      await _useDeviceTimeZone();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      _ready = true;
      SessionService.instance.onSessionSaved = apply;
    } catch (e) {
      _initializing = null;
      debugPrint('Device reminder setup skipped: $e');
    }
  }

  Future<void> syncForCurrentUser() async {
    if (!_supported || !_active) return;
    try {
      final uid = _currentUid;
      if (uid == null) return;
      await initialize();
      if (!_ready) return;
      final sessions = await SessionService.instance.getSessionsForUser(uid);
      await _syncSessions(sessions, onlyCurrentUser: false);
    } catch (e) {
      debugPrint('Device reminder sync skipped: $e');
    }
  }

  /// Updates device alarms for sessions already loaded by the in-app automation.
  Future<void> syncLoadedSessions(List<ProviderSession> sessions) async {
    if (!_supported || !_active) return;
    try {
      await initialize();
      if (!_ready) return;
      await _syncSessions(sessions, onlyCurrentUser: true);
    } catch (e) {
      debugPrint('Device reminder sync skipped: $e');
    }
  }

  Future<void> apply(ProviderSession session) async {
    if (!_supported || !_active) return;
    try {
      await initialize();
      if (!_ready) return;
      await _cancelSession(session.id);
      await _scheduleUpcoming(session);
    } catch (e) {
      debugPrint('Device reminder update skipped: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_supported || !_ready) return;
    try {
      await _plugin.cancelAllPendingNotifications();
    } catch (e) {
      debugPrint('Device reminder cancel skipped: $e');
    }
  }

  Future<void> _syncSessions(
    List<ProviderSession> sessions, {
    required bool onlyCurrentUser,
  }) async {
    if (!_active) return;
    final uid = _currentUid;
    if (onlyCurrentUser && uid == null) return;

    final pending = await _plugin.pendingNotificationRequests();
    final pendingPayload = <int, String?>{
      for (final request in pending) request.id: request.payload,
    };

    for (final session in sessions) {
      if (onlyCurrentUser &&
          session.providerId != uid &&
          session.learnerId != uid) {
        continue;
      }
      await _syncOne(session, pendingPayload);
    }
  }

  Future<void> _syncOne(
    ProviderSession session,
    Map<int, String?> pendingPayload,
  ) async {
    final slots = session.status == SessionStatus.upcoming
        ? deviceReminderTimes(session.scheduledAt, DateTime.now())
        : const <({String kind, DateTime when})>[];
    final wanted = <int, ({String kind, DateTime when, String payload})>{};
    for (final slot in slots) {
      final id = deviceReminderId(session.id, slot.kind);
      wanted[id] = (
        kind: slot.kind,
        when: slot.when,
        payload: _payload(session, slot.kind),
      );
    }

    var needsPermission = false;
    for (final kind in const ['24h', '1h']) {
      final id = deviceReminderId(session.id, kind);
      final next = wanted[id];
      if (next == null) {
        if (pendingPayload.containsKey(id)) {
          await _plugin.cancel(id: id);
          pendingPayload.remove(id);
        }
        continue;
      }
      if (pendingPayload[id] == next.payload) continue;
      needsPermission = true;
    }

    if (!needsPermission) return;
    await _ensurePermission();
    final mode = await _scheduleMode();
    for (final kind in const ['24h', '1h']) {
      final id = deviceReminderId(session.id, kind);
      final next = wanted[id];
      if (next == null || pendingPayload[id] == next.payload) continue;
      await _schedule(
        id: id,
        session: session,
        kind: next.kind,
        when: next.when,
        payload: next.payload,
        mode: mode,
      );
      pendingPayload[id] = next.payload;
    }
  }

  Future<void> _scheduleUpcoming(ProviderSession session) async {
    final slots = session.status == SessionStatus.upcoming
        ? deviceReminderTimes(session.scheduledAt, DateTime.now())
        : const <({String kind, DateTime when})>[];
    if (slots.isEmpty) return;
    await _ensurePermission();
    final mode = await _scheduleMode();
    for (final slot in slots) {
      await _schedule(
        id: deviceReminderId(session.id, slot.kind),
        session: session,
        kind: slot.kind,
        when: slot.when,
        payload: _payload(session, slot.kind),
        mode: mode,
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required ProviderSession session,
    required String kind,
    required DateTime when,
    required String payload,
    required AndroidScheduleMode mode,
  }) async {
    if (!_active) return;
    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'session_reminders',
        'Session reminders',
        channelDescription: 'Reminders before a scheduled lesson session',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final scheduledDate = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: kind == '24h' ? 'Session in 24 hours' : 'Session in 1 hour',
        body: kind == '24h'
            ? '${session.lessonTitle} is scheduled for ${formatDateTime(session.scheduledAt)}.'
            : '${session.lessonTitle} starts at ${formatDateTime(session.scheduledAt)}.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: mode,
        payload: payload,
      );
    } catch (e) {
      if (mode == AndroidScheduleMode.inexactAllowWhileIdle) rethrow;
      debugPrint('Exact reminder unavailable, using a flexible alarm: $e');
      await _plugin.zonedSchedule(
        id: id,
        title: kind == '24h' ? 'Session in 24 hours' : 'Session in 1 hour',
        body: kind == '24h'
            ? '${session.lessonTitle} is scheduled for ${formatDateTime(session.scheduledAt)}.'
            : '${session.lessonTitle} starts at ${formatDateTime(session.scheduledAt)}.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
    if (!_active) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> _cancelSession(String sessionId) async {
    await _plugin.cancel(id: deviceReminderId(sessionId, '24h'));
    await _plugin.cancel(id: deviceReminderId(sessionId, '1h'));
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (await android?.canScheduleExactNotifications() == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (e) {
      debugPrint('Exact alarm check skipped: $e');
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _ensurePermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      _permissionAsked = false;
      debugPrint('Reminder permission request skipped: $e');
    }
  }

  Future<void> _useDeviceTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Device timezone fallback: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Colombo'));
    }
  }

  String? get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String _payload(ProviderSession session, String kind) {
    return 'plh:${session.id}:$kind:${session.scheduledAt.millisecondsSinceEpoch}';
  }
}

int deviceReminderId(String sessionId, String kind) {
  final hash = Object.hash(sessionId, kind) & 0x7fffffff;
  return hash == 0 ? 1 : hash;
}
