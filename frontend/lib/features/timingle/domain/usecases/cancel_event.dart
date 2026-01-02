import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/event_repository.dart';

class CancelEvent implements UseCase<void, CancelEventParams> {
  final EventRepository repository;

  CancelEvent(this.repository);

  @override
  Future<Either<Failure, void>> call(CancelEventParams params) {
    return repository.cancelEvent(params.eventId);
  }
}

class CancelEventParams {
  final int eventId;

  const CancelEventParams({required this.eventId});
}
