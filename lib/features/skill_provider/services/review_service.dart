import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/demo/demo_reviews.dart';
import '../models/review.dart';

class ReviewService extends ChangeNotifier {
  ReviewService._();

  static final ReviewService instance = ReviewService._();
  static bool useMockData = false;

  static const _collection = 'reviews';
  final List<ProviderReview> _reviews = [];

  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      FirebaseFirestore.instance.collection(_collection);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      FirebaseFirestore.instance.collection('users');

  String? get _authUid => FirebaseAuth.instance.currentUser?.uid;

  String get _learnerName {
    final user = FirebaseAuth.instance.currentUser;
    final display = user?.displayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    final email = user?.email?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Student';
  }

  Future<void> refresh() async {
    await _hydrate();
    notifyListeners();
  }

  Future<List<ProviderReview>> getReviews(String providerId) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return createDemoReviews()
          .where((r) => r.providerId == providerId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    await _hydrate(providerId);
    return _reviews
        .where((r) => r.providerId == providerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<ProviderReview>> getReviewsForLesson(String lessonId) async {
    if (useMockData) {
      return createDemoReviews()
          .where((r) => r.lessonTitle.isNotEmpty)
          .toList();
    }
    await _hydrate();
    return _reviews
        .where((r) => r.lessonId == lessonId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<ReviewSummary> getReviewSummary(String providerId) async {
    if (useMockData) {
      return createDemoReviewSummary();
    }
    final reviews = await getReviews(providerId);
    if (reviews.isEmpty) {
      return const ReviewSummary(
        averageRating: 0,
        totalReviews: 0,
        completedSessions: 0,
      );
    }
    final avg =
        reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    return ReviewSummary(
      averageRating: avg,
      totalReviews: reviews.length,
      completedSessions: reviews.length,
    );
  }

  double averageForLesson(String lessonId) {
    final reviews = _reviews.where((r) => r.lessonId == lessonId).toList();
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  }

  ProviderReview? existingReviewForLesson(String lessonId) {
    final uid = _authUid;
    if (uid == null) return null;
    try {
      return _reviews.firstWhere(
        (r) => r.lessonId == lessonId && r.learnerId == uid,
      );
    } catch (_) {
      return null;
    }
  }

  ProviderReview? existingReviewForSession(String sessionId) {
    try {
      return _reviews.firstWhere((r) => r.sessionId == sessionId);
    } catch (_) {
      return null;
    }
  }

  Future<ProviderReview> addReview({
    required String providerId,
    required String lessonId,
    required String lessonTitle,
    required double rating,
    required String comment,
    String? sessionId,
  }) async {
    final uid = _authUid;
    if (uid == null) {
      throw StateError('Please sign in to rate this lesson.');
    }

    final id = sessionId != null && sessionId.isNotEmpty
        ? '${sessionId}_$uid'
        : '${lessonId}_$uid';
    final existing = _reviews.cast<ProviderReview?>().firstWhere(
      (r) => r?.id == id,
      orElse: () => null,
    );
    final review = ProviderReview(
      id: id,
      providerId: providerId,
      learnerId: uid,
      learnerName: _learnerName,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      rating: rating,
      comment: comment.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
      sessionId: sessionId,
    );

    _reviews.removeWhere((r) => r.id == id);
    _reviews.add(review);
    notifyListeners();

    await _persistReview(review);
    return review;
  }

  Future<void> _hydrate([String? providerId]) async {
    try {
      Query<Map<String, dynamic>> query = _reviewsRef;
      if (providerId != null && providerId.isNotEmpty) {
        query = query.where('providerId', isEqualTo: providerId);
      }
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        _merge(ProviderReview.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint('Reviews collection read skipped: $e');
    }

    final uid = _authUid;
    if (uid == null) return;

    try {
      final userDoc = await _usersRef.doc(uid).get();
      final data = userDoc.data();
      if (data == null) return;
      _mergeStoredMap(data['skillProviderReviews']);
      _mergeStoredMap(data['submittedReviews']);
    } catch (e) {
      debugPrint('User review fallback read skipped: $e');
    }
  }

  void _mergeStoredMap(dynamic stored) {
    if (stored is! Map) return;
    stored.forEach((key, value) {
      if (value is Map) {
        _merge(
          ProviderReview.fromDocData(
            key.toString(),
            Map<String, dynamic>.from(value),
          ),
        );
      }
    });
  }

  void _merge(ProviderReview review) {
    _reviews.removeWhere((r) => r.id == review.id);
    _reviews.add(review);
  }

  Future<void> _persistReview(ProviderReview review) async {
    final payload = review.toFirestore();
    try {
      await _reviewsRef.doc(review.id).set(payload, SetOptions(merge: true));
      return;
    } catch (e) {
      debugPrint('Reviews collection write skipped: $e');
    }

    final uid = _authUid;
    if (uid == null) return;

    try {
      final fields = <String, dynamic>{
        'submittedReviews': {review.id: payload},
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (uid == review.providerId) {
        fields['skillProviderReviews'] = {review.id: payload};
      }
      await _usersRef.doc(uid).set(fields, SetOptions(merge: true));
    } catch (e) {
      debugPrint('User review fallback write skipped: $e');
    }
  }
}
