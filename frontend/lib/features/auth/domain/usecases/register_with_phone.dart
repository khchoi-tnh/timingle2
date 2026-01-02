import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_tokens.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterWithPhone implements UseCase<(User, AuthTokens), RegisterWithPhoneParams> {
  final AuthRepository repository;

  RegisterWithPhone(this.repository);

  @override
  Future<Either<Failure, (User, AuthTokens)>> call(RegisterWithPhoneParams params) {
    return repository.registerWithPhone(
      phone: params.phone,
      name: params.name,
    );
  }
}

class RegisterWithPhoneParams {
  final String phone;
  final String name;

  const RegisterWithPhoneParams({
    required this.phone,
    required this.name,
  });
}
