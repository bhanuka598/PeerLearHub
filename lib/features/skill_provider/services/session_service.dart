import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../data/demo/demo_sessions.dart';
import '../models/booking_request.dart';
import '../models/provider_session.dart';
import '../utils/session_time_utils.dart';

class SessionService extends ChangeNotifier {
  SessionService._() {
    _sessions.addAll(createDemoSessions());
  }

  static final SessionService instance = SessionService._();
  static bool useMockData = false;

  /// Called after a session is saved so device reminders can follow the
  /// same create, reschedule, cancel, and complete changes.
  void Function(ProviderSession session)? onSessionSaved;

  static const _collection = 'sessions';
  final List<ProviderSession> _sessions = [];

  String? _cachedProviderId;
  List<ProviderSession>? _cachedForProvider;
  DateTime? _cacheFetchedAt;
  static const _cacheMaxAge = Duration(seconds: 45);

  void _invalidateProviderCache([String? providerId]) {
    if (providerId == null ||
        providerId == _cachedProviderId ||
        _cachedProviderId == null) {
      _cachedProviderId = null;
      _cachedForProvider = null;
      _cacheFetchedAt = null;
    }
  }

  Future<List<ProviderSession>> getSessionsForAutomation() async {
    if (useMockData) {
      return List<ProviderSession>.from(_sessions);
    }
    final firestore = FirebaseFirestore.instance.collection(_collection);
    final results = <ProviderSession>[];
    try {
      final upcoming = await firestore
          .where('status', isEqualTo: SessionStatus.upcoming.name)
          .get();
      results.addAll(upcoming.docs.map(ProviderSession.fromFirestore));
    } catch (e) {
      debugPrint('Automation upcoming sessions load skipped: $e');
    }
    try {
      final completed = await firestore
          .where('status', isEqualTo: SessionStatus.completed.name)
          .get();
      results.addAll(
        completed.docs
            .map(ProviderSession.fromFirestore)
            .where((s) => s.feedbackRequestedAt == null),
      );
    } catch (e) {
      debugPrint('Automation completed sessions load skipped: $e');
    }
    return results;
  }

  Future<List<ProviderSession>> getSessionsForUser(String uid) async {
    if (uid.isEmpty) return const [];
    if (useMockData) {
      return _sessions
          .where((s) => s.providerId == uid || s.learnerId == uid)
          .toList();
    }

    final col = FirebaseFirestore.instance.collection(_collection);
    final results = <String, ProviderSession>{};
    try {
      final asProvider = await col.where('providerId', isEqualTo: uid).get();
      for (final doc in asProvider.docs) {
        final session = ProviderSession.fromFirestore(doc);
        results[session.id] = session;
      }
    } catch (e) {
      debugPrint('Provider sessions for reminders skipped: $e');
    }
    try {
      final asLearner = await col.where('learnerId', isEqualTo: uid).get();
      for (final doc in asLearner.docs) {
        final session = ProviderSession.fromFirestore(doc);
        results[session.id] = session;
      }
    } catch (e) {
      debugPrint('Learner sessions for reminders skipped: $e');
    }
    return results.values.toList();
  }

