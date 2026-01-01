import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

/// 채팅 상태
class ChatState {
  final bool isLoading;
  final bool isConnecting;
  final bool isConnected;
  final List<ChatMessage> messages;
  final String? errorMessage;
  final int? currentEventId;

  const ChatState({
    this.isLoading = false,
    this.isConnecting = false,
    this.isConnected = false,
    this.messages = const [],
    this.errorMessage,
    this.currentEventId,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isConnecting,
    bool? isConnected,
    List<ChatMessage>? messages,
    String? errorMessage,
    int? currentEventId,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
      currentEventId: currentEventId ?? this.currentEventId,
    );
  }
}

/// ChatRemoteDataSource Provider
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRemoteDataSourceImpl(apiClient);
});

/// ChatRepository Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  final wsClient = ref.watch(webSocketClientProvider);
  return ChatRepositoryImpl(
    remoteDataSource: remoteDataSource,
    wsClient: wsClient,
  );
});

/// Chat StateNotifier
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final int? _currentUserId;
  StreamSubscription<ChatMessage>? _messageSubscription;

  ChatNotifier(this._repository, this._currentUserId) : super(const ChatState()) {
    _listenToMessages();
  }

  void _listenToMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = _repository.messageStream.listen((message) {
      // 새 메시지를 목록에 추가
      state = state.copyWith(
        messages: [...state.messages, message],
      );
    });
  }

  /// 채팅방 입장 (메시지 로드 + WebSocket 연결)
  Future<void> enterChat(int eventId) async {
    state = state.copyWith(
      isLoading: true,
      isConnecting: true,
      currentEventId: eventId,
      errorMessage: null,
    );

    // 1. 기존 메시지 로드
    final messagesResult = await _repository.getMessages(eventId);
    messagesResult.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (messages) {
        state = state.copyWith(
          isLoading: false,
          messages: messages.reversed.toList(), // 최신 메시지가 아래에 오도록
        );
      },
    );

    // 2. WebSocket 연결
    final connectResult = await _repository.connect(eventId);
    connectResult.fold(
      (failure) {
        state = state.copyWith(
          isConnecting: false,
          isConnected: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(
          isConnecting: false,
          isConnected: true,
        );
      },
    );
  }

  /// 채팅방 퇴장
  Future<void> leaveChat() async {
    await _repository.disconnect();
    state = const ChatState();
  }

  /// 메시지 전송
  Future<bool> sendMessage(String message, {String? replyTo}) async {
    if (message.trim().isEmpty) return false;

    final result = await _repository.sendMessage(
      message.trim(),
      replyTo: replyTo,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) => true,
    );
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 현재 사용자 ID
  int? get currentUserId => _currentUserId;

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}

/// Chat StateNotifier Provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return ChatNotifier(repository, currentUser?.id);
});
