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
  static bool useMockData = true;

  static const _collection = 'sessions';
  final List<ProviderSession> _sessions = [];

  Future<List<ProviderSession>> getSessionsForAutomation() async {
    if (useMockData) {
      return List<ProviderSession>.from(_sessions);
    }
    final snapshot =
        await FirebaseFirestore.instance.collection(_collection).get();
    return snapshot.docs.map(ProviderSession.fromFirestore).toList();
  }

  Future<List<ProviderSession>> getSessionsByProvider(String providerId) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final ids = <String>{providerId, AppConstants.demoProviderId};
      return _sessions.where((s) => ids.contains(s.providerId)).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }
    final snapshot = await FirebaseFirestore.instance
        .collection(_collection)
        .where('providerId', isEqualTo: providerId)
        .orderBy('scheduledAt')
        .get();
    return snapshot.docs.map(ProviderSession.fromFirestore).toList();
  }

  Future<List<ProviderSession>> getSessionsByLearner(String learnerId) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // Mock identity: signed-in testers still see demo learner sessions.
      return List<ProviderSession>.from(_sessions)
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }
    final snapshot = await FirebaseFirestore.instance
        .collection(_collection)
        .where('learnerId', isEqualTo: learnerId)
        .orderBy('scheduledAt')
        .get();
    return snapshot.docs.map(ProviderSession.fromFirestore).toList();
  }

  Future<List<ProviderSession>> getUpcomingSessions(String providerId) async {
    final all = await getSessionsByProvider(providerId);
    return all.where((s) => s.status == SessionStatus.upcoming).toList();
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
    if (useMockData) {
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _sessions[index] = session;
      } else {
        _sessions.add(session);
      }
      notifyListeners();
      return;
    }
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(session.id)
        .set(session.toFirestore(), SetOptions(merge: true));
    notifyListeners();
  }
}
