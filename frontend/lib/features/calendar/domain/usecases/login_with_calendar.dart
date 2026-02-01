import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/calendar_repository.dart';

/// Calendar 권한 포함 Google 로그인 UseCase
class LoginWithCalendar implements UseCase<void, NoParams> {
  final CalendarRepository repository;

  LoginWithCalendar(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.loginWithCalendarPermission();
  }
}
