import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:peer_learn_hub/core/constants/app_constants.dart';

/// Returns the authenticated user id, or demo id when not signed in.
String getCurrentProviderId() {
  return FirebaseAuth.instance.currentUser?.uid ??
      AppConstants.demoProviderId;
}

/// Waits for Firebase Auth to restore the current user, then returns that uid.
/// Does not create a new anonymous user, so previously saved lessons stay findable.
Future<String> resolveProviderId() async {
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    try {
      user = await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Auth restore wait failed: $e');
    }
  }
  return user?.uid ?? AppConstants.demoProviderId;
}

/// Makes sure there is a Firebase Auth user before writing lessons.
Future<String> ensureProviderId() async {
  final restored = await resolveProviderId();
  if (restored != AppConstants.demoProviderId ||
      FirebaseAuth.instance.currentUser != null) {
    return FirebaseAuth.instance.currentUser?.uid ?? restored;
  }

  try {
    final credential = await FirebaseAuth.instance.signInAnonymously();
    return credential.user?.uid ?? AppConstants.demoProviderId;
  } catch (e) {
    debugPrint('Anonymous sign-in failed: $e');
    return AppConstants.demoProviderId;
  }
}
