/// Shared lifecycle status for teacher-authored quizzes and assignments.
/// Only [AssessmentStatus.published] is visible to learners.
enum AssessmentStatus {
  draft,
  published,
  disabled,
}

extension AssessmentStatusX on AssessmentStatus {
  String get label {
    switch (this) {
      case AssessmentStatus.draft:
        return 'Draft';
      case AssessmentStatus.published:
        return 'Published';
      case AssessmentStatus.disabled:
        return 'Disabled';
    }
  }

  static AssessmentStatus fromName(String? value) {
    return AssessmentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AssessmentStatus.draft,
    );
  }
}
