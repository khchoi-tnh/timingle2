import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';

/// EventRepository 구현
class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource _remoteDataSource;

  EventRepositoryImpl({required EventRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<Event>>> getEvents({
    String? status,
    int page = 1,
    int limit = 20,
  }) {
    return RepositoryHelper.execute(
      () => _remoteDataSource.getEvents(
        status: status,
        page: page,
        limit: limit,
      ),
    );
  }

  @override
  Future<Either<Failure, Event>> getEvent(int id) {
    return RepositoryHelper.execute(
      () => _remoteDataSource.getEvent(id),
      on404: const NotFoundFailure(message: '이벤트를 찾을 수 없습니다'),
    );
  }

  @override
  Future<Either<Failure, Event>> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<int>? participantIds,
  }) {
    return RepositoryHelper.execute(
      () => _remoteDataSource.createEvent(
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        participantIds: participantIds,
      ),
    );
  }

  @override
  Future<Either<Failure, Event>> updateEvent(
    int id,
    Map<String, dynamic> data,
  ) {
    return RepositoryHelper.execute(
      () => _remoteDataSource.updateEvent(id, data),
    );
  }

  @override
  Future<Either<Failure, Event>> confirmEvent(int id) {
    return RepositoryHelper.execute(
      () => _remoteDataSource.confirmEvent(id),
    );
  }

  @override
  Future<Either<Failure, void>> cancelEvent(int id) {
    return RepositoryHelper.executeVoid(
      () => _remoteDataSource.cancelEvent(id),
    );
  }
}
