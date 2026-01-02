import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class GetMessages implements UseCase<List<ChatMessage>, GetMessagesParams> {
  final ChatRepository repository;

  GetMessages(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(GetMessagesParams params) {
    return repository.getMessages(
      params.eventId,
      limit: params.limit,
    );
  }
}

class GetMessagesParams {
  final int eventId;
  final int limit;

  const GetMessagesParams({
    required this.eventId,
    this.limit = 50,
  });
}
