import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/demo/demo_messages.dart';
import '../models/provider_message.dart';
import '../utils/provider_id_helper.dart';

class MessageService extends ChangeNotifier {
  MessageService._();

  static final MessageService instance = MessageService._();
  static bool useMockData = true;

  static const _threadsCollection = 'messageThreads';
  static const _messagesCollection = 'messages';

  Future<List<MessageThread>> getThreads(String providerId) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return createDemoThreads()
          .where((t) => t.providerId == providerId)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    final snapshot = await FirebaseFirestore.instance
        .collection(_threadsCollection)
        .where('providerId', isEqualTo: providerId)
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs.map(MessageThread.fromFirestore).toList();
  }

  Future<List<ProviderMessage>> getMessages(String threadId) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return createDemoMessages(threadId);
    }
    final snapshot = await FirebaseFirestore.instance
        .collection(_messagesCollection)
        .where('threadId', isEqualTo: threadId)
        .orderBy('sentAt')
        .get();
    return snapshot.docs.map(ProviderMessage.fromFirestore).toList();
  }

  Future<void> sendMessage({
    required String threadId,
    required String text,
  }) async {
    final providerId = getCurrentProviderId();
    final message = ProviderMessage(
      id: '',
      threadId: threadId,
      senderId: providerId,
      senderName: 'Skill Provider',
      text: text,
      sentAt: DateTime.now(),
      isFromProvider: true,
    );

    if (useMockData) {
      notifyListeners();
      return;
    }

    await FirebaseFirestore.instance
        .collection(_messagesCollection)
        .add(message.toFirestore());
    await FirebaseFirestore.instance
        .collection(_threadsCollection)
        .doc(threadId)
        .update({
      'lastMessage': text,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    notifyListeners();
  }
}
