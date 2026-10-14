import '../../../../core/constants/app_constants.dart';
import '../../models/booking_request.dart';

List<BookingRequest> createDemoBookings() {
  final now = DateTime.now();
  return [
    BookingRequest(
      id: 'booking_1',
      providerId: AppConstants.demoProviderId,
      learnerId: 'learner_1',
      learnerName: 'Sarah Johnson',
      lessonId: 'lesson_1',
      lessonTitle: 'Introduction to Flutter',
      requestedDate: now.add(const Duration(days: 3)),
      requestedTime: '6:00 PM',
      status: BookingStatus.pending,
      createdAt: now.subtract(const Duration(hours: 5)),
      learnerVerified: true,
      message: 'Looking forward to learning Flutter basics!',
    ),
    BookingRequest(
      id: 'booking_2',
      providerId: AppConstants.demoProviderId,
      learnerId: 'learner_2',
      learnerName: 'David Kim',
      lessonId: 'lesson_3',
      lessonTitle: 'English Conversation Skills',
      requestedDate: now.add(const Duration(days: 5)),
      requestedTime: '7:00 PM',
      status: BookingStatus.pending,
      createdAt: now.subtract(const Duration(days: 1)),
      learnerVerified: false,
      message: 'Need help with interview preparation.',
    ),
    BookingRequest(
      id: 'booking_3',
      providerId: AppConstants.demoProviderId,
      learnerId: 'learner_3',
      learnerName: 'Emma Wilson',
      lessonId: 'lesson_2',
      lessonTitle: 'Beginner Photography',
      requestedDate: now.subtract(const Duration(days: 2)),
      requestedTime: '10:00 AM',
      status: BookingStatus.accepted,
      createdAt: now.subtract(const Duration(days: 7)),
      learnerVerified: true,
    ),
  ];
}
