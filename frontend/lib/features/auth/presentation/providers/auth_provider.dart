import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/utils/token_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register_with_phone.dart';
import '../../domain/usecases/try_auto_login.dart';

/// 인증 상태
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// 인증 상태 클래스
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

/// AuthRemoteDataSource Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});

/// AuthRepository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final apiClient = ref.watch(apiClientProvider);
  final wsClient = ref.watch(webSocketClientProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    tokenStorage: tokenStorage,
    apiClient: apiClient,
    wsClient: wsClient,
  );
});

/// UseCase Providers
final registerWithPhoneUseCaseProvider = Provider<RegisterWithPhone>((ref) {
  return RegisterWithPhone(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<Logout>((ref) {
  return Logout(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUser>((ref) {
  return GetCurrentUser(ref.watch(authRepositoryProvider));
});

final tryAutoLoginUseCaseProvider = Provider<TryAutoLogin>((ref) {
  return TryAutoLogin(ref.watch(authRepositoryProvider));
});

/// Auth StateNotifier
class AuthNotifier extends StateNotifier<AuthState> {
  final RegisterWithPhone _registerWithPhone;
  final Logout _logout;
  final GetCurrentUser _getCurrentUser;
  final TryAutoLogin _tryAutoLogin;

  AuthNotifier({
    required RegisterWithPhone registerWithPhone,
    required Logout logout,
    required GetCurrentUser getCurrentUser,
    required TryAutoLogin tryAutoLogin,
  })  : _registerWithPhone = registerWithPhone,
        _logout = logout,
        _getCurrentUser = getCurrentUser,
        _tryAutoLogin = tryAutoLogin,
        super(const AuthState());

  /// 자동 로그인 시도
  Future<void> tryAutoLogin() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _tryAutoLogin();

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: null,
        );
      },
      (user) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        );
      },
    );
  }

  /// 전화번호로 회원가입/로그인
  Future<bool> registerWithPhone({
    required String phone,
    required String name,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _registerWithPhone(
      RegisterWithPhoneParams(phone: phone, name: name),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (data) {
        final (user, _) = data;
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        );
        return true;
      },
    );
  }

  /// 로그아웃
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    await _logout();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 현재 사용자 정보 새로고침
  Future<void> refreshCurrentUser() async {
    final result = await _getCurrentUser();

    result.fold(
      (failure) {
        // 실패해도 현재 상태 유지
      },
      (user) {
        state = state.copyWith(user: user);
      },
    );
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Auth StateNotifier Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    registerWithPhone: ref.watch(registerWithPhoneUseCaseProvider),
    logout: ref.watch(logoutUseCaseProvider),
    getCurrentUser: ref.watch(getCurrentUserUseCaseProvider),
    tryAutoLogin: ref.watch(tryAutoLoginUseCaseProvider),
  );
});

/// 현재 사용자 Provider (편의용)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// 인증 상태 Provider (편의용)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
