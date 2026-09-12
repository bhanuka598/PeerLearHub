import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../data/demo/demo_lessons.dart';
import '../../../models/lesson.dart';
import '../../../models/provider_dashboard_stats.dart';
import '../data/demo/demo_bookings.dart';
import '../data/demo/demo_sessions.dart';
import '../models/booking_request.dart';
import '../models/provider_session.dart';

class FirebaseLessonService extends ChangeNotifier {
  FirebaseLessonService._() {
    if (useMockData) {
      _lessons.addAll(createDemoLessons());
    }
  }

  static final FirebaseLessonService instance = FirebaseLessonService._();
  static bool useMockData = false;

  static const _collection = 'lessons';
  final List<Lesson> _lessons = [];
  Set<String>? _deletedIds;
  int _idCounter = 6;

  Set<String> get _removedIds => _deletedIds ??= <String>{};

  /// True when the last save could not reach the `lessons` collection and was
  /// stored under the user profile instead.
  bool lastSaveUsedFallback = false;

  CollectionReference<Map<String, dynamic>> get _lessonsRef =>
      FirebaseFirestore.instance.collection(_collection);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      FirebaseFirestore.instance.collection('users');

  String? get _authUid => FirebaseAuth.instance.currentUser?.uid;

  Future<List<Lesson>> getLessonsByProvider(String providerId) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return _lessons
          .where((l) => l.providerId == providerId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    try {
      final lessonsById = <String, Lesson>{};
      final uid = _authUid ?? providerId;

      await _readLessonsCollection(lessonsById, providerId, uid);
      await _readUserLessons(lessonsById, uid);
      _migrateUserLessonsToCollection(uid, Map<String, Lesson>.from(lessonsById));

      for (final lesson in _lessons) {
        if (lesson.providerId == providerId || lesson.providerId == uid) {
          _upsertLesson(lessonsById, lesson);
        }
      }

      lessonsById.removeWhere((id, _) => _removedIds.contains(id));

      return lessonsById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Lessons load recovered: $e');
      return _lessons
          .where((l) => l.providerId == providerId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Future<Lesson?> getLessonById(String id) async {
    Lesson? cached;
    try {
      cached = _lessons.firstWhere((l) => l.id == id);
    } catch (_) {
      cached = null;
    }

    if (useMockData) return cached;

    Lesson? fetched;
    try {
      final doc = await _lessonsRef.doc(id).get();
      if (doc.exists) fetched = Lesson.fromFirestore(doc);
    } catch (e) {
      debugPrint('Lessons collection get skipped: $e');
    }
    final uid = _authUid;
    if (fetched == null && uid != null) {
      try {
        final userDoc = await _usersRef.doc(uid).get();
        final stored = userDoc.data()?['skillProviderLessons'];
        if (stored is Map && stored[id] is Map) {
          fetched = Lesson.fromDocData(
            id,
            Map<String, dynamic>.from(stored[id] as Map),
          );
        }
      } catch (e) {
        debugPrint('User lesson fallback get skipped: $e');
      }
    }

    if (fetched == null) return cached;
    return _preferImage(fetched, cached);
  }

  Lesson _preferImage(Lesson primary, Lesson? secondary) {
    if (secondary == null) return primary;
    final primaryImage = primary.imageUrl;
    final secondaryImage = secondary.imageUrl;
    if ((primaryImage == null || primaryImage.isEmpty) &&
        secondaryImage != null &&
        secondaryImage.isNotEmpty) {
      return primary.copyWith(imageUrl: secondaryImage);
    }
    return primary;
  }

  void _upsertLesson(Map<String, Lesson> lessonsById, Lesson lesson) {
    final existing = lessonsById[lesson.id];
    if (existing == null) {
      lessonsById[lesson.id] = lesson;
      return;
    }
    final newer =
        lesson.updatedAt.isAfter(existing.updatedAt) ? lesson : existing;
    final older = identical(newer, lesson) ? existing : lesson;
    lessonsById[lesson.id] = _preferImage(newer, older);
  }

  Future<Lesson> createLesson(Lesson lesson) async {
    if (useMockData) {
      final now = DateTime.now();
      final newLesson = lesson.copyWith(
        id: 'lesson_${_idCounter++}',
        createdAt: now,
        updatedAt: now,
      );
      _lessons.add(newLesson);
      notifyListeners();
      return newLesson;
    }
    final uid = _authUid;
    if (uid == null) {
      throw StateError('Please sign in to save lessons.');
    }
    final docRef = _lessonsRef.doc();
    final now = DateTime.now();
    final newLesson = lesson.copyWith(
      id: docRef.id,
      providerId: uid,
      createdAt: now,
      updatedAt: now,
    );
    await _persistLesson(newLesson);
    _rememberLesson(newLesson);
    notifyListeners();
    return newLesson;
  }

  Future<Lesson> updateLesson(Lesson lesson) async {
    if (useMockData) {
      final index = _lessons.indexWhere((l) => l.id == lesson.id);
      if (index == -1) throw StateError('Lesson not found');
      final updated = lesson.copyWith(updatedAt: DateTime.now());
      _lessons[index] = updated;
      notifyListeners();
      return updated;
    }
    final uid = _authUid;
    if (uid == null) {
      throw StateError('Please sign in to save lessons.');
    }
    final updated = lesson.copyWith(
      providerId: uid,
      updatedAt: DateTime.now(),
    );
    await _persistLesson(updated, isUpdate: true);
    _rememberLesson(updated);
    notifyListeners();
    return updated;
  }

  Future<void> deleteLesson(String id) async {
    _removedIds.add(id);
    _lessons.removeWhere((l) => l.id == id);

    if (useMockData) {
      notifyListeners();
      return;
    }
    try {
      await _lessonsRef.doc(id).delete();
    } catch (e) {
      debugPrint('Lessons collection delete skipped: $e');
    }
    final uid = _authUid;
    if (uid != null) {
      try {
        await _usersRef.doc(uid).set({
          'skillProviderLessons': {id: FieldValue.delete()},
          'skillProviderLessons.$id': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('User lesson delete skipped: $e');
      }
    }
    notifyListeners();
  }

  void _rememberLesson(Lesson lesson) {
    _lessons.removeWhere((l) => l.id == lesson.id);
    _lessons.add(lesson);
  }

  Future<void> _readLessonsCollection(
    Map<String, Lesson> lessonsById,
    String providerId,
    String uid,
  ) async {
    try {
      final snapshot =
          await _lessonsRef.where('providerId', isEqualTo: providerId).get();
      for (final doc in snapshot.docs) {
        lessonsById[doc.id] = Lesson.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Lessons query skipped: $e');
    }

    if (lessonsById.isEmpty && uid != providerId) {
      try {
        final snapshot =
            await _lessonsRef.where('providerId', isEqualTo: uid).get();
        for (final doc in snapshot.docs) {
          lessonsById[doc.id] = Lesson.fromFirestore(doc);
        }
      } catch (e) {
        debugPrint('Lessons uid query skipped: $e');
      }
    }
  }

  Future<void> _readUserLessons(
    Map<String, Lesson> lessonsById,
    String uid,
  ) async {
    try {
      final userDoc = await _usersRef.doc(uid).get();
      final data = userDoc.data();
      if (data == null) return;

      final stored = data['skillProviderLessons'];
      if (stored is Map) {
        stored.forEach((key, value) {
          if (value is Map) {
            _upsertLesson(
              lessonsById,
              Lesson.fromDocData(
                key.toString(),
                Map<String, dynamic>.from(value),
              ),
            );
          }
        });
      }

      data.forEach((key, value) {
        if (key.startsWith('skillProviderLessons.') && value is Map) {
          final id = key.substring('skillProviderLessons.'.length);
          _upsertLesson(
            lessonsById,
            Lesson.fromDocData(id, Map<String, dynamic>.from(value)),
          );
        }
      });
    } catch (e) {
      debugPrint('User lesson fallback read skipped: $e');
    }
  }

  /// Copies lessons that were stored under `users/{uid}` into the `lessons`
  /// collection, then clears the old copy so each lesson lives in one place.
  Future<void> _migrateUserLessonsToCollection(
    String uid,
    Map<String, Lesson> lessonsById,
  ) async {
    if (uid.isEmpty || FirebaseAuth.instance.currentUser == null) return;
    if (lessonsById.isEmpty) return;

    for (final lesson in lessonsById.values.where((l) => !_removedIds.contains(l.id))) {
      try {
        await _lessonsRef.doc(lesson.id).set(
              _payloadForWrite(lesson.copyWith(providerId: uid)),
              SetOptions(merge: true),
            );
      } catch (e) {
        debugPrint('Lesson migrate skipped: $e');
        return;
      }
    }

    try {
      await _usersRef.doc(uid).set({
        'skillProviderLessons': FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('User lesson cleanup skipped: $e');
    }
  }

  Future<void> _persistLesson(Lesson lesson, {bool isUpdate = false}) async {
    final payload = _payloadForWrite(lesson);
    try {
      await _lessonsRef.doc(lesson.id).set(payload, SetOptions(merge: true));
      lastSaveUsedFallback = false;
      return;
    } catch (e) {
      debugPrint('Lessons collection write skipped: $e');
      lastSaveUsedFallback = true;
    }

    final uid = _authUid;
    if (uid == null) {
      throw StateError('Please sign in to save lessons.');
    }

    try {
      await _usersRef.doc(uid).set({
        'skillProviderLessons': {lesson.id: payload},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'invalid-argument' && payload['imageUrl'] != null) {
        payload['imageUrl'] = null;
        await _usersRef.doc(uid).set({
          'skillProviderLessons': {lesson.id: payload},
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }
      rethrow;
    }
  }

  Map<String, dynamic> _payloadForWrite(Lesson lesson) {
    final payload = lesson.toFirestore();
    final imageUrl = payload['imageUrl'];
    if (imageUrl is String && imageUrl.startsWith('data:image/') && imageUrl.length > 700000) {
      payload['imageUrl'] = null;
    }
    return payload;
  }

  Future<ProviderDashboardStats> getDashboardStats(String providerId) async {
    final lessons = await getLessonsByProvider(providerId);
    final demoPending = createDemoBookings()
        .where((b) =>
            b.providerId == providerId && b.status == BookingStatus.pending)
        .length;
    final demoCompleted = createDemoSessions()
        .where((s) =>
            s.providerId == providerId && s.status == SessionStatus.completed)
        .length;

    var pendingRequests = demoPending;
    var completedLessons = demoCompleted;

    if (!useMockData) {
      pendingRequests = 0;
      completedLessons = 0;
      try {
        final bookingSnap = await FirebaseFirestore.instance
            .collection('bookingRequests')
            .where('providerId', isEqualTo: providerId)
            .where('status', isEqualTo: BookingStatus.pending.name)
            .get();
        pendingRequests = bookingSnap.docs.length;
      } catch (e) {
        debugPrint('Booking stats unavailable: $e');
      }
      try {
        final sessionSnap = await FirebaseFirestore.instance
            .collection('sessions')
            .where('providerId', isEqualTo: providerId)
            .where('status', isEqualTo: SessionStatus.completed.name)
            .get();
        completedLessons = sessionSnap.docs.length;
      } catch (e) {
        debugPrint('Session stats unavailable: $e');
      }
    }

    return ProviderDashboardStats(
      totalLessons: lessons.length,
      activeLessons:
          lessons.where((l) => l.status == LessonStatus.active).length,
      pendingRequests: pendingRequests,
      completedLessons: completedLessons,
    );
  }

  Future<List<Lesson>> getRecentLessons(
    String providerId, {
    int limit = 3,
  }) async {
    final lessons = await getLessonsByProvider(providerId);
    return lessons.take(limit).toList();
  }

  /// Published lessons students can browse and rate.
  Future<List<Lesson>> getPublishedLessons() async {
    if (useMockData) {
      return _lessons
          .where((l) => l.status == LessonStatus.active)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final lessonsById = <String, Lesson>{};
    try {
      final snapshot = await _lessonsRef
          .where('status', isEqualTo: LessonStatus.active.name)
          .get();
      for (final doc in snapshot.docs) {
        _upsertLesson(lessonsById, Lesson.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint('Published lessons query skipped: $e');
    }

    final uid = _authUid;
    if (uid != null) {
      await _readUserLessons(lessonsById, uid);
    }

    for (final lesson in _lessons) {
      if (lesson.status == LessonStatus.active) {
        _upsertLesson(lessonsById, lesson);
      }
    }

    lessonsById.removeWhere(
      (id, lesson) =>
          _removedIds.contains(id) || lesson.status != LessonStatus.active,
    );

    return lessonsById.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
