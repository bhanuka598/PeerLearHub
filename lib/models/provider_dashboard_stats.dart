class ProviderDashboardStats {
  const ProviderDashboardStats({
    required this.totalLessons,
    required this.activeLessons,
    required this.pendingRequests,
    required this.completedLessons,
  });

  final int totalLessons;
  final int activeLessons;
  final int pendingRequests;
  final int completedLessons;
}
