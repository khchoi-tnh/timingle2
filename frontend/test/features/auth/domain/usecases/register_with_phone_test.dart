import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/auth/domain/entities/auth_tokens.dart';
import 'package:frontend/features/auth/domain/entities/user.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/domain/usecases/register_with_phone.dart';

class MockAuthRepository implements AuthRepository {
  Either<Failure, (User, AuthTokens)>? registerResult;

  @override
  Future<Either<Failure, (User, AuthTokens)>> registerWithPhone({
    required String phone,
    required String name,
  }) async {
    return registerResult ?? const Left(ServerFailure(message: 'Not configured'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late RegisterWithPhone useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterWithPhone(mockRepository);
  });

  User createTestUser() {
    return User(
      id: 1,
      phone: '01012345678',
      name: 'Test',
      createdAt: DateTime(2024, 1, 1),
    );
  }

  group('RegisterWithPhone', () {
    test('should return User and AuthTokens on success', () async {
      final user = createTestUser();
      const tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');
      mockRepository.registerResult = Right((user, tokens));

      final result = await useCase(const RegisterWithPhoneParams(
        phone: '01012345678',
        name: 'Test',
      ));

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success'),
        (data) {
          final (resultUser, resultTokens) = data;
          expect(resultUser.phone, '01012345678');
          expect(resultUser.name, 'Test');
          expect(resultTokens.accessToken, 'access');
        },
      );
    });

    test('should return ServerFailure on error', () async {
      mockRepository.registerResult = const Left(
        ServerFailure(message: 'Server error'),
      );

      final result = await useCase(const RegisterWithPhoneParams(
        phone: '01012345678',
        name: 'Test',
      ));

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'Server error'),
        (data) => fail('Expected failure'),
      );
    });

    test('should return NetworkFailure when offline', () async {
      mockRepository.registerResult = const Left(
        NetworkFailure(message: '네트워크 연결을 확인해주세요'),
      );

      final result = await useCase(const RegisterWithPhoneParams(
        phone: '01012345678',
        name: 'Test',
      ));

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
        },
        (data) => fail('Expected failure'),
      );
    });
  });
}
