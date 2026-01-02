import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class SendMessage implements UseCase<void, SendMessageParams> {
  final ChatRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, void>> call(SendMessageParams params) {
    return repository.sendMessage(
      params.message,
      replyTo: params.replyTo,
    );
  }
}

class SendMessageParams {
  final String message;
  final String? replyTo;

  const SendMessageParams({
    required this.message,
    this.replyTo,
  });
}
