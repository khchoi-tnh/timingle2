import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/websocket_client.dart';
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
  }) async {
    try {
      final messages = await _remoteDataSource.getMessages(
        eventId,
        limit: limit,
      );
      return Right(messages);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> connect(int eventId) async {
    try {
      await _wsClient.connect(eventId);
      _listenToWebSocket();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await _wsClient.disconnect();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage(
    String message, {
    String? replyTo,
  }) async {
    try {
      _wsClient.sendMessage(message, replyTo: replyTo);
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;

  /// 리소스 정리
  void dispose() {
    _wsSubscription?.cancel();
    _messageStreamController.close();
  }
}
