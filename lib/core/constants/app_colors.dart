import 'package:flutter/material.dart';

/// PeerLearn Hub Color Palette
class AppColors {
  // Primary Colors
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color secondary = Color(0xFF22C55E);
  
  // Background & Surface
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  
  // Border
  static const Color border = Color(0xFFE2E8F0);
  
  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color pending = Color(0xFFF59E0B);
  static const Color error = Color(0xDC2626);
  
  // Status Semantic Colors
  static const Color approved = success;
  static const Color rejected = error;
  static const Color warning = pending;
  
  // Severity Colors
  static const Color severityLow = Color(0xFF3B82F6); // Blue
  static const Color severityMedium = pending;
  static const Color severityHigh = error;
}
