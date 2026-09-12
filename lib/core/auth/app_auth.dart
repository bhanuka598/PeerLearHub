import 'package:flutter/foundation.dart';
import 'package:peer_learn_hub/core/auth/auth_service.dart';

enum AppUserRole { student, teacher, moderator, admin }

class AppAuth extends ChangeNotifier {
  AppAuth._();

  static final AppAuth instance = AppAuth._();

  AppUserRole? _currentRole;

  AppUserRole? get currentRole => _currentRole;

  static const _skillProviderRoutes = [
    '/skill-provider',
    '/skill-provider/my-lessons',
    '/skill-provider/create',
    '/skill-provider/edit',
    '/skill-provider/lesson',
    '/skill-provider/bookings',
    '/skill-provider/booking',
    '/skill-provider/reschedule',
    '/skill-provider/messages',
    '/skill-provider/sessions',
    '/skill-provider/session',
    '/skill-provider/reviews',
    '/skill-provider/profile',
    '/notifications',
    '/learning/sessions',
    '/learning/session-feedback',
  ];

  void setRole(AppUserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void setRoleFromApi(String? roleString) {
    switch (roleString) {
      case 'moderator':
        setRole(AppUserRole.moderator);
        break;
      case 'teacher':
        setRole(AppUserRole.teacher);
        break;
      case 'admin':
        setRole(AppUserRole.admin);
        break;
      default:
        setRole(AppUserRole.student);
    }
  }

  String getHomeRouteForRole(String? roleString) {
    switch (roleString) {
      case 'moderator':
        return '/moderation';
      case 'teacher':
        return '/skill-provider';
      case 'admin':
        return '/moderation';
      default:
        return '/learning';
    }
  }

  void switchRole(AppUserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    final signedIn = await AuthService.instance.signInWithGoogle();
    if (signedIn) {
      // Prefer the backend role when available, but fall back to the saved Firestore role.
      try {
        final loginData = await AuthService.instance.loginWithRole();
        final roleString = loginData['user']['role'] as String?;
        setRoleFromApi(roleString);
      } catch (e) {
        debugPrint('Failed to fetch user role from backend: $e');
        setRoleFromApi(await AuthService.instance.getCurrentUserRole());
      }
    }
    return signedIn;
  }

  Future<bool> registerAsModerator() async {
    try {
      final userData = await AuthService.instance.registerAsModerator(
        adminKey: adminKey,
      );

      // Update role based on response
      final roleString = userData['role'] as String?;
      setRoleFromApi(roleString);

      return true;
    } catch (e) {
      debugPrint('Failed to register as moderator: $e');
      return false;
    }
  }

  void logout() {
    _currentRole = null;
    AuthService.instance.signOut();
    notifyListeners();
  }

  String getHomeRoute() {
    switch (_currentRole) {
      case AppUserRole.student:
        return '/learning';
      case AppUserRole.teacher:
        return '/skill-provider';
      case AppUserRole.moderator:
        return '/moderation';
      case AppUserRole.admin:
        return '/moderation';
      case null:
        return '/login';
    }
  }

  bool canAccess(String location) {
    final cleanLocation = location.split('?').first;
    const allowedForGuest = [
      '/',
      '/loading',
      '/welcome',
      '/login',
      '/register',
      '/moderation/register',
      '/forgot-password',
      '/otp-verification',
    ];
    if (allowedForGuest.contains(cleanLocation)) {
      return true;
    }

    switch (_currentRole) {
      case AppUserRole.student:
      case AppUserRole.teacher:
        return cleanLocation == '/learning' ||
            cleanLocation == '/learning/my-courses' ||
            cleanLocation == '/learning/course' ||
            cleanLocation == '/learning/lesson' ||
            cleanLocation == '/learning/quiz' ||
            cleanLocation == '/learning/assignment' ||
            cleanLocation == '/learning/provider-lesson' ||
            cleanLocation == '/profile' ||
            cleanLocation == '/skill-exchange' ||
            _skillProviderRoutes.contains(cleanLocation);
      case AppUserRole.moderator:
        return cleanLocation == '/moderation' ||
            cleanLocation == '/profile';
      case AppUserRole.admin:
        return cleanLocation == '/moderation' ||
            cleanLocation == '/profile';
      case null:
        return false;
    }
  }
}