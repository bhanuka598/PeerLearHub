import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/demo/demo_messages.dart';
import '../models/provider_message.dart';
import '../utils/provider_id_helper.dart';

class MessageService extends ChangeNotifier {
  MessageService._();

  static final MessageService instance = MessageService._();
  static bool useMockData = false;

  static const _threadsCollection = 'messageThreads';
  static const _messagesCollection = 'messages';

  String? _cachedProviderId;
  List<MessageThread>? _cachedThreads;
  DateTime? _threadsCacheAt;
  final Map<String, List<ProviderMessage>> _cachedMessages = {};
  final Map<String, DateTime> _messagesCacheAt = {};
  static const _cacheMaxAge = Duration(seconds: 45);

  void _invalidateThreadsCache([String? providerId]) {
    if (providerId == null ||
        providerId == _cachedProviderId ||
        _cachedProviderId == null) {
      _cachedProviderId = null;
      _cachedThreads = null;
      _threadsCacheAt = null;
    }
  }

  void _invalidateMessagesCache(String threadId) {
    _cachedMessages.remove(threadId);
    _messagesCacheAt.remove(threadId);
  }

  Future<List<MessageThread>> getThreads(
    String providerId, {
    bool forceRefresh = false,
  }) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return createDemoThreads()
          .where((t) => t.providerId == providerId)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    final cacheFresh = !forceRefresh &&
        _cachedProviderId == providerId &&
        _cachedThreads != null &&
        _threadsCacheAt != null &&
        DateTime.now().difference(_threadsCacheAt!) < _cacheMaxAge;
    if (cacheFresh) {
      return List<MessageThread>.from(_cachedThreads!);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_threadsCollection)
          .where('providerId', isEqualTo: providerId)
          .get();
      final list = snapshot.docs.map(MessageThread.fromFirestore).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _cachedProviderId = providerId;
      _cachedThreads = list;
      _threadsCacheAt = DateTime.now();
      return List<MessageThread>.from(list);
    } catch (e) {
      debugPrint('Message threads load failed: $e');
      if (_cachedProviderId == providerId && _cachedThreads != null) {
        return List<MessageThread>.from(_cachedThreads!);
      }
      rethrow;
    }
  }

  Future<List<ProviderMessage>> getMessages(
    String threadId, {
    bool forceRefresh = false,
  }) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return createDemoMessages(threadId);
    }

    final cachedAt = _messagesCacheAt[threadId];
    final cacheFresh = !forceRefresh &&
        _cachedMessages.containsKey(threadId) &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheMaxAge;
    if (cacheFresh) {
      return List<ProviderMessage>.from(_cachedMessages[threadId]!);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_messagesCollection)
          .where('threadId', isEqualTo: threadId)
          .get();
      final list = snapshot.docs.map(ProviderMessage.fromFirestore).toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      _cachedMessages[threadId] = list;
      _messagesCacheAt[threadId] = DateTime.now();
      return List<ProviderMessage>.from(list);
    } catch (e) {
      debugPrint('Messages load failed: $e');
      if (_cachedMessages.containsKey(threadId)) {
        return List<ProviderMessage>.from(_cachedMessages[threadId]!);
      }
      rethrow;
    }
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
    _invalidateThreadsCache(providerId);
    _invalidateMessagesCache(threadId);
    notifyListeners();
  }
}
