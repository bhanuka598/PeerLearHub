import '../../../../core/constants/app_constants.dart';
import '../../models/provider_message.dart';

List<MessageThread> createDemoThreads() {
  final now = DateTime.now();
  return [
    MessageThread(
      id: 'thread_1',
      providerId: AppConstants.demoProviderId,
      learnerId: 'learner_1',
      learnerName: 'Sarah Johnson',
      lastMessage: 'Can we focus on state management?',
      updatedAt: now.subtract(const Duration(hours: 2)),
      lessonTitle: 'Introduction to Flutter',
      unreadCount: 1,
    ),
    MessageThread(
      id: 'thread_2',
      providerId: AppConstants.demoProviderId,
      learnerId: 'learner_2',
      learnerName: 'David Kim',
      lastMessage: 'Thank you for accepting my request!',
      updatedAt: now.subtract(const Duration(days: 1)),
      lessonTitle: 'English Conversation Skills',
    ),
  ];
}

List<ProviderMessage> createDemoMessages(String threadId) {
  final now = DateTime.now();
  if (threadId == 'thread_1') {
    return [
      ProviderMessage(
        id: 'msg_1',
        threadId: threadId,
        senderId: 'learner_1',
        senderName: 'Sarah Johnson',
        text: 'Hi! I booked your Flutter lesson.',
        sentAt: now.subtract(const Duration(hours: 5)),
        isFromProvider: false,
      ),
      ProviderMessage(
        id: 'msg_2',
        threadId: threadId,
        senderId: AppConstants.demoProviderId,
        senderName: 'Skill Provider',
        text: 'Welcome! We will cover widgets and state.',
        sentAt: now.subtract(const Duration(hours: 4)),
        isFromProvider: true,
      ),
      ProviderMessage(
        id: 'msg_3',
        threadId: threadId,
        senderId: 'learner_1',
        senderName: 'Sarah Johnson',
        text: 'Can we focus on state management?',
        sentAt: now.subtract(const Duration(hours: 2)),
        isFromProvider: false,
      ),
    ];
  }
  return [
    ProviderMessage(
      id: 'msg_4',
      threadId: threadId,
      senderId: 'learner_2',
      senderName: 'David Kim',
      text: 'Thank you for accepting my request!',
      sentAt: now.subtract(const Duration(days: 1)),
      isFromProvider: false,
    ),
  ];
}
