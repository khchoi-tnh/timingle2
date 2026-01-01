import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../error/exceptions.dart';

/// WebSocket 연결 상태
enum WebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// WebSocket 클라이언트
class WebSocketClient {
  WebSocketChannel? _channel;
  String? _accessToken;
  int? _currentEventId;
  WebSocketState _state = WebSocketState.disconnected;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  // 스트림 컨트롤러
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _stateController = StreamController<WebSocketState>.broadcast();

  /// 메시지 스트림
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// 연결 상태 스트림
  Stream<WebSocketState> get stateStream => _stateController.stream;

  /// 현재 연결 상태
  WebSocketState get state => _state;

  /// 현재 연결된 이벤트 ID
  int? get currentEventId => _currentEventId;

  /// Access Token 설정
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// WebSocket 연결
  Future<void> connect(int eventId) async {
    if (_state == WebSocketState.connecting) {
      return;
    }

    if (_accessToken == null) {
      throw const WebSocketException(message: '인증 토큰이 없습니다');
    }

    _currentEventId = eventId;
    _setState(WebSocketState.connecting);

    try {
      final wsUrl = '${ApiConstants.wsEndpoint}?event_id=$eventId';
      final uri = Uri.parse(wsUrl);

      _channel = WebSocketChannel.connect(
        uri,
        protocols: ['chat'],
      );

      // 연결 성공 대기
      await _channel!.ready;

      _setState(WebSocketState.connected);
      _reconnectAttempts = 0;

      // 메시지 리스닝
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      _setState(WebSocketState.disconnected);
      throw WebSocketException(message: 'WebSocket 연결 실패: $e');
    }
  }

  /// 메시지 전송
  void sendMessage(String message, {String? replyTo}) {
    if (_state != WebSocketState.connected || _channel == null) {
      throw const WebSocketException(message: '연결되지 않았습니다');
    }

    final data = {
      'type': 'message',
      'message': message,
      if (replyTo != null) 'reply_to': replyTo,
    };

    _channel!.sink.add(jsonEncode(data));
  }

  /// 타이핑 인디케이터 전송
  void sendTyping() {
    if (_state != WebSocketState.connected || _channel == null) {
      return;
    }

    final data = {'type': 'typing'};
    _channel!.sink.add(jsonEncode(data));
  }

  /// 연결 해제
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _currentEventId = null;

    await _channel?.sink.close();
    _channel = null;

    _setState(WebSocketState.disconnected);
  }

  /// 메시지 수신 핸들러
  void _onMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message) as Map<String, dynamic>;
        _messageController.add(data);
      }
    } catch (e) {
      // JSON 파싱 실패 시 무시
    }
  }

  /// 에러 핸들러
  void _onError(dynamic error) {
    _setState(WebSocketState.disconnected);
    _tryReconnect();
  }

  /// 연결 종료 핸들러
  void _onDone() {
    if (_state != WebSocketState.disconnected) {
      _setState(WebSocketState.disconnected);
      _tryReconnect();
    }
  }

  /// 재연결 시도
  void _tryReconnect() {
    if (_reconnectAttempts >= AppConstants.wsMaxReconnectAttempts) {
      return;
    }

    if (_currentEventId == null) {
      return;
    }

    _reconnectAttempts++;
    _setState(WebSocketState.reconnecting);

    _reconnectTimer = Timer(
      Duration(milliseconds: AppConstants.wsReconnectDelay),
      () async {
        if (_currentEventId != null) {
          try {
            await connect(_currentEventId!);
          } catch (e) {
            _tryReconnect();
          }
        }
      },
    );
  }

  /// 상태 변경
  void _setState(WebSocketState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// 리소스 정리
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _stateController.close();
  }
}

/// WebSocketClient Provider
final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  final client = WebSocketClient();
  ref.onDispose(() => client.dispose());
  return client;
});
