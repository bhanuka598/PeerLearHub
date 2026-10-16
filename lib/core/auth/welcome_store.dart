import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that the intro screen has already been shown on this device.
class WelcomeStore {
  WelcomeStore._();

  static const _key = 'peerlearnhub_welcome_seen';

  /// In-memory copy so routing can decide before the next disk read.
  static bool seen = false;

  /// First launch opens the intro. Later launches open sign-in.
  static String get entryRoute => seen ? '/login' : '/welcome';

  static Future<bool> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(_key) ?? false;
    } catch (_) {
      // Keep the in-memory value when preferences are unavailable.
    }
    return seen;
  }

  static Future<void> markSeen() async {
    seen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {}
  }
}
