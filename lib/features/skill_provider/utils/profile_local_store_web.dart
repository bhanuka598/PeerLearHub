import 'dart:html' as html;

void saveLocalProfileImage(String uid, String? imageUrl) {
  final key = 'teacherProfileImage_$uid';
  if (imageUrl == null || imageUrl.isEmpty) {
    html.window.localStorage.remove(key);
    return;
  }
  html.window.localStorage[key] = imageUrl;
}

String? loadLocalProfileImage(String uid) {
  final value = html.window.localStorage['teacherProfileImage_$uid'];
  if (value == null || value.isEmpty) return null;
  return value;
}
