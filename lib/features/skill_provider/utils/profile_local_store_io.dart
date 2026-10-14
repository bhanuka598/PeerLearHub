final Map<String, String> _images = {};

void saveLocalProfileImage(String uid, String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    _images.remove(uid);
    return;
  }
  _images[uid] = imageUrl;
}

String? loadLocalProfileImage(String uid) => _images[uid];
