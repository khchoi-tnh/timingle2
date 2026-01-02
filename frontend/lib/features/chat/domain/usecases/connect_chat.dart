import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class ConnectChat implements UseCase<void, ConnectChatParams> {
  final ChatRepository repository;

  ConnectChat(this.repository);

  @override
  Future<Either<Failure, void>> call(ConnectChatParams params) {
    return repository.connect(params.eventId);
  }
}

class ConnectChatParams {
  final int eventId;

  const ConnectChatParams({required this.eventId});
}
