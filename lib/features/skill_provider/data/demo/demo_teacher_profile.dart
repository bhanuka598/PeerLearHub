import '../../../../core/constants/app_constants.dart';
import '../../models/teacher_profile.dart';

TeacherProfile createDemoTeacherProfile() {
  return const TeacherProfile(
    uid: AppConstants.demoProviderId,
    displayName: 'Skill Provider',
    bio:
        'Passionate educator with 5+ years of experience teaching programming, languages, and creative skills.',
    verifiedSkills: [
      'Flutter Development',
      'English Conversation',
      'Photography',
      'UI/UX Design',
    ],
    overallRating: 4.8,
    completedSessions: 8,
    totalReviews: 12,
    email: 'provider@peerlearnhub.com',
  );
}
