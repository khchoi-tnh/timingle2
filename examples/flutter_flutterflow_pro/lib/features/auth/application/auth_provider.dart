import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final User? user;
  LoginState({this.isLoading = false, this.errorMessage, this.user});
  LoginState copyWith({bool? isLoading, String? errorMessage, User? user}) => LoginState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    user: user ?? this.user,
  );
}

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthRepository authRepository;
  LoginNotifier(this.authRepository) : super(LoginState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await authRepository.login(
        LoginRequest(email: email.trim(), password: password),
      );
      state = state.copyWith(isLoading: false, user: user, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return LoginNotifier(authRepository);
});

final isLoginLoadingProvider = Provider<bool>((ref) => ref.watch(loginProvider).isLoading);
final loginErrorProvider = Provider<String?>((ref) => ref.watch(loginProvider).errorMessage);
final currentUserProvider = Provider<User?>((ref) => ref.watch(loginProvider).user);
