import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  accepted,
  declined,
  rescheduled,
}

class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.providerId,
    required this.learnerId,
    required this.learnerName,
    required this.lessonId,
    required this.lessonTitle,
    required this.requestedDate,
    required this.requestedTime,
    required this.status,
    required this.createdAt,
    this.learnerVerified = false,
    this.message,
    this.rescheduleReason,
  });

  final String id;
  final String providerId;
  final String learnerId;
  final String learnerName;
  final String lessonId;
  final String lessonTitle;
  final DateTime requestedDate;
  final String requestedTime;
  final BookingStatus status;
  final DateTime createdAt;
  final bool learnerVerified;
  final String? message;
  final String? rescheduleReason;

  BookingRequest copyWith({
    BookingStatus? status,
    String? rescheduleReason,
  }) {
    return BookingRequest(
      id: id,
      providerId: providerId,
      learnerId: learnerId,
      learnerName: learnerName,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      requestedDate: requestedDate,
      requestedTime: requestedTime,
      status: status ?? this.status,
      createdAt: createdAt,
      learnerVerified: learnerVerified,
      message: message,
      rescheduleReason: rescheduleReason ?? this.rescheduleReason,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'learnerId': learnerId,
      'learnerName': learnerName,
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'requestedDate': Timestamp.fromDate(requestedDate),
      'requestedTime': requestedTime,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'learnerVerified': learnerVerified,
      'message': message,
      'rescheduleReason': rescheduleReason,
    };
  }

  factory BookingRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingRequest(
      id: doc.id,
      providerId: data['providerId'] as String? ?? '',
      learnerId: data['learnerId'] as String? ?? '',
      learnerName: data['learnerName'] as String? ?? '',
      lessonId: data['lessonId'] as String? ?? '',
      lessonTitle: data['lessonTitle'] as String? ?? '',
      requestedDate: (data['requestedDate'] as Timestamp).toDate(),
      requestedTime: data['requestedTime'] as String? ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      learnerVerified: data['learnerVerified'] as bool? ?? false,
      message: data['message'] as String?,
      rescheduleReason: data['rescheduleReason'] as String?,
    );
  }
}
