import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

/// 인증 원격 데이터소스 인터페이스
abstract class AuthRemoteDataSource {
  Future<(UserModel, String, String)> registerWithPhone({
    required String phone,
    required String name,
  });

  Future<String> refreshToken(String refreshToken);

  Future<void> logout();

  Future<UserModel> getCurrentUser();
}

/// 인증 원격 데이터소스 구현
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<(UserModel, String, String)> registerWithPhone({
    required String phone,
    required String name,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.authRegister,
        data: {
          'phone': phone,
          'name': name,
        },
      );

      final data = response.data as Map<String, dynamic>;

      final user = UserModel.fromJson(data);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      return (user, accessToken, refreshToken);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? '회원가입에 실패했습니다',
      );
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.authRefresh,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      return data['access_token'] as String;
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw const AuthException(
        message: '토큰 갱신에 실패했습니다',
        code: 'TOKEN_REFRESH_FAILED',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.authLogout);
    } on DioException {
      // 로그아웃 실패해도 로컬 토큰은 삭제
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.usersMe);
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? '사용자 정보를 가져올 수 없습니다',
      );
    }
  }
}
