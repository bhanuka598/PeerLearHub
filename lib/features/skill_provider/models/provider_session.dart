import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus {
  upcoming,
  completed,
  cancelled,
}

class ProviderSession {
  const ProviderSession({
    required this.id,
    required this.providerId,
    required this.learnerId,
    required this.learnerName,
    required this.lessonId,
    required this.lessonTitle,
    required this.scheduledAt,
    required this.duration,
    required this.status,
    this.joinLink,
    this.location,
    this.bookingId,
    this.reminder24hSentAt,
    this.reminder1hSentAt,
    this.completePromptSentAt,
    this.feedbackRequestedAt,
  });

  final String id;
  final String providerId;
  final String learnerId;
  final String learnerName;
  final String lessonId;
  final String lessonTitle;
  final DateTime scheduledAt;
  final String duration;
  final SessionStatus status;
  final String? joinLink;
  final String? location;
  final String? bookingId;
  final DateTime? reminder24hSentAt;
  final DateTime? reminder1hSentAt;
  final DateTime? completePromptSentAt;
  final DateTime? feedbackRequestedAt;

  ProviderSession copyWith({
    SessionStatus? status,
    DateTime? scheduledAt,
    DateTime? reminder24hSentAt,
    DateTime? reminder1hSentAt,
    DateTime? completePromptSentAt,
    DateTime? feedbackRequestedAt,
    bool clearReminder24h = false,
    bool clearReminder1h = false,
    bool clearCompletePrompt = false,
    bool clearFeedbackRequested = false,
    bool clearAllAutomationFlags = false,
  }) {
    return ProviderSession(
      id: id,
      providerId: providerId,
      learnerId: learnerId,
      learnerName: learnerName,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      duration: duration,
      status: status ?? this.status,
      joinLink: joinLink,
      location: location,
      bookingId: bookingId,
      reminder24hSentAt: clearAllAutomationFlags || clearReminder24h
          ? null
          : (reminder24hSentAt ?? this.reminder24hSentAt),
      reminder1hSentAt: clearAllAutomationFlags || clearReminder1h
          ? null
          : (reminder1hSentAt ?? this.reminder1hSentAt),
      completePromptSentAt: clearAllAutomationFlags || clearCompletePrompt
          ? null
          : (completePromptSentAt ?? this.completePromptSentAt),
      feedbackRequestedAt: clearAllAutomationFlags || clearFeedbackRequested
          ? null
          : (feedbackRequestedAt ?? this.feedbackRequestedAt),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'learnerId': learnerId,
      'learnerName': learnerName,
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'duration': duration,
      'status': status.name,
      'joinLink': joinLink,
      'location': location,
      'bookingId': bookingId,
      'reminder24hSentAt': reminder24hSentAt == null
          ? null
          : Timestamp.fromDate(reminder24hSentAt!),
      'reminder1hSentAt': reminder1hSentAt == null
          ? null
          : Timestamp.fromDate(reminder1hSentAt!),
      'completePromptSentAt': completePromptSentAt == null
          ? null
          : Timestamp.fromDate(completePromptSentAt!),
      'feedbackRequestedAt': feedbackRequestedAt == null
          ? null
          : Timestamp.fromDate(feedbackRequestedAt!),
    };
  }

  factory ProviderSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderSession(
      id: doc.id,
      providerId: data['providerId'] as String? ?? '',
      learnerId: data['learnerId'] as String? ?? '',
      learnerName: data['learnerName'] as String? ?? '',
      lessonId: data['lessonId'] as String? ?? '',
      lessonTitle: data['lessonTitle'] as String? ?? '',
      scheduledAt: _parseRequiredDate(data['scheduledAt']),
      duration: data['duration'] as String? ?? '',
      status: SessionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SessionStatus.upcoming,
      ),
      joinLink: data['joinLink'] as String?,
      location: data['location'] as String?,
      bookingId: data['bookingId'] as String?,
      reminder24hSentAt: _parseOptionalDate(data['reminder24hSentAt']),
      reminder1hSentAt: _parseOptionalDate(data['reminder1hSentAt']),
      completePromptSentAt: _parseOptionalDate(data['completePromptSentAt']),
      feedbackRequestedAt: _parseOptionalDate(data['feedbackRequestedAt']),
    );
  }

  static DateTime _parseRequiredDate(dynamic value) {
    return _parseOptionalDate(value) ?? DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
