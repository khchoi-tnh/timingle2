import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../timingle/domain/entities/event.dart';
import '../../../timingle/presentation/providers/event_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

/// 채팅 페이지
class ChatPage extends ConsumerStatefulWidget {
  final int eventId;

  const ChatPage({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 채팅방 입장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).enterChat(widget.eventId);
    });
  }

  @override
  void dispose() {
    // 채팅방 퇴장
    ref.read(chatProvider.notifier).leaveChat();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final wsState = ref.watch(webSocketClientProvider).state;

    // 새 메시지 도착 시 스크롤
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: eventAsync.when(
          data: (event) => _buildAppBarTitle(event),
          loading: () => const Text('로딩 중...'),
          error: (error, stackTrace) => const Text('이벤트'),
        ),
        actions: [
          // 연결 상태 인디케이터
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildConnectionIndicator(wsState),
          ),
        ],
      ),
      body: Column(
        children: [
          // 이벤트 정보 배너
          eventAsync.when(
            data: (event) => event != null
                ? _buildEventBanner(event)
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),

          // 메시지 목록
          Expanded(
            child: _buildMessageList(chatState),
          ),

          // 메시지 입력
          MessageInput(
            onSend: _handleSendMessage,
            enabled: chatState.isConnected,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(Event? event) {
    if (event == null) {
      return const Text('채팅');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${event.participants.length + 1}명 참여',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grayMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionIndicator(WebSocketState wsState) {
    IconData icon;
    Color color;
    String tooltip;

    switch (wsState) {
      case WebSocketState.connected:
        icon = Icons.wifi;
        color = AppColors.successGreen;
        tooltip = '연결됨';
        break;
      case WebSocketState.connecting:
      case WebSocketState.reconnecting:
        icon = Icons.sync;
        color = AppColors.warningYellow;
        tooltip = '연결 중...';
        break;
      case WebSocketState.disconnected:
        icon = Icons.wifi_off;
        color = AppColors.grayMedium;
        tooltip = '연결 끊김';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildEventBanner(Event event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.grayLight),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_outlined,
            size: 18,
            color: AppColors.grayMedium,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatEventTime(event),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grayDark,
              ),
            ),
          ),
          _buildStatusChip(event.status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'PROPOSED':
        backgroundColor = AppColors.warningYellow.withValues(alpha: 0.1);
        textColor = AppColors.warningYellow;
        label = '미확정';
        break;
      case 'CONFIRMED':
        backgroundColor = AppColors.successGreen.withValues(alpha: 0.1);
        textColor = AppColors.successGreen;
        label = '확정';
        break;
      default:
        backgroundColor = AppColors.grayLight;
        textColor = AppColors.grayDark;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatState state) {
    // 로딩 중
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlue,
        ),
      );
    }

    // 에러
    if (state.errorMessage != null && state.messages.isEmpty) {
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
              onPressed: () => ref
                  .read(chatProvider.notifier)
                  .enterChat(widget.eventId),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 빈 메시지
    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.grayMedium.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '아직 메시지가 없어요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.grayDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 메시지를 보내보세요!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grayMedium,
                  ),
            ),
          ],
        ),
      );
    }

    // 메시지 목록
    final currentUserId = ref.read(chatProvider.notifier).currentUserId;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final isMyMessage = currentUserId != null &&
            message.isMyMessage(currentUserId);

        // 이전 메시지와 발신자가 같은지 확인 (같으면 아바타 숨김)
        bool showSender = true;
        if (index > 0) {
          final prevMessage = state.messages[index - 1];
          if (prevMessage.senderId == message.senderId &&
              !prevMessage.isSystemMessage &&
              !message.isSystemMessage) {
            showSender = false;
          }
        }

        return MessageBubble(
          message: message,
          isMyMessage: isMyMessage,
          showSender: showSender,
        );
      },
    );
  }

  void _handleSendMessage(String message) async {
    final success = await ref.read(chatProvider.notifier).sendMessage(message);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메시지 전송에 실패했습니다'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  String _formatEventTime(Event event) {
    final start = event.startTime.toLocal();
    final end = event.endTime.toLocal();

    final dateStr = '${start.month}/${start.day}';
    final startTimeStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTimeStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    String result = '$dateStr $startTimeStr-$endTimeStr';
    if (event.location != null && event.location!.isNotEmpty) {
      result += ' @ ${event.location}';
    }

    return result;
  }
}
