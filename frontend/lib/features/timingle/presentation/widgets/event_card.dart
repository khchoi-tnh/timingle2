import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/event.dart';

/// 이벤트 카드 위젯
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 상태 뱃지 & 시간
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: event.status),
              Text(
                _formatTimeAgo(event.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grayMedium,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 제목
          Text(
            event.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // 날짜/시간
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 16,
                color: AppColors.grayMedium,
              ),
              const SizedBox(width: 6),
              Text(
                _formatEventTime(event.startTime, event.endTime),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grayDark,
                    ),
              ),
            ],
          ),

          // 장소 (있는 경우)
          if (event.location != null && event.location!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.grayMedium,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.location!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grayDark,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // 하단: 참여자 & 읽지 않은 메시지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 참여자 아바타 스택
              AvatarStack(
                avatars: event.participants
                    .map((p) => AvatarData(
                          name: p.name,
                          imageUrl: p.profileImageUrl,
                        ))
                    .toList(),
              ),

              // 읽지 않은 메시지 뱃지
              if (event.hasUnreadMessages)
                UnreadBadge(count: event.unreadMessages ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  String _formatEventTime(DateTime start, DateTime end) {
    final dateFormat = DateFormat('M월 d일 (E)', 'ko_KR');
    final timeFormat = DateFormat('HH:mm');

    final date = dateFormat.format(start.toLocal());
    final startTime = timeFormat.format(start.toLocal());
    final endTime = timeFormat.format(end.toLocal());

    return '$date $startTime - $endTime';
  }

  String _formatTimeAgo(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'ko');
  }
}
