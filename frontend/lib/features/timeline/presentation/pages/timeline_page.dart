import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../timingle/domain/entities/event.dart';
import '../../../timingle/presentation/providers/event_provider.dart';

/// Timeline 페이지 - 캘린더 형식으로 이벤트 표시
class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventsProvider.notifier).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Timeline',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: AppColors.grayDark),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 간단한 월 네비게이션
          _buildMonthHeader(),

          // 요일 헤더
          _buildWeekdayHeader(),

          // 캘린더 그리드
          _buildCalendarGrid(eventsState),

          const Divider(height: 1),

          // 선택된 날짜의 이벤트 목록
          Expanded(
            child: _buildEventList(eventsState),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(
                  _focusedDay.year,
                  _focusedDay.month - 1,
                );
              });
            },
          ),
          Text(
            DateFormat('yyyy년 M월', 'ko_KR').format(_focusedDay),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(
                  _focusedDay.year,
                  _focusedDay.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: weekdays.map((day) {
          final isWeekend = day == '일' || day == '토';
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isWeekend ? AppColors.errorRed : AppColors.grayMedium,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(EventsState eventsState) {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    // 이벤트가 있는 날짜 확인
    final eventDates = <int>{};
    for (final event in eventsState.events) {
      final eventDate = event.startTime.toLocal();
      if (eventDate.year == _focusedDay.year &&
          eventDate.month == _focusedDay.month) {
        eventDates.add(eventDate.day);
      }
    }

    final today = DateTime.now();
    final isCurrentMonth =
        today.year == _focusedDay.year && today.month == _focusedDay.month;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: 42, // 6 weeks
        itemBuilder: (context, index) {
          final dayOffset = index - firstWeekday;
          if (dayOffset < 0 || dayOffset >= daysInMonth) {
            return const SizedBox.shrink();
          }

          final day = dayOffset + 1;
          final date = DateTime(_focusedDay.year, _focusedDay.month, day);
          final isSelected = _isSameDay(date, _selectedDay);
          final isToday = isCurrentMonth && day == today.day;
          final hasEvent = eventDates.contains(day);
          final isWeekend = date.weekday == DateTime.sunday ||
              date.weekday == DateTime.saturday;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = date;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue
                    : isToday
                        ? AppColors.secondaryBlue.withValues(alpha: 0.3)
                        : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isToday || isSelected ? FontWeight.bold : null,
                      color: isSelected
                          ? AppColors.white
                          : isWeekend
                              ? AppColors.errorRed.withValues(alpha: 0.7)
                              : AppColors.black,
                    ),
                  ),
                  if (hasEvent)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.accentBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventList(EventsState eventsState) {
    if (eventsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    final dayEvents = eventsState.events.where((event) {
      final eventDate = event.startTime.toLocal();
      return _isSameDay(eventDate, _selectedDay);
    }).toList();

    // 시간순 정렬
    dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: AppColors.grayMedium.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '${_selectedDay.month}월 ${_selectedDay.day}일에는 약속이 없어요',
              style: const TextStyle(
                color: AppColors.grayDark,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return _buildTimelineItem(event);
      },
    );
  }

  Widget _buildTimelineItem(Event event) {
    final startTime = DateFormat('HH:mm').format(event.startTime.toLocal());
    final endTime = DateFormat('HH:mm').format(event.endTime.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.grayLight),
      ),
      child: InkWell(
        onTap: () => context.push('/events/${event.id}/chat'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 시간 표시
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startTime,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Text(
                      endTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grayMedium,
                      ),
                    ),
                  ],
                ),
              ),

              // 세로 구분선
              Container(
                width: 3,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _getStatusColor(event.status),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 이벤트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.location != null &&
                        event.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.grayMedium,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grayMedium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: AppColors.grayMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PROPOSED':
        return AppColors.warningYellow;
      case 'CONFIRMED':
        return AppColors.successGreen;
      case 'CANCELED':
        return AppColors.errorRed;
      case 'DONE':
        return AppColors.grayMedium;
      default:
        return AppColors.grayMedium;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