  Future<List<ProviderSession>> getSessionsByProvider(
    String providerId, {
    bool forceRefresh = false,
  }) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final ids = <String>{providerId, AppConstants.demoProviderId};
      return _sessions.where((s) => ids.contains(s.providerId)).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }

    final cacheFresh = !forceRefresh &&
        _cachedProviderId == providerId &&
        _cachedForProvider != null &&
        _cacheFetchedAt != null &&
        DateTime.now().difference(_cacheFetchedAt!) < _cacheMaxAge;
    if (cacheFresh) {
      return List<ProviderSession>.from(_cachedForProvider!);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('providerId', isEqualTo: providerId)
          .get();
      final list = snapshot.docs.map(ProviderSession.fromFirestore).toList();
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      _cachedProviderId = providerId;
      _cachedForProvider = list;
      _cacheFetchedAt = DateTime.now();
      return List<ProviderSession>.from(list);
    } catch (e) {
      debugPrint('Sessions load failed: $e');
      if (_cachedProviderId == providerId && _cachedForProvider != null) {
        return List<ProviderSession>.from(_cachedForProvider!);
      }
      rethrow;
    }
  }

  Future<List<ProviderSession>> getSessionsByLearner(String learnerId) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return _sessions.where((s) => s.learnerId == learnerId).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }
    final snapshot = await FirebaseFirestore.instance
        .collection(_collection)
        .where('learnerId', isEqualTo: learnerId)
        .get();
    final list = snapshot.docs.map(ProviderSession.fromFirestore).toList();
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  Future<List<ProviderSession>> getUpcomingSessions(
    String providerId, {
    bool forceRefresh = false,
  }) async {
    if (useMockData) {
      final all = await getSessionsByProvider(providerId, forceRefresh: forceRefresh);
      return all.where((s) => s.status == SessionStatus.upcoming).toList();
    }

    final cacheFresh = !forceRefresh &&
        _cachedProviderId == providerId &&
        _cachedForProvider != null &&
        _cacheFetchedAt != null &&
        DateTime.now().difference(_cacheFetchedAt!) < _cacheMaxAge;
    if (cacheFresh) {
      return _cachedForProvider!
          .where((s) => s.status == SessionStatus.upcoming)
          .toList();
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('providerId', isEqualTo: providerId)
          .where('status', isEqualTo: SessionStatus.upcoming.name)
          .get();
      final list = snapshot.docs.map(ProviderSession.fromFirestore).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return list;
    } catch (e) {
      debugPrint('Upcoming sessions query failed, using cache: $e');
      final all = await getSessionsByProvider(
        providerId,
        forceRefresh: forceRefresh,
      );
      return all.where((s) => s.status == SessionStatus.upcoming).toList();
    }
  }

  Future<ProviderSession?> getSessionById(String id) async {
    if (useMockData) {
      try {
        return _sessions.firstWhere((s) => s.id == id);
      } catch (_) {
        return null;
      }
    }
    final doc =
        await FirebaseFirestore.instance.collection(_collection).doc(id).get();
    return doc.exists ? ProviderSession.fromFirestore(doc) : null;
  }

  Future<ProviderSession?> createFromBooking(BookingRequest booking) async {
    final existing = await _findByBookingId(booking.id);
    if (existing != null) return existing;

    final scheduledAt = combineDateAndTime(
      booking.requestedDate,
      booking.requestedTime,
    );
    final session = ProviderSession(
      id: 'session_from_${booking.id}',
      providerId: booking.providerId,
      learnerId: booking.learnerId,
      learnerName: booking.learnerName,
      lessonId: booking.lessonId,
      lessonTitle: booking.lessonTitle,
      scheduledAt: scheduledAt,
      duration: '1 hour',
      status: SessionStatus.upcoming,
      bookingId: booking.id,
    );
    await _save(session);
    return session;
  }

  Future<void> markCompleted(String id) async {
    final session = await getSessionById(id);
    if (session == null || session.status == SessionStatus.cancelled) return;
    await _save(session.copyWith(status: SessionStatus.completed));
  }

  Future<void> cancelSession(String id) async {
    final session = await getSessionById(id);
    if (session == null || session.status == SessionStatus.completed) return;
    await _save(session.copyWith(status: SessionStatus.cancelled));
  }

  Future<void> rescheduleSession(String id, DateTime newScheduledAt) async {
    final session = await getSessionById(id);
    if (session == null || session.status != SessionStatus.upcoming) return;
    await _save(
      session.copyWith(
        scheduledAt: newScheduledAt,
        status: SessionStatus.upcoming,
        clearAllAutomationFlags: true,
      ),
    );
  }

  Future<void> setReminder24hSent(String id, DateTime at) async {
    final session = await getSessionById(id);
    if (session == null) return;
    await _save(session.copyWith(reminder24hSentAt: at));
  }

  Future<void> setReminder1hSent(String id, DateTime at) async {
    final session = await getSessionById(id);
    if (session == null) return;
    await _save(session.copyWith(reminder1hSentAt: at));
  }

  Future<void> setCompletePromptSent(String id, DateTime at) async {
    final session = await getSessionById(id);
    if (session == null) return;
    await _save(session.copyWith(completePromptSentAt: at));
  }

  Future<void> setFeedbackRequested(String id, DateTime at) async {
    final session = await getSessionById(id);
    if (session == null) return;
    await _save(session.copyWith(feedbackRequestedAt: at));
  }

  Future<ProviderSession?> _findByBookingId(String bookingId) async {
    if (useMockData) {
      try {
        return _sessions.firstWhere((s) => s.bookingId == bookingId);
      } catch (_) {
        return null;
      }
    }
    final snapshot = await FirebaseFirestore.instance
        .collection(_collection)
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ProviderSession.fromFirestore(snapshot.docs.first);
  }

  Future<void> _save(ProviderSession session) async {
    _invalidateProviderCache(session.providerId);
    if (useMockData) {
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _sessions[index] = session;
      } else {
        _sessions.add(session);
      }
      notifyListeners();
      onSessionSaved?.call(session);
      return;
    }
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(session.id)
        .set(session.toFirestore(), SetOptions(merge: true));
    notifyListeners();
    onSessionSaved?.call(session);
  }
}
