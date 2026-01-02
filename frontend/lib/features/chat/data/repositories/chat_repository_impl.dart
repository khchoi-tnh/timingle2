import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/chat_message_model.dart';

/// ChatRepository 구현
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final WebSocketClient _wsClient;
  final StreamController<ChatMessage> _messageStreamController =
      StreamController<ChatMessage>.broadcast();

  StreamSubscription? _wsSubscription;

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    required WebSocketClient wsClient,
  })  : _remoteDataSource = remoteDataSource,
        _wsClient = wsClient {
    _listenToWebSocket();
  }

  void _listenToWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = _wsClient.messageStream.listen((data) {
      try {
        final message = ChatMessageModel.fromJson(data);
        _messageStreamController.add(message);
      } catch (e) {
        // JSON 파싱 실패 시 무시
      }
    });
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    int eventId, {
    int limit = 50,
  }) {
    return RepositoryHelper.execute(
      () => _remoteDataSource.getMessages(eventId, limit: limit),
    );
  }

  @override
  Future<Either<Failure, void>> connect(int eventId) async {
    try {
      await _wsClient.connect(eventId);
      _listenToWebSocket();
      return const Right(null);
    } catch (e) {
      return Left(WebSocketFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() {
    return RepositoryHelper.executeVoid(
      () => _wsClient.disconnect(),
    );
  }

  @override
  Future<Either<Failure, void>> sendMessage(
    String message, {
    String? replyTo,
  }) async {
    final result = RepositoryHelper.executeSync(
      () => _wsClient.sendMessage(message, replyTo: replyTo),
    );
    return Future.value(result);
  }

  @override
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;

  /// 리소스 정리
  void dispose() {
    _wsSubscription?.cancel();
    _messageStreamController.close();
  }
}
