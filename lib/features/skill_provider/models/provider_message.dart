import 'package:cloud_firestore/cloud_firestore.dart';

class MessageThread {
  const MessageThread({
    required this.id,
    required this.providerId,
    required this.learnerId,
    required this.learnerName,
    required this.lastMessage,
    required this.updatedAt,
    this.lessonTitle,
    this.unreadCount = 0,
  });

  final String id;
  final String providerId;
  final String learnerId;
  final String learnerName;
  final String lastMessage;
  final DateTime updatedAt;
  final String? lessonTitle;
  final int unreadCount;

  factory MessageThread.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageThread(
      id: doc.id,
      providerId: data['providerId'] as String? ?? '',
      learnerId: data['learnerId'] as String? ?? '',
      learnerName: data['learnerName'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lessonTitle: data['lessonTitle'] as String?,
      unreadCount: data['unreadCount'] as int? ?? 0,
    );
  }
}

class ProviderMessage {
  const ProviderMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    required this.isFromProvider,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final bool isFromProvider;

  Map<String, dynamic> toFirestore() {
    return {
      'threadId': threadId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
      'isFromProvider': isFromProvider,
    };
  }

  factory ProviderMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderMessage(
      id: doc.id,
      threadId: data['threadId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      text: data['text'] as String? ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      isFromProvider: data['isFromProvider'] as bool? ?? false,
    );
  }
}
