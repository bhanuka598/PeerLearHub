import 'dart:typed_data';

import 'pick_local_image_io.dart'
    if (dart.library.html) 'pick_local_image_web.dart' as impl;

class PickedLocalImage {
  const PickedLocalImage({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

/// Opens the device file dialog so the user can pick a local image.
Future<PickedLocalImage?> pickLocalImage() async {
  final result = await impl.pickLocalImageBytes();
  if (result == null) return null;
  return PickedLocalImage(bytes: result.bytes, fileName: result.fileName);
}
