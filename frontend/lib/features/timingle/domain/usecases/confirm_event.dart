import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class ConfirmEvent implements UseCase<Event, ConfirmEventParams> {
  final EventRepository repository;

  ConfirmEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(ConfirmEventParams params) {
    return repository.confirmEvent(params.eventId);
  }
}

class ConfirmEventParams {
  final int eventId;

  const ConfirmEventParams({required this.eventId});
}
