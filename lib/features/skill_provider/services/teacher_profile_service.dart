import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/demo/demo_teacher_profile.dart';
import '../models/teacher_profile.dart';
import '../utils/profile_local_store.dart';
import 'review_service.dart';

class TeacherProfileService extends ChangeNotifier {
  TeacherProfileService._();

  static final TeacherProfileService instance = TeacherProfileService._();
  static bool useMockData = false;

  static const _collection = 'teacherProfiles';
  TeacherProfile? _cached;

  TeacherProfile? get currentProfile => _cached;

  CollectionReference<Map<String, dynamic>> get _profilesRef =>
      FirebaseFirestore.instance.collection(_collection);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      FirebaseFirestore.instance.collection('users');

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) =>
      _usersRef.doc(uid).collection('profile').doc('info');

  Future<TeacherProfile> getProfile(String uid) async {
    if (useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return createDemoTeacherProfile();
    }

    TeacherProfile? profile = await _readProfileDoc(uid);
    profile ??= await _readTeacherProfiles(uid);
    profile ??= await _readUserFallback(uid);
    if (_cached?.uid == uid) {
      if (profile == null) {
        profile = _cached;
      } else {
        if (profile.verifiedSkills.isEmpty &&
            _cached!.verifiedSkills.isNotEmpty) {
          profile = profile.copyWith(verifiedSkills: _cached!.verifiedSkills);
        }
        if ((profile.profileImageUrl == null ||
                profile.profileImageUrl!.isEmpty) &&
            (_cached!.profileImageUrl != null &&
                _cached!.profileImageUrl!.isNotEmpty)) {
          profile = profile.copyWith(profileImageUrl: _cached!.profileImageUrl);
        }
      }
    }
    profile ??= _emptyProfile(uid);
    profile = _withLocalImage(profile);

    if (profile.displayName.trim().isEmpty) {
      profile = profile.copyWith(displayName: _authDisplayName());
    }
    if (profile.email == null || profile.email!.trim().isEmpty) {
      profile = profile.copyWith(email: FirebaseAuth.instance.currentUser?.email);
    }

    profile = await _withReviewStats(profile);
    _cached = profile;
    return profile;
  }

  Future<void> updateProfile(TeacherProfile profile) async {
    if (useMockData) {
      _cached = profile;
      notifyListeners();
      return;
    }

    _cached = profile;
    saveLocalProfileImage(profile.uid, profile.profileImageUrl);
    notifyListeners();

    final payload = _payloadForWrite(profile);
    Object? lastError;

    try {
      await _profileDoc(profile.uid).set(payload, SetOptions(merge: true));
      return;
    } catch (e) {
      lastError = e;
      debugPrint('Teacher profile subdoc write skipped: $e');
    }

    try {
      await _profilesRef.doc(profile.uid).set(payload, SetOptions(merge: true));
      return;
    } catch (e) {
      lastError = e;
      debugPrint('Teacher profile collection write skipped: $e');
    }

    try {
      await _writeUserFallback(profile.uid, payload, profile);
      return;
    } catch (e) {
      lastError = e;
      debugPrint('Teacher profile user fallback write skipped: $e');
    }

    debugPrint('Teacher profile kept locally after Firebase write failed: $lastError');
  }

  TeacherProfile _withLocalImage(TeacherProfile profile) {
    if (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty) {
      return profile;
    }
    final local = loadLocalProfileImage(profile.uid);
    if (local == null || local.isEmpty) return profile;
    return profile.copyWith(profileImageUrl: local);
  }

  Map<String, dynamic> _payloadForWrite(TeacherProfile profile) {
    final payload = Map<String, dynamic>.from(profile.toFirestore());
    final imageUrl = payload['profileImageUrl'];
    if (imageUrl is String &&
        imageUrl.startsWith('data:image/') &&
        imageUrl.length > 400000) {
      payload['profileImageUrl'] = null;
    }
    payload['updatedAt'] = FieldValue.serverTimestamp();
    return payload;
  }

  Future<TeacherProfile?> _readProfileDoc(String uid) async {
    try {
      final doc = await _profileDoc(uid).get();
      if (doc.exists) {
        return TeacherProfile.fromDocData(uid, doc.data() ?? {});
      }
    } catch (e) {
      debugPrint('Teacher profile subdoc read skipped: $e');
    }
    return null;
  }

  Future<TeacherProfile?> _readTeacherProfiles(String uid) async {
    try {
      final doc = await _profilesRef.doc(uid).get();
      if (doc.exists) {
        return TeacherProfile.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Teacher profile collection read skipped: $e');
    }
    return null;
  }

  Future<TeacherProfile?> _readUserFallback(String uid) async {
    try {
      final userDoc = await _usersRef.doc(uid).get();
      final data = userDoc.data();
      final stored = data?['teacherProfile'];
      if (stored is Map) {
        return TeacherProfile.fromDocData(
          uid,
          Map<String, dynamic>.from(stored),
        );
      }
    } catch (e) {
      debugPrint('Teacher profile user fallback read skipped: $e');
    }
    return null;
  }

  Future<void> _writeUserFallback(
    String uid,
    Map<String, dynamic> payload,
    TeacherProfile profile,
  ) async {
    final smallPayload = Map<String, dynamic>.from(payload);
    final imageUrl = smallPayload['profileImageUrl'];
    if (imageUrl is String && imageUrl.length > 400000) {
      smallPayload.remove('profileImageUrl');
    }

    try {
      await _usersRef.doc(uid).set({
        'teacherProfile': smallPayload,
        'displayName': profile.displayName,
        'fullName': profile.displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    } on FirebaseException catch (e) {
      if (e.code != 'invalid-argument') rethrow;
    }

    final userDoc = await _usersRef.doc(uid).get();
    final data = Map<String, dynamic>.from(userDoc.data() ?? {});
    final lessons = data['skillProviderLessons'];
    if (lessons is Map) {
      final compacted = <String, dynamic>{};
      lessons.forEach((key, value) {
        if (value is! Map) return;
        final lesson = Map<String, dynamic>.from(value);
        final image = lesson['imageUrl'];
        if (image is String && image.startsWith('data:image/')) {
          lesson['imageUrl'] = null;
        }
        compacted[key.toString()] = lesson;
      });
      data['skillProviderLessons'] = compacted;
    }
    data['teacherProfile'] = smallPayload;
    data['displayName'] = profile.displayName;
    data['fullName'] = profile.displayName;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _usersRef.doc(uid).set(data);
  }

  TeacherProfile _emptyProfile(String uid) {
    return TeacherProfile(
      uid: uid,
      displayName: _authDisplayName(),
      bio: '',
      verifiedSkills: const [],
      overallRating: 0,
      completedSessions: 0,
      totalReviews: 0,
      email: FirebaseAuth.instance.currentUser?.email,
    );
  }

  String _authDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user?.email?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Teacher';
  }

  Future<TeacherProfile> _withReviewStats(TeacherProfile profile) async {
    try {
      final summary = await ReviewService.instance.getReviewSummary(profile.uid);
      return profile.copyWith(
        overallRating: summary.averageRating,
        totalReviews: summary.totalReviews,
        completedSessions: summary.completedSessions,
      );
    } catch (e) {
      debugPrint('Teacher profile review stats skipped: $e');
      return profile;
    }
  }
}
