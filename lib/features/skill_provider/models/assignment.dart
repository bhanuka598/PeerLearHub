/// Teacher-authored assignment model nested under a [Lesson] module.
///
/// Business rules:
/// - One assignment per module (stored at `lessons/{lessonId}/modules/{moduleId}/assignment/main`).
/// - Only `status == published` assignments are visible to learners.
/// - Assignments have an independent lifecycle from the parent lesson publish state.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'assessment_status.dart';

class Assignment {
  const Assignment({
    required this.id,
    required this.lessonId,
    required this.moduleId,
    required this.providerId,
    required this.title,
    required this.description,
    required this.requirements,
    required this.maxPoints,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.dueAt,
  });

  final String id;
  final String lessonId;
  final String moduleId;
  final String providerId;
  final String title;
  final String description;
  final List<String> requirements;
  final DateTime? dueAt;
  final int maxPoints;
  final AssessmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  static String defaultId(String lessonId, String moduleId) =>
      '${lessonId}_${moduleId}_assignment';

  Assignment copyWith({
    String? id,
    String? lessonId,
    String? moduleId,
    String? providerId,
    String? title,
    String? description,
    List<String>? requirements,
    DateTime? dueAt,
    int? maxPoints,
    AssessmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDueAt = false,
  }) {
    return Assignment(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      moduleId: moduleId ?? this.moduleId,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      maxPoints: maxPoints ?? this.maxPoints,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonId': lessonId,
      'moduleId': moduleId,
      'providerId': providerId,
      'title': title,
      'description': description,
      'requirements': requirements,
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'maxPoints': maxPoints,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] as String? ?? '',
      lessonId: map['lessonId'] as String? ?? '',
      moduleId: map['moduleId'] as String? ?? '',
      providerId: map['providerId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      requirements: List<String>.from(map['requirements'] as List? ?? []),
      dueAt: map['dueAt'] != null ? _parseDate(map['dueAt']) : null,
      maxPoints: (map['maxPoints'] as num?)?.toInt() ?? 15,
      status: AssessmentStatusX.fromName(map['status'] as String?),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
