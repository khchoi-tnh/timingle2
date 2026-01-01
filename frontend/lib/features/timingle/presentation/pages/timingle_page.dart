import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../providers/event_provider.dart';
import '../widgets/event_card.dart';

/// Timingle (이벤트 목록) 페이지
class TiminglePage extends ConsumerStatefulWidget {
  const TiminglePage({super.key});

  @override
  ConsumerState<TiminglePage> createState() => _TiminglePageState();
}

class _TiminglePageState extends ConsumerState<TiminglePage> {
  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 이벤트 목록 조회
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventsProvider.notifier).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final eventsState = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.schedule,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'timingle',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // 알림 버튼
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.grayDark,
            ),
            onPressed: () {
              // TODO: 알림 페이지로 이동
            },
          ),
          // 프로필 버튼
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                // Settings 탭으로 이동 (index 4)
                ref.read(currentTabProvider.notifier).state = 4;
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0] : '?',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(eventsProvider.notifier).refreshEvents(),
        child: _buildBody(eventsState),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentBlue,
        onPressed: _showCreateEventDialog,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildBody(EventsState state) {
    // 로딩 중 (첫 로드)
    if (state.isLoading && state.events.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlue,
        ),
      );
    }

    // 에러
    if (state.errorMessage != null && state.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.grayMedium,
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.grayDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(eventsProvider.notifier).loadEvents(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 빈 목록
    if (state.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: AppColors.grayMedium.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '아직 약속이 없어요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.grayDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 약속을 만들어보세요!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grayMedium,
                  ),
            ),
          ],
        ),
      );
    }

    // 이벤트 목록
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.events.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // 로딩 인디케이터 (무한 스크롤)
        if (index >= state.events.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            ),
          );
        }

        final event = state.events[index];
        return EventCard(
          event: event,
          onTap: () {
            // TODO: 이벤트 상세/채팅 페이지로 이동
            _showEventDetail(event.id);
          },
        );
      },
    );
  }

  void _showCreateEventDialog() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay startTime = TimeOfDay.fromDateTime(selectedDate);
    TimeOfDay endTime = TimeOfDay.fromDateTime(
      selectedDate.add(const Duration(hours: 1)),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '새 약속 만들기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 제목 입력
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '약속 제목',
                  hintText: '예: 점심 식사',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 장소 입력
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: '장소 (선택)',
                  hintText: '예: 강남역 1번 출구',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 날짜 선택
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setModalState(() {
                      selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        startTime.hour,
                        startTime.minute,
                      );
                    });
                  }
                },
              ),

              // 시간 선택
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: Text('${startTime.format(context)} 시작'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (time != null) {
                          setModalState(() => startTime = time);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${endTime.format(context)} 종료'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (time != null) {
                          setModalState(() => endTime = time);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 생성 버튼
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('제목을 입력해주세요')),
                    );
                    return;
                  }

                  final startDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    startTime.hour,
                    startTime.minute,
                  );

                  final endDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    endTime.hour,
                    endTime.minute,
                  );

                  Navigator.pop(context);

                  final event =
                      await ref.read(eventsProvider.notifier).createEvent(
                            title: titleController.text,
                            startTime: startDateTime,
                            endTime: endDateTime,
                            location: locationController.text.isNotEmpty
                                ? locationController.text
                                : null,
                          );

                  if (event != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('약속이 생성되었습니다')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '약속 만들기',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetail(int eventId) {
    // 채팅 페이지로 이동
    context.push('/events/$eventId/chat');
  }
}
