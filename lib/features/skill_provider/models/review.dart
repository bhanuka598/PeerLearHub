import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderReview {
  const ProviderReview({
    required this.id,
    required this.providerId,
    required this.learnerName,
    required this.lessonTitle,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.learnerId,
    this.lessonId,
    this.sessionId,
  });

  final String id;
  final String providerId;
  final String? learnerId;
  final String learnerName;
  final String? lessonId;
  final String lessonTitle;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? sessionId;

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'learnerId': learnerId,
      'learnerName': learnerName,
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'sessionId': sessionId,
    };
  }

  factory ProviderReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProviderReview.fromDocData(doc.id, data);
  }

  factory ProviderReview.fromDocData(String id, Map<String, dynamic> data) {
    return ProviderReview(
      id: id,
      providerId: data['providerId'] as String? ?? '',
      learnerId: data['learnerId'] as String?,
      learnerName: data['learnerName'] as String? ?? 'Student',
      lessonId: data['lessonId'] as String?,
      lessonTitle: data['lessonTitle'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: _parseDate(data['createdAt']),
      sessionId: data['sessionId'] as String?,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

class ReviewSummary {
  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.completedSessions,
  });

  final double averageRating;
  final int totalReviews;
  final int completedSessions;
}
