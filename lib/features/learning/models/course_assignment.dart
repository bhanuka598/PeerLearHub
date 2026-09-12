enum AssignmentStatus { notSubmitted, submitted, approved }

class CourseAssignment {
  const CourseAssignment({
    required this.courseId,
    required this.description,
    this.status = AssignmentStatus.notSubmitted,
    this.githubUrl,
  });

  final String courseId;
  final String description;
  final AssignmentStatus status;
  final String? githubUrl;
}
