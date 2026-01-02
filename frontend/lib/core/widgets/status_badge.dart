import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// 이벤트 상태 뱃지
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  /// 상태값으로 생성
  factory StatusBadge.fromStatus(String status, {bool compact = false}) {
    return StatusBadge(status: status, compact: compact);
  }

  /// 제안됨 상태 뱃지
  const StatusBadge.proposed({super.key, this.compact = false})
      : status = AppConstants.statusProposed;

  /// 확정됨 상태 뱃지
  const StatusBadge.confirmed({super.key, this.compact = false})
      : status = AppConstants.statusConfirmed;

  /// 취소됨 상태 뱃지
  const StatusBadge.canceled({super.key, this.compact = false})
      : status = AppConstants.statusCanceled;

  /// 완료됨 상태 뱃지
  const StatusBadge.done({super.key, this.compact = false})
      : status = AppConstants.statusDone;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor, label) = _getStatusStyle();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color, String) _getStatusStyle() {
    return switch (status) {
      AppConstants.statusProposed => (
          AppColors.statusProposed.withValues(alpha: 0.1),
          AppColors.statusProposed,
          '미확정',
        ),
      AppConstants.statusConfirmed => (
          AppColors.statusConfirmed.withValues(alpha: 0.1),
          AppColors.statusConfirmed,
          '확정',
        ),
      AppConstants.statusCanceled => (
          AppColors.statusCanceled.withValues(alpha: 0.1),
          AppColors.statusCanceled,
          '취소됨',
        ),
      AppConstants.statusDone => (
          AppColors.statusDone.withValues(alpha: 0.1),
          AppColors.statusDone,
          '완료',
        ),
      _ => (
          AppColors.grayLight,
          AppColors.grayDark,
          status,
        ),
    };
  }
}

/// 읽지 않은 메시지 뱃지
class UnreadBadge extends StatelessWidget {
  final int count;
  final bool showIcon;

  const UnreadBadge({
    super.key,
    required this.count,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            const Icon(
              Icons.chat_bubble,
              size: 12,
              color: AppColors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 커스텀 뱃지 (색상 지정 가능)
class CustomBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final bool compact;

  const CustomBadge({
    super.key,
    required this.text,
    this.backgroundColor = AppColors.primaryBlue,
    this.textColor = AppColors.white,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 10 : 12,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
