import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEvent implements UseCase<Event, GetEventParams> {
  final EventRepository repository;

  GetEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(GetEventParams params) {
    return repository.getEvent(params.id);
  }
}

class GetEventParams {
  final int id;

  const GetEventParams({required this.id});
}
