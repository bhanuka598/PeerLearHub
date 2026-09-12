import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModeratorAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Check if current user is a moderator
  Future<bool> isCurrentUserModerator() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final role = userDoc.data()?['role'] as String?;
      return role == 'moderator';
    } catch (e) {
      print('Error checking moderator status: $e');
      return false;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }
}
