import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// timingle 스타일 카드
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final double? elevation;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.margin,
    this.padding,
    this.borderRadius = 12,
    this.borderColor,
    this.elevation,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: elevation ?? 0,
      color: backgroundColor ?? AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: borderColor ?? AppColors.grayLight),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// 로딩 상태의 카드
class LoadingCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final double height;

  const LoadingCard({
    super.key,
    this.margin,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin,
      child: SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

/// 에러 상태의 카드
class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? margin;

  const ErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin,
      borderColor: AppColors.errorRed.withValues(alpha: 0.3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.errorRed,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grayDark,
              fontSize: 14,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
            ),
          ],
        ],
      ),
    );
  }
}

/// 빈 상태 카드
class EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final EdgeInsetsGeometry? margin;

  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin,
      borderColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.grayMedium,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grayDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grayMedium,
                fontSize: 14,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}
