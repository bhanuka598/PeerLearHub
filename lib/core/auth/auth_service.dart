import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _defaultBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:4000',
  );
  static const String _googleServerClientId =
      '536687852853-hfodgc9f3a88chmuskg16qrck22spp4v.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _googleServerClientId,
    clientId: kIsWeb ? _googleServerClientId : null,
  );
  String? _lastError;

  String? get lastError => _lastError;

  FirebaseAuth get _requiredFirebaseAuth {
    final firebaseAuth = _firebaseAuth;
    if (firebaseAuth == null) {
      throw StateError(
        'Firebase Auth is not initialized. Check the Firebase configuration.',
      );
    }
    return firebaseAuth;
  }

  FirebaseAuth? get _firebaseAuth {
    try {
      return FirebaseAuth.instance;
    } on Object catch (error) {
      debugPrint('Firebase Auth is not initialized: $error');
      return null;
    }
  }

  static String get backendBaseUrl {
    if (kIsWeb) {
      return _defaultBackendUrl;
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000';
    }

    if (Platform.isIOS) {
      return 'http://127.0.0.1:4000';
    }

    return _defaultBackendUrl;
  }

  Future<UserCredential> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
    required String learningGoal,
  }) async {
    _lastError = null;
    final credential = await _requiredFirebaseAuth
        .createUserWithEmailAndPassword(
          email: email.trim().toLowerCase(),
          password: password,
        );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return the newly created user.');
    }

    await user.updateDisplayName(fullName.trim());
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName.trim(),
        'email': user.email,
        'learningGoal': learningGoal,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
      debugPrint('User profile was not saved: Firestore permissions denied.');
    }
    return credential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _lastError = null;
    final credential = await _requiredFirebaseAuth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied') {
          rethrow;
        }
        debugPrint(
          'Login succeeded, but the profile timestamp was not saved: '
          'Firestore permissions denied.',
        );
      }
    }
    return credential;
  }

  Future<void> signOut() async {
    await _firebaseAuth?.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> requestPasswordResetCode(String email) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/auth/password-reset/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || payload['success'] != true) {
      throw Exception(
        payload['message'] ?? 'Unable to send verification code.',
      );
    }
  }

  Future<void> verifyPasswordResetCode({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/auth/password-reset/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'otp': otp,
        'newPassword': newPassword,
      }),
    );
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || payload['success'] != true) {
      throw Exception(payload['message'] ?? 'Unable to reset password.');
    }
  }

  String authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<Map<String, dynamic>> verifyTokenWithBackend(String idToken) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/auth/verify-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    final payload = jsonDecode(response.body);

    if (response.statusCode != 200 || payload['success'] != true) {
      throw Exception(payload['message'] ?? 'Token verification failed.');
    }

    return Map<String, dynamic>.from(payload['user'] as Map);
  }

  Future<bool> signInWithGoogle() async {
    _lastError = null;
    try {
      final firebaseAuth = _firebaseAuth;
      if (firebaseAuth == null) {
        _lastError =
            'Firebase Web is not configured. Run flutterfire configure '
            'with the web platform enabled.';
        return false;
      }

      final UserCredential userCredential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        userCredential = await firebaseAuth.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _lastError = 'Google sign-in was cancelled.';
          return false;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await firebaseAuth.signInWithCredential(credential);
      }
      final firebaseIdToken = await userCredential.user?.getIdToken(true);

      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        await firebaseAuth.signOut();
        _lastError = 'Firebase did not return an ID token.';
        return false;
      }

      try {
        await verifyTokenWithBackend(firebaseIdToken);
      } on Exception catch (error) {
        await firebaseAuth.signOut();
        _lastError =
            'Backend connection failed. Start the API at '
            '$backendBaseUrl. ($error)';
        debugPrint('PeerLearnHub backend verification failed: $error');
        return false;
      }

      return true;
    } on FirebaseAuthException catch (error) {
      _lastError = 'Firebase sign-in failed (${error.code}).';
      debugPrint(
        'Firebase Google sign-in failed: ${error.code} ${error.message}',
      );
      return false;
    } on Exception catch (error) {
      final errorText = error.toString();
      if (errorText.contains('network_error') ||
          errorText.contains('ApiException: 7')) {
        _lastError =
            'Google sign-in needs an internet connection. Check the '
            'emulator network and try again.';
      } else {
        _lastError = 'Google sign-in failed: $error';
      }
      debugPrint('Google sign-in failed: $error');
      return false;
    }
  }
}
