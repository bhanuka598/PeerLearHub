import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class ResolvedLoginSession {
  const ResolvedLoginSession({required this.role, this.redirectRoute});

  final String? role;
  final String? redirectRoute;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// Set with `--dart-define=BACKEND_URL=http://host:4000` for a physical
  /// device APK. Empty keeps the platform defaults below.
  static const String _configuredBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
  );
  static const String _googleServerClientId =
      '536687852853-hfodgc9f3a88chmuskg16qrck22spp4v.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(clientId: _googleServerClientId)
      : GoogleSignIn(serverClientId: _googleServerClientId);
  String? _lastError;

  String? get lastError => _lastError;

  static const Duration _backendTimeout = Duration(seconds: 4);

  Future<http.Response> _postBackend(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      return await http
          .post(
            Uri.parse('$backendBaseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_backendTimeout);
    } on TimeoutException {
      throw Exception('Network error. Check your connection and try again.');
    }
  }

  void _saveUserProfile({
    required String uid,
    required Map<String, dynamic> data,
    bool merge = false,
    required String permissionDeniedMessage,
  }) {
    unawaited(
      _writeUserProfile(
        uid: uid,
        data: data,
        merge: merge,
        permissionDeniedMessage: permissionDeniedMessage,
      ),
    );
  }

  Future<void> _writeUserProfile({
    required String uid,
    required Map<String, dynamic> data,
    required bool merge,
    required String permissionDeniedMessage,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, merge ? SetOptions(merge: true) : null);
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        debugPrint(permissionDeniedMessage);
        return;
      }
      debugPrint('User profile was not saved: $error');
    } catch (error) {
      debugPrint('User profile was not saved: $error');
    }
  }

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
    final configured = _configuredBackendUrl.trim();
    if (configured.isNotEmpty) {
      return configured.endsWith('/')
          ? configured.substring(0, configured.length - 1)
          : configured;
    }

    if (kIsWeb) {
      return 'http://localhost:4000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000';
    }

    if (Platform.isIOS) {
      return 'http://127.0.0.1:4000';
    }

    return 'http://localhost:4000';
  }

  Future<UserCredential> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
    required String learningGoal,
    String role = 'student',
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
    _saveUserProfile(
      uid: user.uid,
      permissionDeniedMessage:
          'User profile was not saved: Firestore permissions denied.',
      data: {
        'uid': user.uid,
        'fullName': fullName.trim(),
        'email': user.email,
        'learningGoal': learningGoal,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
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
      _saveUserProfile(
        uid: user.uid,
        merge: true,
        permissionDeniedMessage:
            'Login succeeded, but the profile timestamp was not saved: '
            'Firestore permissions denied.',
        data: {
          'uid': user.uid,
          'email': user.email,
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }
    return credential;
  }

  Future<void> signOut() async {
    await _firebaseAuth?.signOut();
    await _googleSignIn.signOut();
  }

  /// Waits for Firebase to restore a saved session, if one exists.
  Future<User?> currentUserOrNull() async {
    final auth = _firebaseAuth;
    if (auth == null) {
      return null;
    }

    try {
      return await auth.authStateChanges().first.timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {
      return auth.currentUser;
    }
  }

  Future<void> requestPasswordResetCode(String email) async {
    final response = await _postBackend(
      '/api/auth/password-reset/request',
      body: {'email': email.trim().toLowerCase()},
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
    final response = await _postBackend(
      '/api/auth/password-reset/verify',
      body: {
        'email': email.trim().toLowerCase(),
        'otp': otp,
        'newPassword': newPassword,
      },
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
    final response = await _postBackend(
      '/api/auth/verify-token',
      body: {'idToken': idToken},
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

  Future<String> getCurrentUserRole() async {
    final user = _firebaseAuth?.currentUser;
    if (user == null) {
      return 'student';
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      final role = (userData?['role'] as String?)?.trim().toLowerCase();
      return role == null || role.isEmpty ? 'student' : role;
    } catch (e) {
      debugPrint('Error getting current user role: $e');
      return 'student';
    }
  }

  /// Role lookup used after sign-in. The Firestore read and the backend
  /// login start together, and the first successful result is used. When the
  /// API answers first, its redirect is kept. When it is unreachable, the
  /// Firestore role is used without waiting for the backend timeout.
  Future<ResolvedLoginSession> resolveLoginSession() {
    final completer = Completer<ResolvedLoginSession>();
    var pending = 2;

    void succeed(ResolvedLoginSession session) {
      if (!completer.isCompleted) {
        completer.complete(session);
      }
    }

    void fail(Object error) {
      pending -= 1;
      debugPrint('Login role lookup failed: $error');
      if (pending == 0 && !completer.isCompleted) {
        completer.complete(const ResolvedLoginSession(role: 'student'));
      }
    }

    _sessionFromBackend().then(
      succeed,
      onError: (Object error, StackTrace _) {
        fail(error);
      },
    );
    _sessionFromFirestore().then(
      succeed,
      onError: (Object error, StackTrace _) {
        fail(error);
      },
    );
    return completer.future;
  }

  Future<ResolvedLoginSession> _sessionFromFirestore() async {
    final user = _firebaseAuth?.currentUser;
    if (user == null) {
      throw StateError('User must be logged in.');
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = (userDoc.data()?['role'] as String?)?.trim().toLowerCase();
    return ResolvedLoginSession(
      role: role == null || role.isEmpty ? 'student' : role,
    );
  }

  Future<ResolvedLoginSession> _sessionFromBackend() async {
    final loginData = await loginWithRole();
    final user = loginData['user'];
    final role = user is Map ? user['role'] as String? : null;
    final redirectRoute = loginData['redirectRoute'] as String?;
    return ResolvedLoginSession(role: role, redirectRoute: redirectRoute);
  }

  Future<bool> isModerator() async {
    final user = _firebaseAuth?.currentUser;
    if (user == null) {
      return false;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data();
      if (userData == null) {
        return false;
      }

      return userData['role'] == 'moderator';
    } catch (e) {
      debugPrint('Error checking moderator status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> registerAsModerator() async {
    final user = _firebaseAuth?.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to register as moderator.');
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Failed to get Firebase ID token.');
    }

    final response = await _postBackend(
      '/api/auth/register-moderator',
      body: {'idToken': idToken},
    );

    final payload = jsonDecode(response.body);

    if (response.statusCode != 200 || payload['success'] != true) {
      throw Exception(payload['message'] ?? 'Failed to register as moderator.');
    }

    return Map<String, dynamic>.from(payload['user'] as Map);
  }

  Future<Map<String, dynamic>> loginWithRole() async {
    final user = _firebaseAuth?.currentUser;
    if (user == null) {
      throw Exception('User must be logged in.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Failed to get Firebase ID token.');
    }

    final response = await _postBackend(
      '/api/auth/login-with-role',
      body: {'idToken': idToken},
    );

    final payload = jsonDecode(response.body);

    if (response.statusCode != 200 || payload['success'] != true) {
      throw Exception(payload['message'] ?? 'Login failed.');
    }

    return Map<String, dynamic>.from(payload as Map);
  }
}
