import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class CreateEvent implements UseCase<Event, CreateEventParams> {
  final EventRepository repository;

  CreateEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(CreateEventParams params) {
    return repository.createEvent(
      title: params.title,
      description: params.description,
      startTime: params.startTime,
      endTime: params.endTime,
      location: params.location,
      participantIds: params.participantIds,
    );
  }
}

class CreateEventParams {
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final List<int>? participantIds;

  const CreateEventParams({
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.participantIds,
  });
}
