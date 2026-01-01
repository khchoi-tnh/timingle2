import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/chat_message.dart';

/// 채팅 Repository 인터페이스
abstract class ChatRepository {
  /// 채팅 메시지 목록 조회
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    int eventId, {
    int limit = 50,
  });

  /// WebSocket 연결
  Future<Either<Failure, void>> connect(int eventId);

  /// WebSocket 연결 해제
  Future<Either<Failure, void>> disconnect();

  /// 메시지 전송
  Future<Either<Failure, void>> sendMessage(String message, {String? replyTo});

  /// 실시간 메시지 스트림
  Stream<ChatMessage> get messageStream;
}
