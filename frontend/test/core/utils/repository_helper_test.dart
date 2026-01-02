import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/error/exceptions.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/core/utils/repository_helper.dart';

void main() {
  group('RepositoryHelper', () {
    group('execute', () {
      test('성공 시 Right(result) 반환', () async {
        final result = await RepositoryHelper.execute<String>(
          () async => 'success',
        );

        expect(result, isA<Right<Failure, String>>());
        expect(result.getOrElse(() => ''), 'success');
      });

      test('ServerException 발생 시 ServerFailure 반환', () async {
        final result = await RepositoryHelper.execute<String>(
          () async => throw const ServerException(
            message: 'Server error',
            statusCode: 500,
          ),
        );

        expect(result, isA<Left<Failure, String>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, 'Server error');
          },
          (_) => fail('Should return Left'),
        );
      });

      test('ServerException 404 + on404 옵션 시 커스텀 Failure 반환', () async {
        final result = await RepositoryHelper.execute<String>(
          () async => throw const ServerException(
            message: 'Not found',
            statusCode: 404,
          ),
          on404: const NotFoundFailure(message: '이벤트를 찾을 수 없습니다'),
        );

        expect(result, isA<Left<Failure, String>>());
        result.fold(
          (failure) {
            expect(failure, isA<NotFoundFailure>());
            expect(failure.message, '이벤트를 찾을 수 없습니다');
          },
          (_) => fail('Should return Left'),
        );
      });

      test('NetworkException 발생 시 NetworkFailure 반환', () async {
        final result = await RepositoryHelper.execute<String>(
          () async => throw const NetworkException(message: 'No internet'),
        );

        expect(result, isA<Left<Failure, String>>());
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, 'No internet');
          },
          (_) => fail('Should return Left'),
        );
      });

      test('AuthException 발생 시 AuthFailure 반환', () async {
        final result = await RepositoryHelper.execute<String>(
          () async => throw const AuthException(
            message: 'Unauthorized',
            code: 'AUTH_001',
          ),
        );

        expect(result, isA<Left<Failure, String>>());
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Unauthorized');
          },
          (_) => fail('Should return Left'),
        );
      });

      test('일반 Exception 발생 시 UnknownFailure 반환', () async {
        final result = await RepositoryHelper.execute<String>(
          () async => throw Exception('Unknown error'),
        );

        expect(result, isA<Left<Failure, String>>());
        result.fold(
          (failure) {
            expect(failure, isA<UnknownFailure>());
          },
          (_) => fail('Should return Left'),
        );
      });
    });

    group('executeVoid', () {
      test('성공 시 Right(null) 반환', () async {
        final result = await RepositoryHelper.executeVoid(
          () async {},
        );

        expect(result, isA<Right<Failure, void>>());
      });

      test('Exception 발생 시 Failure 반환', () async {
        final result = await RepositoryHelper.executeVoid(
          () async => throw const ServerException(message: 'Error'),
        );

        expect(result, isA<Left<Failure, void>>());
      });
    });

    group('executeSync', () {
      test('성공 시 Right(null) 반환', () {
        final result = RepositoryHelper.executeSync(() {});

        expect(result, isA<Right<Failure, void>>());
      });

      test('WebSocketException 발생 시 WebSocketFailure 반환', () {
        final result = RepositoryHelper.executeSync(
          () => throw const WebSocketException(message: 'Connection failed'),
        );

        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (failure) {
            expect(failure, isA<WebSocketFailure>());
            expect(failure.message, 'Connection failed');
          },
          (_) => fail('Should return Left'),
        );
      });
    });

    group('executeWithCustomHandler', () {
      test('커스텀 핸들러가 Failure 반환 시 해당 Failure 사용', () async {
        final result = await RepositoryHelper.executeWithCustomHandler<String>(
          () async => throw const AuthException(message: 'Token expired'),
          onError: (e) {
            if (e is AuthException) {
              return const TokenExpiredFailure(message: '세션이 만료되었습니다');
            }
            return null;
          },
        );

        expect(result, isA<Left<Failure, String>>());
        result.fold(
          (failure) {
            expect(failure, isA<TokenExpiredFailure>());
            expect(failure.message, '세션이 만료되었습니다');
          },
          (_) => fail('Should return Left'),
        );
      });

      test('커스텀 핸들러가 null 반환 시 기본 핸들러 사용', () async {
        final result = await RepositoryHelper.executeWithCustomHandler<String>(
          () async => throw const NetworkException(message: 'No internet'),
          onError: (e) => null,
        );

        expect(result, isA<Left<Failure, String>>());
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
          },
          (_) => fail('Should return Left'),
        );
      });
    });
  });
}
