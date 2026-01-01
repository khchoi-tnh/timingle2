import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/friend.dart';

/// 친구 타일 위젯
class FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onTap;
  final VoidCallback? onCreateEvent;
  final VoidCallback? onMore;

  const FriendTile({
    super.key,
    required this.friend,
    this.onTap,
    this.onCreateEvent,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primaryBlue,
        child: Text(
          friend.name.isNotEmpty ? friend.name[0] : '?',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        friend.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: AppColors.black,
        ),
      ),
      subtitle: Row(
        children: [
          if (friend.lastEventDate != null) ...[
            const Icon(
              Icons.event_outlined,
              size: 12,
              color: AppColors.grayMedium,
            ),
            const SizedBox(width: 4),
            Text(
              '마지막 약속: ${_formatRelativeDate(friend.lastEventDate!)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grayMedium,
              ),
            ),
          ] else ...[
            Text(
              '${friend.eventCount}개의 약속',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grayMedium,
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 약속 만들기 버튼
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primaryBlue,
            ),
            onPressed: onCreateEvent,
            tooltip: '약속 만들기',
          ),
          // 더보기 메뉴
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.grayMedium,
            ),
            onPressed: onMore,
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else {
      return DateFormat('M월 d일').format(date);
    }
  }
}

/// 친구 요청 타일 위젯
class FriendRequestTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const FriendRequestTile({
    super.key,
    required this.friend,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.secondaryBlue,
            child: Text(
              friend.name.isNotEmpty ? friend.name[0] : '?',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  friend.phone ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grayMedium,
                  ),
                ),
              ],
            ),
          ),
          // 거절 버튼
          TextButton(
            onPressed: onReject,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.grayDark,
            ),
            child: const Text('거절'),
          ),
          const SizedBox(width: 4),
          // 수락 버튼
          ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('수락'),
          ),
        ],
      ),
    );
  }
}
