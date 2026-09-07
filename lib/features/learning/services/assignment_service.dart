import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AssignmentService {
  AssignmentService._();

  static final instance = AssignmentService._();

  static String get _backendUrl {
    const defaultUrl = 'http://localhost:4000';
    return const String.fromEnvironment('BACKEND_URL', defaultValue: defaultUrl);
  }

  Future<void> submit({
    required String courseId,
    required String description,
    required String githubUrl,
  }) async {
    print('Starting assignment submission via backend...');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Error: User not authenticated');
      throw StateError('Please sign in before submitting an assignment.');
    }
    print('User authenticated: ${user.uid}');

    final trimmedUrl = githubUrl.trim();
    final github = Uri.tryParse(trimmedUrl);
    print('GitHub URL validation: $trimmedUrl -> $github');
    if (github == null) {
      print('Error: Invalid URL format');
      throw ArgumentError('Enter a valid GitHub repository URL (e.g., https://github.com/username/repository).');
    }
    if (github.host.toLowerCase() != 'github.com') {
      print('Error: Not a GitHub URL: ${github.host}');
      throw ArgumentError('URL must be from github.com (e.g., https://github.com/username/repository).');
    }
    if (trimmedUrl.endsWith('/') || trimmedUrl.endsWith('github.com/') || trimmedUrl.endsWith('github.com')) {
      print('Error: Incomplete GitHub URL');
      throw ArgumentError('Please enter a complete GitHub repository URL (e.g., https://github.com/username/repository).');
    }

    try {
      print('Getting Firebase ID token...');
      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw StateError('Failed to get authentication token.');
      }
      print('Got ID token');

      print('Submitting to backend: $_backendUrl/api/assignments/submit');
      
      final response = await http.post(
        Uri.parse('$_backendUrl/api/assignments/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'courseId': courseId,
          'description': description.trim(),
          'githubUrl': githubUrl.trim(),
        }),
      ).timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception('Submission timed out. Please check your internet connection and try again.');
        },
      );

      print('Response status: ${response.statusCode}');
      final responseBody = response.body;
      print('Response body: $responseBody');

      if (response.statusCode != 200) {
        throw StateError('Submission failed: $responseBody');
      }

      print('Assignment submitted successfully via backend');
    } catch (e) {
      print('Error during submission: $e');
      throw StateError('Submission failed: ${e.toString()}. Please ensure the backend server is running at $_backendUrl');
    }
  }
}
