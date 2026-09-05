import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Bangladeshi Green Civic Theme
  static const Color primary = Color(0xFF006A4E); // Bangladeshi Emerald Green
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color primaryDark = Color(0xFF004D36);

  // Secondary & Accent
  static const Color secondary = Color(0xFF0288D1);
  static const Color accent = Color(0xFFFF9800); // Amber

  // Neutral Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Status Colors (Report Status)
  static const Color statusPending = Color(0xFFFF9800);     // Amber - অপেক্ষমাণ
  static const Color statusInProgress = Color(0xFF2196F3);  // Blue - চলমান
  static const Color statusResolved = Color(0xFF4CAF50);    // Green - সমাধানকৃত
  static const Color statusRejected = Color(0xFFF44336);    // Red - বাতিল

  // Status Badges Light Backgrounds
  static const Color statusPendingBg = Color(0xFFFFF3E0);
  static const Color statusInProgressBg = Color(0xFFE3F2FD);
  static const Color statusResolvedBg = Color(0xFFE8F5E9);
  static const Color statusRejectedBg = Color(0xFFFFEBEE);
}
