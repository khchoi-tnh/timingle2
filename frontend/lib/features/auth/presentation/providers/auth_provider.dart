import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/utils/token_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

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

/// Auth StateNotifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  /// 자동 로그인 시도
  Future<void> tryAutoLogin() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _repository.tryAutoLogin();

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

    final result = await _repository.registerWithPhone(
      phone: phone,
      name: name,
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

    await _repository.logout();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 현재 사용자 정보 새로고침
  Future<void> refreshCurrentUser() async {
    final result = await _repository.getCurrentUser();

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
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// 현재 사용자 Provider (편의용)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// 인증 상태 Provider (편의용)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
