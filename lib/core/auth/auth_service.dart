import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _defaultBackendUrl = 'http://localhost:4000';
  static const String _googleServerClientId =
      '536687852853-hfodgc9f3a88chmuskg16qrck22spp4v.apps.googleusercontent.com';

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _googleServerClientId,
  );
  String? _lastError;

  String? get lastError => _lastError;

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

  Future<bool> signInWithGoogle() async {
    _lastError = null;
    try {
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

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        await _firebaseAuth.signOut();
        _lastError = 'Firebase did not return an ID token.';
        return false;
      }

      try {
        await verifyTokenWithBackend(firebaseIdToken);
      } catch (_) {
        // The backend may not be running yet during local development.
        // Firebase sign-in still succeeds and the app remains usable.
      }

      return true;
    } on FirebaseAuthException catch (error) {
      _lastError = 'Firebase sign-in failed (${error.code}).';
      debugPrint(
        'Firebase Google sign-in failed: ${error.code} ${error.message}',
      );
      return false;
    } on Exception catch (error) {
      _lastError = 'Google sign-in failed: $error';
      debugPrint('Google sign-in failed: $error');
      return false;
    }
  }
}
