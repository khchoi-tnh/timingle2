import 'package:flutter/material.dart';
import 'ff_colors.dart';

class FFGradients {
  // Primary Gradient
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0066CC), Color(0xFF0052A3)],
    stops: [0.0, 1.0],
  );

  // Primary Light Gradient
  static const LinearGradient primaryLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B9EFF), Color(0xFF0066CC)],
    stops: [0.0, 1.0],
  );

  // Secondary Gradient
  static const LinearGradient secondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B4A0), Color(0xFF008B78)],
    stops: [0.0, 1.0],
  );

  // Background Subtle Gradient
  static const LinearGradient backgroundSubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAFAFC), Color(0xFFF8F9FB)],
    stops: [0.0, 1.0],
  );

  // Card Background Gradient
  static const LinearGradient cardBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFC)],
    stops: [0.0, 1.0],
  );

  // Success Gradient
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    stops: [0.0, 1.0],
  );

  // Error Gradient
  static const LinearGradient error = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    stops: [0.0, 1.0],
  );

  // Overlay Gradient (for bottom sheets)
  static const LinearGradient overlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x80000000)],
    stops: [0.0, 1.0],
  );
}
