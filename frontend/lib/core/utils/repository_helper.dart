import 'package:dartz/dartz.dart';

import '../error/exceptions.dart';
import '../error/failures.dart';

/// Repository 에러 핸들링 헬퍼
///
/// Exception을 Failure로 변환하는 공통 로직을 제공합니다.
/// 모든 Repository에서 일관된 에러 처리를 보장합니다.
class RepositoryHelper {
  /// 비동기 작업을 실행하고 Exception을 Failure로 변환합니다.
  ///
  /// [action]: 실행할 비동기 작업
  /// [on404]: 404 에러 시 사용할 커스텀 실패 (선택)
  ///
  /// 예시:
  /// ```dart
  /// return RepositoryHelper.execute(
  ///   () => _remoteDataSource.getEvent(id),
  ///   on404: NotFoundFailure(message: '이벤트를 찾을 수 없습니다'),
  /// );
  /// ```
  static Future<Either<Failure, T>> execute<T>(
    Future<T> Function() action, {
    Failure? on404,
  }) async {
    try {
      final result = await action();
      return Right(result);
    } on ServerException catch (e) {
      if (e.statusCode == 404 && on404 != null) {
        return Left(on404);
      }
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// void를 반환하는 비동기 작업을 실행합니다.
  ///
  /// [action]: 실행할 비동기 작업
  ///
  /// 예시:
  /// ```dart
  /// return RepositoryHelper.executeVoid(
  ///   () => _remoteDataSource.cancelEvent(id),
  /// );
  /// ```
  static Future<Either<Failure, void>> executeVoid(
    Future<void> Function() action,
  ) async {
    try {
      await action();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// 동기 작업을 실행하고 Exception을 Failure로 변환합니다.
  ///
  /// WebSocket 메시지 전송 등 동기 작업에 사용됩니다.
  ///
  /// 예시:
  /// ```dart
  /// return RepositoryHelper.executeSync(
  ///   () => _wsClient.sendMessage(message),
  /// );
  /// ```
  static Either<Failure, void> executeSync(
    void Function() action,
  ) {
    try {
      action();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// 커스텀 에러 처리를 포함한 비동기 작업을 실행합니다.
  ///
  /// [action]: 실행할 비동기 작업
  /// [onError]: 커스텀 에러 핸들러 (에러 → Failure 변환)
  ///
  /// 예시:
  /// ```dart
  /// return RepositoryHelper.executeWithCustomHandler(
  ///   () => _remoteDataSource.refreshToken(token),
  ///   onError: (e) {
  ///     if (e is AuthException) {
  ///       return TokenExpiredFailure(message: e.message);
  ///     }
  ///     return null; // null 반환 시 기본 핸들러 사용
  ///   },
  /// );
  /// ```
  static Future<Either<Failure, T>> executeWithCustomHandler<T>(
    Future<T> Function() action, {
    required Failure? Function(Object error) onError,
  }) async {
    try {
      final result = await action();
      return Right(result);
    } catch (e) {
      final customFailure = onError(e);
      if (customFailure != null) {
        return Left(customFailure);
      }

      // 기본 에러 핸들링
      if (e is ServerException) {
        return Left(ServerFailure(
          message: e.message,
          code: e.code,
          statusCode: e.statusCode,
        ));
      }
      if (e is NetworkException) {
        return Left(NetworkFailure(message: e.message));
      }
      if (e is AuthException) {
        return Left(AuthFailure(message: e.message, code: e.code));
      }
      if (e is CacheException) {
        return Left(CacheFailure(message: e.message));
      }
      if (e is WebSocketException) {
        return Left(WebSocketFailure(message: e.message));
      }
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
