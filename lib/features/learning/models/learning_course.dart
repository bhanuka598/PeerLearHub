class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.lessonCount,
    required this.duration,
  });

  final String id;
  final String title;
  final int lessonCount;
  final String duration;
}

class LearningCourse {
  const LearningCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.instructor,
    required this.duration,
    required this.rating,
    required this.colorValue,
    required this.modules,
    this.enrolled = false,
    this.progress = 0,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String level;
  final String instructor;
  final String duration;
  final double rating;
  final int colorValue;
  final List<CourseModule> modules;
  final bool enrolled;
  final int progress;

  LearningCourse copyWith({bool? enrolled, int? progress}) => LearningCourse(
        id: id,
        title: title,
        description: description,
        category: category,
        level: level,
        instructor: instructor,
        duration: duration,
        rating: rating,
        colorValue: colorValue,
        modules: modules,
        enrolled: enrolled ?? this.enrolled,
        progress: progress ?? this.progress,
      );
}
