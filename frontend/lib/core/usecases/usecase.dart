import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// UseCase 기본 추상 클래스
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// 파라미터 없는 UseCase
abstract class UseCaseNoParams<T> {
  Future<Either<Failure, T>> call();
}

/// 파라미터 없음을 나타내는 클래스
class NoParams {
  const NoParams();
}
