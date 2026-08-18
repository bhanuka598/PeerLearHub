import '../../models/provider_dashboard_stats.dart';

/// Demo dashboard statistics for Sprint 1.
/// Replace with Firebase-backed data via [LessonService.getDashboardStats].
const demoDashboardStats = ProviderDashboardStats(
  totalLessons: 5,
  activeLessons: 4,
  pendingRequests: 2,
  completedLessons: 8,
);
