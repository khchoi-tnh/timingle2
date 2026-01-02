import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEvents implements UseCase<List<Event>, GetEventsParams> {
  final EventRepository repository;

  GetEvents(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(GetEventsParams params) {
    return repository.getEvents(
      status: params.status,
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetEventsParams {
  final String? status;
  final int page;
  final int limit;

  const GetEventsParams({
    this.status,
    this.page = 1,
    this.limit = 20,
  });
}
