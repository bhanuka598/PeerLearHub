import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage helper for lesson thumbnails and materials.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();
  static bool useMockUpload = false;

  static const _uploadTimeout = Duration(seconds: 12);

  Future<String?> uploadLessonImage({
    required String lessonId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (useMockUpload) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return 'https://placeholder.peerlearnhub.com/lessons/$lessonId/$fileName';
    }

    // Flutter web Storage uploads retry forever when the bucket has no CORS
    // policy. Persist a compact data URL instead so the picker never hangs.
    if (kIsWeb) {
      return _toPersistableThumbnail(bytes, fileName);
    }

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('lessons/$lessonId/images/$fileName');
      await ref
          .putData(bytes, SettableMetadata(contentType: _contentType(fileName)))
          .timeout(_uploadTimeout);
      return await ref.getDownloadURL().timeout(_uploadTimeout);
    } catch (e) {
      debugPrint('Storage upload failed: $e');
      return _toPersistableThumbnail(bytes, fileName);
    }
  }

  Future<String?> uploadProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 240);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (png == null) return null;
      final compressed = png.buffer.asUint8List();
      return 'data:image/png;base64,${base64Encode(compressed)}';
    } catch (e) {
      debugPrint('Profile avatar encode failed: $e');
      return _toPersistableThumbnail(bytes, fileName);
    }
  }

  Future<String?> uploadLearningMaterial({
    required String lessonId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (useMockUpload) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return 'https://placeholder.peerlearnhub.com/lessons/$lessonId/materials/$fileName';
    }
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('lessons/$lessonId/materials/$fileName');
      await ref.putData(bytes).timeout(_uploadTimeout);
      return await ref.getDownloadURL().timeout(_uploadTimeout);
    } catch (e) {
      debugPrint('Material upload failed: $e');
      return null;
    }
  }

  String _contentType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<String?> _toPersistableThumbnail(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      if (bytes.lengthInBytes <= 350 * 1024) {
        return 'data:${_contentType(fileName)};base64,${base64Encode(bytes)}';
      }

      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 720);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (png == null) return null;

      final compressed = png.buffer.asUint8List();
      if (compressed.lengthInBytes > 900 * 1024) return null;
      return 'data:image/png;base64,${base64Encode(compressed)}';
    } catch (e) {
      debugPrint('Thumbnail encode failed: $e');
      return null;
    }
  }
}
