import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/utils/token_storage.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// AuthRepository 구현
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;
  final WebSocketClient _wsClient;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
    required ApiClient apiClient,
    required WebSocketClient wsClient,
  })  : _remoteDataSource = remoteDataSource,
        _tokenStorage = tokenStorage,
        _apiClient = apiClient,
        _wsClient = wsClient;

  @override
  Future<Either<Failure, (User, AuthTokens)>> registerWithPhone({
    required String phone,
    required String name,
  }) async {
    try {
      final (user, accessToken, refreshToken) =
          await _remoteDataSource.registerWithPhone(
        phone: phone,
        name: name,
      );

      // 토큰 저장
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await _tokenStorage.saveUserId(user.id);
      await _tokenStorage.saveUserPhone(user.phone);
      await _tokenStorage.saveUserName(user.name);

      // API 클라이언트에 토큰 설정
      _apiClient.setAccessToken(accessToken);
      _wsClient.setAccessToken(accessToken);

      final tokens = AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      return Right((user, tokens));
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
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken(String refreshToken) async {
    try {
      final newAccessToken =
          await _remoteDataSource.refreshToken(refreshToken);

      // 새 토큰 저장
      await _tokenStorage.saveAccessToken(newAccessToken);
      _apiClient.setAccessToken(newAccessToken);
      _wsClient.setAccessToken(newAccessToken);

      return Right(newAccessToken);
    } on AuthException catch (e) {
      // 토큰 갱신 실패 시 저장된 토큰 삭제
      await _tokenStorage.clearAll();
      _apiClient.setAccessToken(null);
      _wsClient.setAccessToken(null);

      return Left(TokenExpiredFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // 서버 로그아웃 실패해도 계속 진행
    }

    // 로컬 정리
    await _tokenStorage.clearAll();
    _apiClient.setAccessToken(null);
    _wsClient.setAccessToken(null);
    await _wsClient.disconnect();

    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        statusCode: e.statusCode,
      ));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> hasValidToken() async {
    final accessToken = await _tokenStorage.getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  @override
  Future<Either<Failure, User>> tryAutoLogin() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final refreshTokenValue = await _tokenStorage.getRefreshToken();

      if (accessToken == null || refreshTokenValue == null) {
        return const Left(AuthFailure(
          message: '저장된 인증 정보가 없습니다',
          code: 'NO_TOKEN',
        ));
      }

      // API 클라이언트에 토큰 설정
      _apiClient.setAccessToken(accessToken);
      _wsClient.setAccessToken(accessToken);

      // 현재 사용자 정보 가져오기 시도
      final result = await getCurrentUser();

      return result.fold(
        (failure) async {
          // 토큰 만료 시 갱신 시도
          if (failure is AuthFailure || failure is TokenExpiredFailure) {
            final refreshResult = await refreshToken(refreshTokenValue);
            return refreshResult.fold(
              (refreshFailure) => Left(refreshFailure),
              (newToken) => getCurrentUser(),
            );
          }
          return Left(failure);
        },
        (user) => Right(user),
      );
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
