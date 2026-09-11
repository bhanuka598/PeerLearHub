import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  reminder24h,
  reminder1h,
  completeSession,
  feedbackRequest,
}

enum NotificationRecipientRole { teacher, learner }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.recipientRole,
    required this.type,
    required this.title,
    required this.body,
    required this.sessionId,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String recipientId;
  final NotificationRecipientRole recipientRole;
  final NotificationType type;
  final String title;
  final String body;
  final String sessionId;
  final DateTime createdAt;
  final bool read;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      recipientId: recipientId,
      recipientRole: recipientRole,
      type: type,
      title: title,
      body: body,
      sessionId: sessionId,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'recipientRole': recipientRole.name,
      'type': type.name,
      'title': title,
      'body': body,
      'sessionId': sessionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
    };
  }

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotification(
      id: doc.id,
      recipientId: data['recipientId'] as String? ?? '',
      recipientRole: NotificationRecipientRole.values.firstWhere(
        (e) => e.name == data['recipientRole'],
        orElse: () => NotificationRecipientRole.learner,
      ),
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.reminder24h,
      ),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      sessionId: data['sessionId'] as String? ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      read: data['read'] as bool? ?? false,
    );
  }

  static String buildId({
    required String sessionId,
    required NotificationType type,
    required NotificationRecipientRole role,
    required DateTime scheduledAt,
  }) {
    return '${sessionId}_${type.name}_${role.name}_${scheduledAt.millisecondsSinceEpoch}';
  }
}
