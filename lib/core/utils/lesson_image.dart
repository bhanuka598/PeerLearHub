import 'dart:convert';

import 'package:flutter/material.dart';

/// Builds an [ImageProvider] for a lesson thumbnail.
///
/// Data URLs are decoded from the base64 payload directly. Going through
/// [Uri.data] corrupts `+` characters and often fails on larger images, which
/// made saved thumbnails look like they were never added.
ImageProvider? lessonImageProvider(String? url) {
  final value = url?.trim();
  if (value == null || value.isEmpty) return null;
  if (value.contains('placeholder.peerlearnhub.com')) return null;

  if (value.startsWith('data:')) {
    final comma = value.indexOf(',');
    if (comma == -1) return null;
    try {
      return MemoryImage(base64Decode(value.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return NetworkImage(value);
  }

  try {
    return MemoryImage(base64Decode(value));
  } catch (_) {
    return null;
  }
}
