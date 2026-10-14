import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/auth/app_auth.dart';
import '../../../models/lesson.dart' hide SkillLevel;
import '../../learning/data/learning_store.dart';
import '../../skill_provider/services/firebase_lesson_service.dart';
import '../data/mock_skill_exchange_data.dart';
import '../models/skill_exchange_models.dart';
import '../services/ai_suggestion_service.dart';

class SkillExchangeRepository {
  static const String _exchangeRequestsCollection = 'skillExchangeRequests';
  static const String _exchangeCoursesCollection = 'exchangeCourses';

  ExchangeUser? _customCurrentUser;

  Set<String> get currentActiveUserIds {
    final ids = <String>{};
    if (_customCurrentUser != null) {
      ids.add(_customCurrentUser!.id);
    }
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      ids.add(authUser.uid);
    }
    // Also include default role IDs so simulated & authenticated actions stay unified
    ids.add(MockSkillExchangeData.currentUserStudent.id);
    if (currentUser.role == UserRole.lecturer || AppAuth.instance.currentRole == AppUserRole.teacher) {
      ids.add(MockSkillExchangeData.currentUserLecturer.id);
    }
    ids.add(currentUser.id);
    return ids;
  }

  ExchangeUser get currentUser {
    if (_customCurrentUser != null) {
      return _customCurrentUser!;
    }
    final authUser = FirebaseAuth.instance.currentUser;
    final currentRole = AppAuth.instance.currentRole;

    UserRole role = UserRole.student;
    if (currentRole == AppUserRole.teacher) {
      role = UserRole.lecturer;
    }

    if (authUser != null) {
      return ExchangeUser(
        id: authUser.uid,
        name: authUser.displayName?.trim().isNotEmpty == true
            ? authUser.displayName!
            : (authUser.email?.split('@').first ?? 'Learner'),
        email: authUser.email ?? 'learner@peerlearnhub.edu',
        avatarUrl: authUser.photoURL ??
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        role: role,
        rating: 4.9,
        completedExchangesCount: 2,
      );
    }

    return role == UserRole.lecturer
        ? MockSkillExchangeData.currentUserLecturer
        : MockSkillExchangeData.currentUserStudent;
  }

  void switchUserRole(UserRole role) {
    if (role == UserRole.student) {
      _customCurrentUser = MockSkillExchangeData.currentUserStudent;
    } else {
      _customCurrentUser = MockSkillExchangeData.currentUserLecturer;
    }
  }

  Future<List<ExchangeCourse>> getAvailableCourses() async {
    final List<ExchangeCourse> courses = [];
    final Set<String> courseIds = {};

    // 1. Fetch from Firestore 'exchangeCourses'
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_exchangeCoursesCollection)
          .get();
      for (final doc in snap.docs) {
        final c = ExchangeCourse.fromMap(doc.data(), doc.id);
        if (!courseIds.contains(c.id)) {
          courseIds.add(c.id);
          courses.add(c);
        }
      }
    } catch (e) {
      debugPrint('Error fetching exchangeCourses from Firestore: $e');
    }

    // 2. Fetch live published teacher lessons from Firestore 'lessons'
    try {
      final lessonsSnap = await FirebaseFirestore.instance
          .collection('lessons')
          .where('status', isEqualTo: 'active')
          .get();
      for (final doc in lessonsSnap.docs) {
        final lesson = Lesson.fromFirestore(doc);
        final c = _lessonToExchangeCourse(lesson);
        if (!courseIds.contains(c.id)) {
          courseIds.add(c.id);
          courses.add(c);
        }
      }
    } catch (e) {
      debugPrint('Error fetching active lessons from Firestore: $e');
    }

    // 3. Include default learning store courses as marketplace courses
    try {
      final learningCourses = LearningStore.instance.value;
      for (final lc in learningCourses) {
        if (!courseIds.contains(lc.id)) {
          final levelEnum = lc.level.toLowerCase().contains('adv')
              ? SkillLevel.advanced
              : (lc.level.toLowerCase().contains('inter')
                  ? SkillLevel.intermediate
                  : SkillLevel.beginner);

          final ec = ExchangeCourse(
            id: lc.id,
            title: lc.title,
            description: lc.description,
            category: lc.category,
            tags: [lc.category, lc.level, ...lc.modules.map((m) => m.title.split(' ').first)],
            level: levelEnum,
            ownerId: 'instructor_${lc.instructor.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
            ownerName: lc.instructor,
            ownerAvatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
            ownerRole: UserRole.lecturer,
            rating: lc.rating,
            totalLessons: lc.modules.length * 3,
            durationMinutes: 180,
            thumbnailUrl: _categoryThumbnail(lc.category),
          );
          courseIds.add(ec.id);
          courses.add(ec);
        }
      }
    } catch (e) {
      debugPrint('Error loading learning store courses: $e');
    }

    // Fallback if empty
    if (courses.isEmpty) {
      return MockSkillExchangeData.getSampleCourses();
    }

    return courses;
  }

  Future<List<ExchangeCourse>> getMyCourses() async {
    final allCourses = await getAvailableCourses();
    final uid = currentUser.id;

    // Filter courses owned by the current user
    final owned = allCourses.where((c) => c.ownerId == uid).toList();
    if (owned.isNotEmpty) {
      return owned;
    }

    // If current user has published lessons via FirebaseLessonService
    try {
      final teacherLessons = await FirebaseLessonService.instance.getLessonsByProvider(uid);
      if (teacherLessons.isNotEmpty) {
        return teacherLessons.map(_lessonToExchangeCourse).toList();
      }
    } catch (e) {
      debugPrint('Error fetching provider lessons: $e');
    }

    // Fallback: If user is student, give enrolled or beginner starter courses, or sample courses
    final samples = MockSkillExchangeData.getSampleCourses();
    if (currentUser.role == UserRole.student) {
      return samples.where((c) => c.ownerRole == UserRole.student || c.level == SkillLevel.beginner).toList();
    }
    return samples.where((c) => c.ownerId == MockSkillExchangeData.currentUserLecturer.id).toList();
  }

  Future<List<SkillExchangeRequest>> getRequests() async {
    final Map<String, SkillExchangeRequest> requestsById = {};
    final activeIds = currentActiveUserIds;
    final authUser = FirebaseAuth.instance.currentUser;

    // 1. Try reading from global 'skillExchangeRequests' collection
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_exchangeRequestsCollection)
          .get();

      for (final doc in snap.docs) {
        try {
          final req = SkillExchangeRequest.fromMap(doc.data(), doc.id);
          requestsById[req.id] = req;
        } catch (e) {
          debugPrint('Error parsing request ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading exchange requests from Firestore collection: $e');
    }

    // 2. Read from user-scoped subcollection and user document field (guaranteed read permission)
    final uidsToTry = <String>{};
    if (authUser != null) uidsToTry.add(authUser.uid);
    uidsToTry.addAll(activeIds);

    for (final uid in uidsToTry) {
      // 2a. Subcollection: users/{uid}/skillExchangeRequests
      try {
        final userSubSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection(_exchangeRequestsCollection)
            .get();
        for (final doc in userSubSnap.docs) {
          try {
            final req = SkillExchangeRequest.fromMap(doc.data(), doc.id);
            requestsById[req.id] = req;
          } catch (e) {
            debugPrint('Error parsing user subcollection request ${doc.id}: $e');
          }
        }
      } catch (e) {
        debugPrint('Reading user subcollection requests skipped: $e');
      }

      // 2b. Document field: users/{uid}.data()['skillExchangeRequests']
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final stored = userDoc.data()?['skillExchangeRequests'];
        if (stored is Map) {
          stored.forEach((key, val) {
            if (val is Map) {
              try {
                final req = SkillExchangeRequest.fromMap(Map<String, dynamic>.from(val), key.toString());
                requestsById[req.id] = req;
              } catch (_) {}
            }
          });
        }
      } catch (e) {
        debugPrint('Reading user doc requests field skipped: $e');
      }
    }

    final list = requestsById.values.toList();
    if (list.isEmpty) {
      return MockSkillExchangeData.getInitialRequests();
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<SkillExchangeRequest> createExchangeRequest({
    required ExchangeCourse offeredCourse,
    required ExchangeCourse targetCourse,
    required String message,
  }) async {
    final user = currentUser;

    final ExchangeStatus initialStatus;
    if (user.isLecturerOrTutor && targetCourse.ownerRole != UserRole.student) {
      initialStatus = ExchangeStatus.pendingPeerApproval;
    } else {
      initialStatus = ExchangeStatus.pendingTutorApproval;
    }

    // Compute match score quickly without network latency blocking submission
    double matchScore = 80.0;
    try {
      final scoreDetails = AISuggestionService.calculateMatchScoreFast(offeredCourse, targetCourse);
      matchScore = (scoreDetails['score'] as num?)?.toDouble() ?? 80.0;
    } catch (_) {}

    final docRef = FirebaseFirestore.instance.collection(_exchangeRequestsCollection).doc();

    final newRequest = SkillExchangeRequest(
      id: docRef.id,
      requesterId: user.id,
      requesterName: user.name,
      requesterAvatar: user.avatarUrl,
      requesterRole: user.role,
      offeredCourseId: offeredCourse.id,
      offeredCourseTitle: offeredCourse.title,
      targetOwnerId: targetCourse.ownerId,
      targetOwnerName: targetCourse.ownerName,
      targetOwnerAvatar: targetCourse.ownerAvatar,
      requestedCourseId: targetCourse.id,
      requestedCourseTitle: targetCourse.title,
      status: initialStatus,
      message: message,
      createdAt: DateTime.now(),
      matchScore: matchScore,
    );

    final payload = newRequest.toMap();

    // 1. Save to main Firestore collection
    try {
      await docRef.set(payload);
      debugPrint('Skill exchange request saved to collection $_exchangeRequestsCollection: ${docRef.id}');
    } catch (e) {
      debugPrint('Firestore save to collection failed: $e');
    }

    // 2. Also persist under user document and subcollection (matching Firebase security rules)
    final authUser = FirebaseAuth.instance.currentUser;
    final userIdsToSave = <String>{user.id};
    if (authUser != null) userIdsToSave.add(authUser.uid);

    for (final uid in userIdsToSave) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection(_exchangeRequestsCollection)
            .doc(docRef.id)
            .set(payload, SetOptions(merge: true));
        debugPrint('Skill exchange request saved to users/$uid/$_exchangeRequestsCollection');
      } catch (e) {
        debugPrint('Saving to user subcollection skipped: $e');
      }

      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'skillExchangeRequests': {docRef.id: payload},
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('Skill exchange request saved to users/$uid map field');
      } catch (e) {
        debugPrint('Saving to user document field skipped: $e');
      }
    }

    return newRequest;
  }

  Future<void> updateRequestStatus(String requestId, ExchangeStatus newStatus) async {
    final updateData = {
      'status': newStatus.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await FirebaseFirestore.instance
          .collection(_exchangeRequestsCollection)
          .doc(requestId)
          .update(updateData);
    } catch (e) {
      debugPrint('Firestore update failed for collection request $requestId: $e');
    }

    final authUser = FirebaseAuth.instance.currentUser;
    final userIdsToSave = <String>{currentUser.id};
    if (authUser != null) userIdsToSave.add(authUser.uid);

    for (final uid in userIdsToSave) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection(_exchangeRequestsCollection)
            .doc(requestId)
            .update(updateData);
      } catch (_) {}

      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'skillExchangeRequests.$requestId.status': newStatus.name,
          'skillExchangeRequests.$requestId.updatedAt': DateTime.now().toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<List<AIMatchSuggestion>> getAISuggestions(ExchangeCourse offeredCourse) async {
    final allCourses = await getAvailableCourses();
    return await AISuggestionService.generateMatchSuggestions(
      myOfferedCourse: offeredCourse,
      availableCourses: allCourses,
    );
  }

  ExchangeCourse _lessonToExchangeCourse(Lesson lesson) {
    SkillLevel lvl = SkillLevel.beginner;
    if (lesson.skillLevel.name.toLowerCase() == 'intermediate') {
      lvl = SkillLevel.intermediate;
    } else if (lesson.skillLevel.name.toLowerCase() == 'advanced') {
      lvl = SkillLevel.advanced;
    }

    return ExchangeCourse(
      id: lesson.id,
      title: lesson.title,
      description: lesson.description,
      category: lesson.category.name.toUpperCase(),
      tags: [lesson.category.name, lesson.skillLevel.name, ...lesson.learningOutcomes],
      level: lvl,
      ownerId: lesson.providerId,
      ownerName: 'Instructor',
      ownerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      ownerRole: UserRole.lecturer,
      rating: 4.9,
      totalLessons: 8,
      durationMinutes: 120,
      thumbnailUrl: lesson.imageUrl ?? _categoryThumbnail(lesson.category.name),
    );
  }

  String _categoryThumbnail(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('mobile') || cat.contains('flutter')) {
      return 'https://images.unsplash.com/photo-1551650975-87deedd944c3?w=500';
    } else if (cat.contains('ai') || cat.contains('machine') || cat.contains('data')) {
      return 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=500';
    } else if (cat.contains('devops') || cat.contains('cloud') || cat.contains('docker')) {
      return 'https://images.unsplash.com/photo-1667372393119-3d4c48d07fc9?w=500';
    } else if (cat.contains('design') || cat.contains('ui') || cat.contains('ux')) {
      return 'https://images.unsplash.com/photo-1581291518655-9523c932edcf?w=500';
    } else if (cat.contains('security') || cat.contains('cyber')) {
      return 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=500';
    }
    return 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=500';
  }
}

