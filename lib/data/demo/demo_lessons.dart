import '../../core/constants/app_constants.dart';
import '../../models/lesson.dart';

/// Demo lesson data for Sprint 1.
/// Structured for easy replacement with Firestore documents.
List<Lesson> createDemoLessons() {
  final now = DateTime.now();

  return [
    Lesson(
      id: 'lesson_1',
      providerId: AppConstants.demoProviderId,
      title: 'Introduction to Flutter',
      description:
          'Learn the fundamentals of Flutter development including widgets, state management, and building your first app.',
      category: LessonCategory.programming,
      skillLevel: SkillLevel.beginner,
      duration: '2 hours',
      lessonType: LessonType.online,
      availability: const LessonAvailability(
        availableDays: ['Monday', 'Wednesday', 'Friday'],
        preferredTime: '6:00 PM - 8:00 PM',
      ),
      location: 'Google Meet - link shared after booking',
      isFree: false,
      price: 25.00,
      status: LessonStatus.active,
      createdAt: now.subtract(const Duration(days: 14)),
      updatedAt: now.subtract(const Duration(days: 2)),
    ),
    Lesson(
      id: 'lesson_2',
      providerId: AppConstants.demoProviderId,
      title: 'Beginner Photography',
      description:
          'Master camera basics, composition techniques, and lighting for stunning photos.',
      category: LessonCategory.photography,
      skillLevel: SkillLevel.beginner,
      duration: '1 hour',
      lessonType: LessonType.both,
      availability: const LessonAvailability(
        availableDays: ['Tuesday', 'Saturday'],
        preferredTime: '10:00 AM - 12:00 PM',
      ),
      location: 'City Park Studio or Zoom',
      isFree: true,
      status: LessonStatus.active,
      createdAt: now.subtract(const Duration(days: 21)),
      updatedAt: now.subtract(const Duration(days: 5)),
    ),
    Lesson(
      id: 'lesson_3',
      providerId: AppConstants.demoProviderId,
      title: 'English Conversation Skills',
      description:
          'Improve your spoken English through guided conversations and practical exercises.',
      category: LessonCategory.languages,
      skillLevel: SkillLevel.intermediate,
      duration: '1 hour',
      lessonType: LessonType.online,
      availability: const LessonAvailability(
        availableDays: ['Monday', 'Thursday'],
        preferredTime: '7:00 PM - 8:00 PM',
      ),
      location: 'Microsoft Teams',
      isFree: false,
      price: 15.00,
      status: LessonStatus.active,
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
    Lesson(
      id: 'lesson_4',
      providerId: AppConstants.demoProviderId,
      title: 'UI/UX Design Basics',
      description:
          'Explore user-centered design principles, wireframing, and prototyping with Figma.',
      category: LessonCategory.design,
      skillLevel: SkillLevel.beginner,
      duration: '2 hours',
      lessonType: LessonType.online,
      availability: const LessonAvailability(
        availableDays: ['Wednesday', 'Sunday'],
        preferredTime: '2:00 PM - 4:00 PM',
      ),
      location: 'Zoom - meeting link provided',
      isFree: false,
      price: 30.00,
      status: LessonStatus.draft,
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3)),
    ),
    Lesson(
      id: 'lesson_5',
      providerId: AppConstants.demoProviderId,
      title: 'Guitar for Beginners',
      description:
          'Start your musical journey with basic chords, strumming patterns, and simple songs.',
      category: LessonCategory.music,
      skillLevel: SkillLevel.beginner,
      duration: '1 hour',
      lessonType: LessonType.inPerson,
      availability: const LessonAvailability(
        availableDays: ['Friday', 'Saturday'],
        preferredTime: '4:00 PM - 6:00 PM',
      ),
      location: 'Music Room 204, University Campus',
      isFree: false,
      price: 20.00,
      status: LessonStatus.inactive,
      createdAt: now.subtract(const Duration(days: 45)),
      updatedAt: now.subtract(const Duration(days: 30)),
    ),
  ];
}
