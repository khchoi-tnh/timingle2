import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_tokens.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogle implements UseCase<(User, AuthTokens), NoParams> {
  final AuthRepository repository;

  LoginWithGoogle(this.repository);

  @override
  Future<Either<Failure, (User, AuthTokens)>> call(NoParams params) {
    return repository.loginWithGoogle();
  }
}
