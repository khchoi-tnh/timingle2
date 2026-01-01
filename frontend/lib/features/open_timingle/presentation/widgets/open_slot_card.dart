import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/open_slot.dart';

/// 오픈 슬롯 카드 위젯
class OpenSlotCard extends StatelessWidget {
  final OpenSlot slot;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  const OpenSlotCard({
    super.key,
    required this.slot,
    this.onTap,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.grayLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 호스트 정보 + 카테고리
              Row(
                children: [
                  // 프로필 아바타
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      slot.hostName.isNotEmpty ? slot.hostName[0] : '?',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 호스트 이름
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.hostName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.black,
                          ),
                        ),
                        if (slot.category != null)
                          Text(
                            slot.category!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grayMedium,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 가격
                  if (slot.price != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '₩${NumberFormat('#,###').format(slot.price!.toInt())}',
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // 제목
              Text(
                slot.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (slot.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  slot.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grayDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // 날짜/시간 + 위치
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.grayMedium,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(slot.startTime, slot.endTime),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grayDark,
                    ),
                  ),
                ],
              ),

              if (slot.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.grayMedium,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        slot.location!,
                        style: const TextStyle(
                          fontSize: 13,
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

              // 하단: 남은 자리 + 예약 버튼
              Row(
                children: [
                  // 남은 자리
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: slot.canBook
                          ? AppColors.successGreen.withValues(alpha: 0.1)
                          : AppColors.grayLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: slot.canBook
                              ? AppColors.successGreen
                              : AppColors.grayMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          slot.canBook
                              ? '${slot.remainingSlots}자리 남음'
                              : '마감',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: slot.canBook
                                ? AppColors.successGreen
                                : AppColors.grayMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 예약 버튼
                  ElevatedButton(
                    onPressed: slot.canBook ? onBook : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.grayLight,
                      disabledForegroundColor: AppColors.grayMedium,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      slot.canBook ? '예약하기' : '마감',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              // 태그
              if (slot.tags != null && slot.tags!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: slot.tags!
                      .take(3)
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grayLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.grayDark,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime start, DateTime end) {
    final dateFormat = DateFormat('M/d (E)', 'ko_KR');
    final timeFormat = DateFormat('HH:mm');

    return '${dateFormat.format(start)} ${timeFormat.format(start)} - ${timeFormat.format(end)}';
  }
}
