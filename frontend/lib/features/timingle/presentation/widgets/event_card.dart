import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.grayLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 상태 뱃지 & 시간
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(),
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
                  _buildParticipantsStack(context),

                  // 읽지 않은 메시지 뱃지
                  if (event.hasUnreadMessages)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chat_bubble,
                            size: 12,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.unreadMessages}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (event.status) {
      case AppConstants.statusProposed:
        backgroundColor = AppColors.statusProposed.withValues(alpha: 0.1);
        textColor = AppColors.statusProposed;
        label = '미확정';
        break;
      case AppConstants.statusConfirmed:
        backgroundColor = AppColors.statusConfirmed.withValues(alpha: 0.1);
        textColor = AppColors.statusConfirmed;
        label = '확정';
        break;
      case AppConstants.statusCanceled:
        backgroundColor = AppColors.statusCanceled.withValues(alpha: 0.1);
        textColor = AppColors.statusCanceled;
        label = '취소됨';
        break;
      case AppConstants.statusDone:
        backgroundColor = AppColors.statusDone.withValues(alpha: 0.1);
        textColor = AppColors.statusDone;
        label = '완료';
        break;
      default:
        backgroundColor = AppColors.grayLight;
        textColor = AppColors.grayDark;
        label = event.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildParticipantsStack(BuildContext context) {
    final participants = event.participants;
    final displayCount = participants.length > 3 ? 3 : participants.length;
    final remainingCount = participants.length - displayCount;

    if (participants.isEmpty) {
      return const Text(
        '참여자 없음',
        style: TextStyle(
          color: AppColors.grayMedium,
          fontSize: 12,
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 24.0 * displayCount + (remainingCount > 0 ? 24 : 0),
          height: 28,
          child: Stack(
            children: [
              ...List.generate(displayCount, (index) {
                final participant = participants[index];
                return Positioned(
                  left: index * 18.0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryBlue,
                    backgroundImage: participant.profileImageUrl != null
                        ? NetworkImage(participant.profileImageUrl!)
                        : null,
                    child: participant.profileImageUrl == null
                        ? Text(
                            participant.name.isNotEmpty
                                ? participant.name[0]
                                : '?',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                );
              }),
              if (remainingCount > 0)
                Positioned(
                  left: displayCount * 18.0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.grayLight,
                    child: Text(
                      '+$remainingCount',
                      style: const TextStyle(
                        color: AppColors.grayDark,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${participants.length}명',
          style: const TextStyle(
            color: AppColors.grayMedium,
            fontSize: 12,
          ),
        ),
      ],
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
