import 'package:flutter/material.dart';
import 'tokens/ff_colors.dart';
import 'tokens/ff_typography.dart';
import 'tokens/ff_radius.dart';
import 'tokens/ff_gradients.dart';

class FFTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      primaryColor: FFColors.primary,
      scaffoldBackgroundColor: FFColors.background,
      colorScheme: ColorScheme.light(
        primary: FFColors.primary,
        secondary: FFColors.secondary,
        tertiary: FFColors.secondary,
        surface: FFColors.backgroundLight,
        background: FFColors.background,
        error: FFColors.error,
        onPrimary: FFColors.textInverse,
        onSecondary: FFColors.textInverse,
        onSurface: FFColors.textPrimary,
        onBackground: FFColors.textPrimary,
        onError: FFColors.textInverse,
      ),
      textTheme: TextTheme(
        displayLarge: FFTypography.display1.copyWith(color: FFColors.textPrimary),
        displayMedium: FFTypography.display2.copyWith(color: FFColors.textPrimary),
        displaySmall: FFTypography.display3.copyWith(color: FFColors.textPrimary),
        headlineLarge: FFTypography.heading1.copyWith(color: FFColors.textPrimary),
        headlineMedium: FFTypography.heading2.copyWith(color: FFColors.textPrimary),
        headlineSmall: FFTypography.heading3.copyWith(color: FFColors.textPrimary),
        titleLarge: FFTypography.subheading1.copyWith(color: FFColors.textPrimary),
        titleMedium: FFTypography.subheading2.copyWith(color: FFColors.textSecondary),
        bodyLarge: FFTypography.bodyLg.copyWith(color: FFColors.textPrimary),
        bodyMedium: FFTypography.body.copyWith(color: FFColors.textSecondary),
        bodySmall: FFTypography.bodySm.copyWith(color: FFColors.textTertiary),
        labelLarge: FFTypography.labelLg.copyWith(color: FFColors.textPrimary),
        labelMedium: FFTypography.label.copyWith(color: FFColors.textSecondary),
        labelSmall: FFTypography.labelSm.copyWith(color: FFColors.textTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FFColors.primary,
          foregroundColor: FFColors.textInverse,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FFRadius.lg)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FFColors.primary,
          side: BorderSide(color: FFColors.border, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FFRadius.lg)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FFColors.primary,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FFColors.backgroundDark,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FFRadius.lg),
          borderSide: BorderSide(color: FFColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FFRadius.lg),
          borderSide: BorderSide(color: FFColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FFRadius.lg),
          borderSide: BorderSide(color: FFColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FFRadius.lg),
          borderSide: BorderSide(color: FFColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FFRadius.lg),
          borderSide: BorderSide(color: FFColors.error, width: 2),
        ),
        labelStyle: FFTypography.body.copyWith(color: FFColors.textSecondary),
        hintStyle: FFTypography.body.copyWith(color: FFColors.placeholder),
        errorStyle: FFTypography.bodySm.copyWith(color: FFColors.error),
      ),
      cardTheme: CardThemeData(
        color: FFColors.backgroundLight,
        shadowColor: FFColors.shadow,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FFRadius.lg)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: FFColors.border,
        thickness: 1,
        space: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: FFColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: FFTypography.heading3.copyWith(color: FFColors.textPrimary),
        iconTheme: IconThemeData(color: FFColors.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
