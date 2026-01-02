import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class DisconnectChat implements UseCaseNoParams<void> {
  final ChatRepository repository;

  DisconnectChat(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.disconnect();
  }
}
