import 'package:peer_learn_hub/core/auth/auth_service.dart';

enum AppUserRole { student, teacher, admin }

class AppAuth {
  AppAuth._();

  static final AppAuth instance = AppAuth._();

  AppUserRole? _currentRole;

  AppUserRole? get currentRole => _currentRole;

  void setRole(AppUserRole role) {
    _currentRole = role;
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
    final allowedForGuest = [
      '/',
      '/loading',
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
            cleanLocation == '/skill-exchange';
      case AppUserRole.teacher:
        return cleanLocation == '/skill-exchange' ||
            cleanLocation == '/skill-provider' ||
            cleanLocation == '/skill-provider/my-lessons' ||
            cleanLocation == '/skill-provider/create' ||
            cleanLocation == '/skill-provider/edit';
      case AppUserRole.admin:
        return cleanLocation == '/moderation';
      case null:
        return false;
    }
  }
}
