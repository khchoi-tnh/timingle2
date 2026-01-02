import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/auth/domain/entities/auth_tokens.dart';
import 'package:frontend/features/auth/domain/entities/user.dart';
import 'package:frontend/features/auth/domain/usecases/get_current_user.dart';
import 'package:frontend/features/auth/domain/usecases/logout.dart';
import 'package:frontend/features/auth/domain/usecases/register_with_phone.dart';
import 'package:frontend/features/auth/domain/usecases/try_auto_login.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';

// Test helper to create User
User createTestUser({
  int id = 1,
  String phone = '01012345678',
  String name = 'Test',
}) {
  return User(
    id: id,
    phone: phone,
    name: name,
    createdAt: DateTime(2024, 1, 1),
  );
}

// Mock UseCases
class MockRegisterWithPhone implements RegisterWithPhone {
  Either<Failure, (User, AuthTokens)>? result;

  @override
  Future<Either<Failure, (User, AuthTokens)>> call(RegisterWithPhoneParams params) async {
    return result ?? const Left(ServerFailure(message: 'Not configured'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLogout implements Logout {
  bool called = false;

  @override
  Future<Either<Failure, void>> call() async {
    called = true;
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGetCurrentUser implements GetCurrentUser {
  Either<Failure, User>? result;

  @override
  Future<Either<Failure, User>> call() async {
    return result ?? const Left(ServerFailure(message: 'Not configured'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTryAutoLogin implements TryAutoLogin {
  Either<Failure, User>? result;

  @override
  Future<Either<Failure, User>> call() async {
    return result ?? const Left(AuthFailure(message: 'No token'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthState', () {
    test('initial state should have correct defaults', () {
      const state = AuthState();

      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('copyWith should update only specified fields', () {
      const state = AuthState();
      final user = createTestUser();

      final newState = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );

      expect(newState.status, AuthStatus.authenticated);
      expect(newState.user, user);
      expect(newState.isAuthenticated, isTrue);
    });

    test('isAuthenticated should return true only for authenticated status', () {
      expect(
        const AuthState(status: AuthStatus.authenticated).isAuthenticated,
        isTrue,
      );
      expect(
        const AuthState(status: AuthStatus.unauthenticated).isAuthenticated,
        isFalse,
      );
      expect(
        const AuthState(status: AuthStatus.loading).isAuthenticated,
        isFalse,
      );
    });

    test('isLoading should return true only for loading status', () {
      expect(
        const AuthState(status: AuthStatus.loading).isLoading,
        isTrue,
      );
      expect(
        const AuthState(status: AuthStatus.authenticated).isLoading,
        isFalse,
      );
    });
  });

  group('AuthNotifier', () {
    late MockRegisterWithPhone mockRegister;
    late MockLogout mockLogout;
    late MockGetCurrentUser mockGetCurrentUser;
    late MockTryAutoLogin mockTryAutoLogin;
    late AuthNotifier notifier;

    setUp(() {
      mockRegister = MockRegisterWithPhone();
      mockLogout = MockLogout();
      mockGetCurrentUser = MockGetCurrentUser();
      mockTryAutoLogin = MockTryAutoLogin();

      notifier = AuthNotifier(
        registerWithPhone: mockRegister,
        logout: mockLogout,
        getCurrentUser: mockGetCurrentUser,
        tryAutoLogin: mockTryAutoLogin,
      );
    });

    test('initial state should be AuthStatus.initial', () {
      expect(notifier.state.status, AuthStatus.initial);
    });

    group('tryAutoLogin', () {
      test('should set authenticated state on success', () async {
        final user = createTestUser();
        mockTryAutoLogin.result = Right(user);

        await notifier.tryAutoLogin();

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user, user);
      });

      test('should set unauthenticated state on failure', () async {
        mockTryAutoLogin.result = const Left(AuthFailure(message: 'No token'));

        await notifier.tryAutoLogin();

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.user, isNull);
      });
    });

    group('registerWithPhone', () {
      test('should return true and set authenticated state on success', () async {
        final user = createTestUser();
        const tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');
        mockRegister.result = Right((user, tokens));

        final result = await notifier.registerWithPhone(
          phone: '01012345678',
          name: 'Test',
        );

        expect(result, isTrue);
        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user, user);
      });

      test('should return false and set error state on failure', () async {
        mockRegister.result = const Left(ServerFailure(message: 'Server error'));

        final result = await notifier.registerWithPhone(
          phone: '01012345678',
          name: 'Test',
        );

        expect(result, isFalse);
        expect(notifier.state.status, AuthStatus.error);
        expect(notifier.state.errorMessage, 'Server error');
      });
    });

    group('logout', () {
      test('should set unauthenticated state', () async {
        // First, authenticate
        final user = createTestUser();
        const tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');
        mockRegister.result = Right((user, tokens));
        await notifier.registerWithPhone(phone: '01012345678', name: 'Test');

        // Then logout
        await notifier.logout();

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.user, isNull);
        expect(mockLogout.called, isTrue);
      });
    });

    group('refreshCurrentUser', () {
      test('should update user on success', () async {
        // First authenticate
        final user = createTestUser();
        const tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');
        mockRegister.result = Right((user, tokens));
        await notifier.registerWithPhone(phone: '01012345678', name: 'Test');

        // Setup refresh response with updated name
        final updatedUser = createTestUser(name: 'Updated');
        mockGetCurrentUser.result = Right(updatedUser);

        await notifier.refreshCurrentUser();

        expect(notifier.state.user?.name, 'Updated');
      });

      test('should maintain current state on failure', () async {
        // First authenticate
        final user = createTestUser();
        const tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');
        mockRegister.result = Right((user, tokens));
        await notifier.registerWithPhone(phone: '01012345678', name: 'Test');

        // Setup refresh failure
        mockGetCurrentUser.result = const Left(ServerFailure(message: 'Error'));

        await notifier.refreshCurrentUser();

        // State should be maintained
        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user?.name, 'Test');
      });
    });

    test('clearError should clear error message', () async {
      mockRegister.result = const Left(ServerFailure(message: 'Error'));
      await notifier.registerWithPhone(phone: '01012345678', name: 'Test');
      expect(notifier.state.errorMessage, 'Error');

      notifier.clearError();

      expect(notifier.state.errorMessage, isNull);
    });
  });
}
