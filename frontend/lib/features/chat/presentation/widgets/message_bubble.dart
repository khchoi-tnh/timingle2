import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/chat_message.dart';

/// 메시지 버블 위젯
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMyMessage;
  final bool showSender;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    this.showSender = true,
  });

  @override
  Widget build(BuildContext context) {
    // 시스템 메시지
    if (message.isSystemMessage) {
      return _buildSystemMessage(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 내 메시지가 아닐 때 아바타
          if (!isMyMessage && showSender) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryBlue,
              backgroundImage: message.senderProfileUrl != null
                  ? NetworkImage(message.senderProfileUrl!)
                  : null,
              child: message.senderProfileUrl == null
                  ? Text(
                      message.senderName.isNotEmpty
                          ? message.senderName[0]
                          : '?',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMyMessage) ...[
            const SizedBox(width: 40), // 아바타 공간 유지
          ],

          // 메시지 내용
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 발신자 이름 (내 메시지가 아닐 때)
                if (!isMyMessage && showSender)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grayMedium,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),

                // 메시지 버블
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? AppColors.primaryBlue
                        : AppColors.grayLight,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                      bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: isMyMessage ? AppColors.white : AppColors.black,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),

                // 시간
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grayMedium,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // 내 메시지일 때 오른쪽 여백
          if (isMyMessage) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.grayLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grayDark,
                fontStyle: FontStyle.italic,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();

    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      // 오늘: 시간만 표시
      return DateFormat('HH:mm').format(local);
    } else if (local.year == now.year) {
      // 올해: 날짜 + 시간
      return DateFormat('M/d HH:mm').format(local);
    } else {
      // 작년 이전: 연도 포함
      return DateFormat('yy/M/d HH:mm').format(local);
    }
  }
}
