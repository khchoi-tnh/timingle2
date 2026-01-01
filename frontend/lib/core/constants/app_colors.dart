import 'package:flutter/material.dart';

/// timingle 브랜드 색상
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryBlue = Color(0xFF2E4A8F);
  static const Color secondaryBlue = Color(0xFF5EC4E8);
  static const Color accentBlue = Color(0xFF3B82F6);

  // Status Colors
  static const Color purple = Color(0xFF8B5CF6);
  static const Color warningYellow = Color(0xFFFBBF24);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);

  // Neutral Colors
  static const Color grayLight = Color(0xFFE5E7EB);
  static const Color grayMedium = Color(0xFF9CA3AF);
  static const Color grayDark = Color(0xFF374151);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111827);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  // Event Status Colors
  static const Color statusProposed = warningYellow;
  static const Color statusConfirmed = successGreen;
  static const Color statusCanceled = errorRed;
  static const Color statusDone = grayMedium;

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
