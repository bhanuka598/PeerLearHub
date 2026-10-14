import 'profile_local_store_io.dart'
    if (dart.library.html) 'profile_local_store_web.dart' as impl;

void saveLocalProfileImage(String uid, String? imageUrl) {
  impl.saveLocalProfileImage(uid, imageUrl);
}

String? loadLocalProfileImage(String uid) {
  return impl.loadLocalProfileImage(uid);
}
