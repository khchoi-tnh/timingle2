import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/calendar_event.dart';
import '../repositories/calendar_repository.dart';

/// Calendar 이벤트 조회 UseCase
class GetCalendarEvents
    implements UseCase<List<CalendarEvent>, GetCalendarEventsParams> {
  final CalendarRepository repository;

  GetCalendarEvents(this.repository);

  @override
  Future<Either<Failure, List<CalendarEvent>>> call(
      GetCalendarEventsParams params) {
    return repository.getCalendarEvents(
      startTime: params.startTime,
      endTime: params.endTime,
    );
  }
}

/// Calendar 이벤트 조회 파라미터
class GetCalendarEventsParams extends Equatable {
  final DateTime? startTime;
  final DateTime? endTime;

  const GetCalendarEventsParams({
    this.startTime,
    this.endTime,
  });

  @override
  List<Object?> get props => [startTime, endTime];
}
