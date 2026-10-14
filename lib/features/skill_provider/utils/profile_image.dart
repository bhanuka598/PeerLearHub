import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

ImageProvider? profileImageProvider(String? url) {
  final value = url?.trim();
  if (value == null || value.isEmpty) return null;

  if (value.startsWith('data:image/')) {
    final comma = value.indexOf(',');
    if (comma == -1) return null;
    try {
      return MemoryImage(base64Decode(value.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }

  if (value.startsWith('http')) {
    return NetworkImage(value);
  }
  return null;
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.size,
    this.imageUrl,
    this.initial = 'T',
    this.backgroundColor = AppTheme.iconBackground,
    this.foregroundColor = AppTheme.primaryColor,
  });

  final double size;
  final String? imageUrl;
  final String initial;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final image = profileImageProvider(imageUrl);
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: image != null
            ? Image(image: image, fit: BoxFit.cover)
            : ColoredBox(
                color: backgroundColor,
                child: Center(
                  child: Text(
                    initial.isNotEmpty ? initial[0].toUpperCase() : 'T',
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.38,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
