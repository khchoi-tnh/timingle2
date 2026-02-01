import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/calendar_provider.dart';

/// Google Calendar 동기화 버튼 위젯
class CalendarSyncButton extends ConsumerWidget {
  final int eventId;
  final VoidCallback? onSyncComplete;

  const CalendarSyncButton({
    super.key,
    required this.eventId,
    this.onSyncComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);

    return ElevatedButton.icon(
      onPressed: calendarState.isSyncing
          ? null
          : () => _handleSync(context, ref),
      icon: calendarState.isSyncing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.calendar_today, size: 18),
      label: Text(calendarState.isSyncing ? '동기화 중...' : 'Google Calendar에 추가'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4285F4), // Google Blue
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    final calendarNotifier = ref.read(calendarProvider.notifier);
    final hasAccess = ref.read(hasCalendarAccessProvider);

    // Calendar 권한이 없는 경우 먼저 로그인
    if (!hasAccess) {
      final loggedIn = await calendarNotifier.loginWithCalendarPermission();
      if (!loggedIn) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calendar 권한이 필요합니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Calendar에 동기화
    final syncedEvent = await calendarNotifier.syncToCalendar(eventId);

    if (context.mounted) {
      if (syncedEvent != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google Calendar에 추가되었습니다'),
            backgroundColor: Colors.green,
            action: syncedEvent.htmlLink != null
                ? SnackBarAction(
                    label: '열기',
                    textColor: Colors.white,
                    onPressed: () {
                      final uri = Uri.parse(syncedEvent.htmlLink!);
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  )
                : null,
          ),
        );
        onSyncComplete?.call();
      } else {
        final errorMessage = ref.read(calendarProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? '동기화에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Calendar 연동 상태 위젯
class CalendarConnectionStatus extends ConsumerWidget {
  const CalendarConnectionStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);

    return Card(
      child: ListTile(
        leading: Icon(
          calendarState.hasCalendarAccess
              ? Icons.check_circle
              : Icons.cancel,
          color: calendarState.hasCalendarAccess
              ? Colors.green
              : Colors.grey,
        ),
        title: const Text('Google Calendar 연동'),
        subtitle: Text(
          calendarState.hasCalendarAccess
              ? '연동됨'
              : '연동되지 않음',
        ),
        trailing: calendarState.hasCalendarAccess
            ? null
            : TextButton(
                onPressed: calendarState.isLoading
                    ? null
                    : () => ref
                        .read(calendarProvider.notifier)
                        .loginWithCalendarPermission(),
                child: calendarState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('연동하기'),
              ),
      ),
    );
  }
}
