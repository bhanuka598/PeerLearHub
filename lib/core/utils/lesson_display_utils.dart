import '../../models/lesson.dart';

extension LessonCategoryDisplay on LessonCategory {
  String get label {
    switch (this) {
      case LessonCategory.programming:
        return 'Programming';
      case LessonCategory.design:
        return 'Design';
      case LessonCategory.business:
        return 'Business';
      case LessonCategory.languages:
        return 'Languages';
      case LessonCategory.music:
        return 'Music';
      case LessonCategory.photography:
        return 'Photography';
      case LessonCategory.cooking:
        return 'Cooking';
      case LessonCategory.other:
        return 'Other';
    }
  }
}

extension SkillLevelDisplay on SkillLevel {
  String get label {
    switch (this) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.advanced:
        return 'Advanced';
    }
  }
}

extension LessonTypeDisplay on LessonType {
  String get label {
    switch (this) {
      case LessonType.online:
        return 'Online';
      case LessonType.inPerson:
        return 'In Person';
      case LessonType.both:
        return 'Both';
    }
  }
}

extension LessonStatusDisplay on LessonStatus {
  String get label {
    switch (this) {
      case LessonStatus.draft:
        return 'Draft';
      case LessonStatus.active:
        return 'Active';
      case LessonStatus.inactive:
        return 'Inactive';
    }
  }
}

String formatLessonPrice(Lesson lesson) {
  if (lesson.isFree) {
    return 'Free';
  }
  return '\$${lesson.price?.toStringAsFixed(2) ?? '0.00'}';
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
