import 'package:flutter/foundation.dart';
import 'package:peer_learn_hub/core/auth/auth_service.dart';

enum AppUserRole { student, teacher, admin }

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

  void switchRole(AppUserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    final signedIn = await AuthService.instance.signInWithGoogle();
    if (signedIn) {
      setRole(AppUserRole.student);
    }
    return signedIn;
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
      '/forgot-password',
      '/otp-verification',
    ];
    if (allowedForGuest.contains(cleanLocation)) {
      return true;
    }

    switch (_currentRole) {
      case AppUserRole.student:
        return cleanLocation == '/learning' ||
            cleanLocation == '/learning/my-courses' ||
            cleanLocation == '/learning/course' ||
            cleanLocation == '/learning/lesson' ||
            cleanLocation == '/learning/provider-lesson' ||
            cleanLocation == '/learning/sessions' ||
            cleanLocation == '/learning/session-feedback' ||
            cleanLocation == '/notifications' ||
            cleanLocation == '/skill-exchange' ||
            _skillProviderRoutes.contains(cleanLocation);
      case AppUserRole.teacher:
        return cleanLocation == '/learning' ||
            cleanLocation == '/learning/my-courses' ||
            cleanLocation == '/learning/course' ||
            cleanLocation == '/learning/lesson' ||
            cleanLocation == '/learning/provider-lesson' ||
            cleanLocation == '/learning/sessions' ||
            cleanLocation == '/learning/session-feedback' ||
            cleanLocation == '/notifications' ||
            cleanLocation == '/skill-exchange' ||
            _skillProviderRoutes.contains(cleanLocation);
      case AppUserRole.admin:
        return cleanLocation == '/moderation';
      case null:
        return false;
    }
  }
}
