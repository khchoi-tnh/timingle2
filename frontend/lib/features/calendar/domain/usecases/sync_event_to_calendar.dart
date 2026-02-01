import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/calendar_event.dart';
import '../repositories/calendar_repository.dart';

/// timingle 이벤트를 Google Calendar에 동기화하는 UseCase
class SyncEventToCalendar
    implements UseCase<SyncedCalendarEvent, SyncEventToCalendarParams> {
  final CalendarRepository repository;

  SyncEventToCalendar(this.repository);

  @override
  Future<Either<Failure, SyncedCalendarEvent>> call(
      SyncEventToCalendarParams params) {
    return repository.syncEventToCalendar(params.eventId);
  }
}

/// 동기화 파라미터
class SyncEventToCalendarParams extends Equatable {
  final int eventId;

  const SyncEventToCalendarParams({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}
