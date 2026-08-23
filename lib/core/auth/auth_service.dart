import 'dart:convert';
import 'dart:io';

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
  );
  String? _lastError;
  String? _authenticatedRole;

  String? get lastError => _lastError;
  String? get authenticatedRole => _authenticatedRole;

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

  Future<String?> saveRole(String role) async {
    final firebaseAuth = _firebaseAuth;
    final token = await firebaseAuth?.currentUser?.getIdToken(true);
    if (firebaseAuth == null || token == null) {
      _lastError = 'Firebase authentication is not available.';
      return null;
    }

    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/auth/role'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'role': role}),
    );
    final payload = jsonDecode(response.body);
    if ((response.statusCode != 200 && response.statusCode != 201) ||
        payload['success'] != true) {
      throw Exception(payload['message'] ?? 'Unable to save account role.');
    }

    _authenticatedRole = payload['role'] as String?;
    return _authenticatedRole;
  }

  Future<bool> signInWithGoogle() async {
    _lastError = null;
    _authenticatedRole = null;
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
        final backendUser = await verifyTokenWithBackend(firebaseIdToken);
        _authenticatedRole = backendUser['role'] as String?;
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
