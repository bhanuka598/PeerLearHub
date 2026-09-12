import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ModerationActivity {
  final String id;
  final String moderatorId;
  final String moderatorName;
  final String actionType; // verification_approved, verification_rejected, report_resolved, report_dismissed, warning_issued, user_banned
  final String targetId; // ID of the verification request or report
  final String targetUserId; // ID of the affected user
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ModerationActivity({
    required this.id,
    required this.moderatorId,
    required this.moderatorName,
    required this.actionType,
    required this.targetId,
    required this.targetUserId,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  // Convert from Firestore document
  factory ModerationActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModerationActivity(
      id: doc.id,
      moderatorId: data['moderatorId'] ?? '',
      moderatorName: data['moderatorName'] ?? '',
      actionType: data['actionType'] ?? '',
      targetId: data['targetId'] ?? '',
      targetUserId: data['targetUserId'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'moderatorId': moderatorId,
      'moderatorName': moderatorName,
      'actionType': actionType,
      'targetId': targetId,
      'targetUserId': targetUserId,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata ?? {},
    };
  }

  // Get display color based on action type
  Color getActionColor() {
    switch (actionType) {
      case 'verification_approved':
        return const Color(0xFF10B981); // Green
      case 'verification_rejected':
        return const Color(0xFFEF4444); // Red
      case 'report_resolved':
        return const Color(0xFF10B981); // Green
      case 'report_dismissed':
        return const Color(0xFF6B7280); // Gray
      case 'warning_issued':
        return const Color(0xFFF59E0B); // Orange
      case 'user_banned':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  // Get display icon based on action type
  IconData getActionIcon() {
    switch (actionType) {
      case 'verification_approved':
        return Icons.check_circle;
      case 'verification_rejected':
        return Icons.cancel;
      case 'report_resolved':
        return Icons.check_circle;
      case 'report_dismissed':
        return Icons.remove_circle;
      case 'warning_issued':
        return Icons.warning;
      case 'user_banned':
        return Icons.block;
      default:
        return Icons.info;
    }
  }
}