import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class UpdateEvent implements UseCase<Event, UpdateEventParams> {
  final EventRepository repository;

  UpdateEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(UpdateEventParams params) {
    return repository.updateEvent(params.id, params.data);
  }
}

class UpdateEventParams {
  final int id;
  final Map<String, dynamic> data;

  const UpdateEventParams({
    required this.id,
    required this.data,
  });
}
