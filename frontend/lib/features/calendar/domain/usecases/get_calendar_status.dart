import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/calendar_event.dart';
import '../repositories/calendar_repository.dart';

/// Calendar 연동 상태 확인 UseCase
class GetCalendarStatus implements UseCase<CalendarStatus, NoParams> {
  final CalendarRepository repository;

  GetCalendarStatus(this.repository);

  @override
  Future<Either<Failure, CalendarStatus>> call(NoParams params) {
    return repository.getCalendarStatus();
  }
}
