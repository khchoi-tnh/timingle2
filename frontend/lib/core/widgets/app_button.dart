import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// 버튼 스타일 종류
enum AppButtonStyle {
  primary,
  secondary,
  outline,
  text,
}

/// 버튼 크기
enum AppButtonSize {
  small,
  medium,
  large,
}

/// timingle 스타일 버튼
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Widget? child;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.child,
  });

  /// Primary 버튼 생성자
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.child,
  }) : style = AppButtonStyle.primary;

  /// Secondary 버튼 생성자
  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.child,
  }) : style = AppButtonStyle.secondary;

  /// Outline 버튼 생성자
  const AppButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.child,
  }) : style = AppButtonStyle.outline;

  /// Text 버튼 생성자
  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.child,
  }) : style = AppButtonStyle.text;

  @override
  Widget build(BuildContext context) {
    final height = _getHeight();
    final fontSize = _getFontSize();
    final padding = _getPadding();

    Widget buttonChild = isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: _getLoadingColor(),
              strokeWidth: 2,
            ),
          )
        : child ??
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: fontSize + 4),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );

    final button = switch (style) {
      AppButtonStyle.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: buttonChild,
        ),
      AppButtonStyle.secondary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryBlue,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.secondaryBlue.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: buttonChild,
        ),
      AppButtonStyle.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            side: const BorderSide(color: AppColors.primaryBlue),
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        ),
      AppButtonStyle.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        ),
    };

    return button;
  }

  double _getHeight() {
    return switch (size) {
      AppButtonSize.small => 36,
      AppButtonSize.medium => 48,
      AppButtonSize.large => 56,
    };
  }

  double _getFontSize() {
    return switch (size) {
      AppButtonSize.small => 14,
      AppButtonSize.medium => 16,
      AppButtonSize.large => 18,
    };
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      AppButtonSize.small => const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      AppButtonSize.medium => const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      AppButtonSize.large => const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    };
  }

  Color _getLoadingColor() {
    return switch (style) {
      AppButtonStyle.primary || AppButtonStyle.secondary => AppColors.white,
      AppButtonStyle.outline || AppButtonStyle.text => AppColors.primaryBlue,
    };
  }
}
