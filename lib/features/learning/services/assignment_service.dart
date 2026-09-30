import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:peer_learn_hub/core/auth/auth_service.dart';

class AssignmentService {
  AssignmentService._();

  static final instance = AssignmentService._();

  static String get _backendUrl => AuthService.backendBaseUrl;

  Future<void> submit({
    required String courseId,
    required String description,
    required String githubUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in before submitting an assignment.');
    }

    final trimmedUrl = githubUrl.trim();
    final github = Uri.tryParse(trimmedUrl);
    if (github == null) {
      throw ArgumentError('Enter a valid GitHub repository URL (e.g., https://github.com/username/repository).');
    }
    if (github.host.toLowerCase() != 'github.com') {
      throw ArgumentError('URL must be from github.com (e.g., https://github.com/username/repository).');
    }
    if (trimmedUrl.endsWith('/') || trimmedUrl.endsWith('github.com/') || trimmedUrl.endsWith('github.com')) {
      throw ArgumentError('Please enter a complete GitHub repository URL (e.g., https://github.com/username/repository).');
    }

    // 1. Save directly to Firebase Firestore from Flutter client (guarantees data is saved immediately)
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('assignments')
          .doc(courseId)
          .set({
            'courseId': courseId,
            'description': description.trim(),
            'githubUrl': trimmedUrl,
            'status': 'submitted',
            'submittedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .doc(courseId)
          .set({
            'courseId': courseId,
            'assignmentSubmitted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (firestoreError) {
      print('Firestore direct save error: $firestoreError');
      throw StateError('Failed to save assignment to database: $firestoreError');
    }

    // 2. Also attempt backend API call if backend is running (non-blocking / optional backup)
    try {
      final idToken = await user.getIdToken();
      if (idToken != null) {
        await http.post(
          Uri.parse('$_backendUrl/api/assignments/submit'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idToken': idToken,
            'courseId': courseId,
            'description': description.trim(),
            'githubUrl': trimmedUrl,
          }),
        ).timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      print('Backend assignment sync skipped/failed: $e');
    }
  }
}
