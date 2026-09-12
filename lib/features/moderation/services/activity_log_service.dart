import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/moderation_activity.dart';

class ActivityLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'moderationLogs';

  // Log a moderation action
  Future<void> logAction({
    required String moderatorId,
    required String moderatorName,
    required String actionType,
    required String targetId,
    required String targetUserId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'moderatorId': moderatorId,
        'moderatorName': moderatorName,
        'actionType': actionType,
        'targetId': targetId,
        'targetUserId': targetUserId,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });
    } catch (e) {
      print('Error logging action: $e');
    }
  }

  // Get activities for a specific moderator
  Stream<List<ModerationActivity>> getModeratorActivities(String moderatorId) {
    return _firestore
        .collection(_collection)
        .where('moderatorId', isEqualTo: moderatorId)
        .snapshots()
        .map((snapshot) {
          final activities = snapshot.docs
              .map((doc) => ModerationActivity.fromFirestore(doc))
              .toList();
          // Sort by timestamp descending
          activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return activities;
        });
  }

  // Get all activities (for admin view)
  Stream<List<ModerationActivity>> getAllActivities() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
          final activities = snapshot.docs
              .map((doc) => ModerationActivity.fromFirestore(doc))
              .toList();
          activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return activities;
        });
  }

  // Get activity statistics for a moderator
  Future<Map<String, int>> getModeratorStats(String moderatorId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = DateTime(now.year, now.month - 1, now.day);

      final snapshot = await _firestore
          .collection(_collection)
          .where('moderatorId', isEqualTo: moderatorId)
          .get();

      final activities = snapshot.docs
          .map((doc) => ModerationActivity.fromFirestore(doc))
          .toList();

      return {
        'today': activities.where((a) => a.timestamp.isAfter(today)).length,
        'thisWeek': activities.where((a) => a.timestamp.isAfter(weekAgo)).length,
        'thisMonth': activities.where((a) => a.timestamp.isAfter(monthAgo)).length,
        'total': activities.length,
      };
    } catch (e) {
      print('Error getting stats: $e');
      return {'today': 0, 'thisWeek': 0, 'thisMonth': 0, 'total': 0};
    }
  }

  // Get activities by action type
  Stream<List<ModerationActivity>> getActivitiesByType(
    String moderatorId,
    String actionType,
  ) {
    return _firestore
        .collection(_collection)
        .where('moderatorId', isEqualTo: moderatorId)
        .where('actionType', isEqualTo: actionType)
        .snapshots()
        .map((snapshot) {
          final activities = snapshot.docs
              .map((doc) => ModerationActivity.fromFirestore(doc))
              .toList();
          activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return activities;
        });
  }
}