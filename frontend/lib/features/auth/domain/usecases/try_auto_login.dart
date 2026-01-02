import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class TryAutoLogin implements UseCaseNoParams<User> {
  final AuthRepository repository;

  TryAutoLogin(this.repository);

  @override
  Future<Either<Failure, User>> call() {
    return repository.tryAutoLogin();
  }
}
