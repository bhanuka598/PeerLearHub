import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/moderation_report.dart';

class CommunitySafetyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate trust index based on reports and resolutions
  Future<double> calculateTrustIndex() async {
    try {
      final reportsSnapshot = await _firestore.collection('reports').get();
      final totalReports = reportsSnapshot.docs.length;
      
      if (totalReports == 0) return 100.0;

      final resolvedReports = reportsSnapshot.docs
          .where((doc) => (doc.data()['status'] as String?) == 'resolved')
          .length;

      final dismissedReports = reportsSnapshot.docs
          .where((doc) => (doc.data()['status'] as String?) == 'dismissed')
          .length;

      // Trust index: higher when more reports are handled
      final handledReports = resolvedReports + dismissedReports;
      final handledPercentage = (handledReports / totalReports) * 100;
      
      // Penalize for high severity unresolved reports
      final highSeverityOpen = reportsSnapshot.docs
          .where((doc) => 
              (doc.data()['severity'] as String?) == 'high' &&
              (doc.data()['status'] as String?) == 'open')
          .length;

      final trustIndex = handledPercentage - (highSeverityOpen * 5);
      return trustIndex.clamp(0, 100);
    } catch (e) {
      print('Error calculating trust index: $e');
      return 0.0;
    }
  }

  // Get trust score distribution
  Future<Map<String, int>> getTrustScoreDistribution() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      int excellent = 0;
      int good = 0;
      int fair = 0;
      int poor = 0;

      for (var doc in usersSnapshot.docs) {
        final trustScore = (doc.data()['trustScore'] as num?)?.toInt();

        if (trustScore == null) {
          continue;
        }

        if (trustScore >= 90) {
          excellent++;
        } else if (trustScore >= 75) {
          good++;
        } else if (trustScore >= 50) {
          fair++;
        } else {
          poor++;
        }
      }

      return {
        'excellent': excellent,
        'good': good,
        'fair': fair,
        'poor': poor,
        'total': usersSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting trust distribution: $e');
      return {'excellent': 0, 'good': 0, 'fair': 0, 'poor': 0, 'total': 0};
    }
  }

  // Get report volume over time (last 7 days)
  Future<List<int>> getReportVolume() async {
    try {
      final now = DateTime.now();
      final volumes = <int>[];

      for (int i = 6; i >= 0; i--) {
        final dayStart = DateTime(now.year, now.month, now.day - i);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final snapshot = await _firestore
            .collection('reports')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
            .where('createdAt', isLessThan: Timestamp.fromDate(dayEnd))
            .get();

        volumes.add(snapshot.docs.length);
      }

      return volumes;
    } catch (e) {
      print('Error getting report volume: $e');
      return List.filled(7, 0);
    }
  }

  // Get top report categories
  Future<Map<String, int>> getTopCategories() async {
    try {
      final snapshot = await _firestore.collection('reports').get();
      final categoryCounts = <String, int>{};

      for (var doc in snapshot.docs) {
        final reason = doc.data()['reason'] as String?;
        if (reason != null) {
          categoryCounts[reason] = (categoryCounts[reason] ?? 0) + 1;
        }
      }

      // Convert to display names and sort
      final categoryMap = <String, int>{};
      categoryCounts.forEach((key, value) {
        final displayName = _getReasonDisplayName(key);
        categoryMap[displayName] = value;
      });

      // Sort by count and return top 5
      final sortedEntries = categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topCategories = <String, int>{};
      for (var i = 0; i < sortedEntries.length && i < 5; i++) {
        topCategories[sortedEntries[i].key] = sortedEntries[i].value;
      }

      return topCategories;
    } catch (e) {
      print('Error getting top categories: $e');
      return {};
    }
  }

  // Get safety alerts
  Future<List<Map<String, dynamic>>> getSafetyAlerts() async {
    try {
      final alerts = <Map<String, dynamic>>[];

      // Check for IP flood (multiple reports from same IP in short time)
      // This would require IP tracking - for now return mock
      
      // Check for API rate limiting issues
      final recentReportsSnapshot = await _firestore
          .collection('reports')
          .where('createdAt', 
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(hours: 1))))
          .get();

      if (recentReportsSnapshot.docs.length > 50) {
        alerts.add({
          'title': 'High Report Volume',
          'description': '${recentReportsSnapshot.docs.length} reports in last hour',
          'type': 'warning',
          'time': 'Just now',
        });
      }

      // Check for multiple high severity reports
      final highSeveritySnapshot = await _firestore
          .collection('reports')
          .where('severity', isEqualTo: 'high')
          .where('status', isEqualTo: 'open')
          .get();

      if (highSeveritySnapshot.docs.length > 5) {
        alerts.add({
          'title': 'Multiple High Severity Reports',
          'description': '${highSeveritySnapshot.docs.length} unresolved high severity reports',
          'type': 'critical',
          'time': 'Active',
        });
      }

      return alerts;
    } catch (e) {
      print('Error getting safety alerts: $e');
      return [];
    }
  }

  String _getReasonDisplayName(String reason) {
    switch (reason) {
      case 'spam':
        return 'Spam';
      case 'harassment':
        return 'Harassment';
      case 'unsafeLocation':
        return 'Unsafe Location';
      case 'inappropriateContent':
        return 'Inappropriate Content';
      case 'fraudScam':
        return 'Fraud/Scam';
      case 'other':
        return 'Other';
      default:
        return reason;
    }
  }
}
