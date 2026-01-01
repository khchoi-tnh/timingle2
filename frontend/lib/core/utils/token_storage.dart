import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// 토큰 저장소 (Secure Storage)
class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Access Token 저장
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: token);
  }

  /// Access Token 가져오기
  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  /// Refresh Token 저장
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  /// Refresh Token 가져오기
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  /// 토큰 모두 저장
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// 사용자 ID 저장
  Future<void> saveUserId(int userId) async {
    await _storage.write(
      key: AppConstants.userIdKey,
      value: userId.toString(),
    );
  }

  /// 사용자 ID 가져오기
  Future<int?> getUserId() async {
    final value = await _storage.read(key: AppConstants.userIdKey);
    return value != null ? int.tryParse(value) : null;
  }

  /// 사용자 전화번호 저장
  Future<void> saveUserPhone(String phone) async {
    await _storage.write(key: AppConstants.userPhoneKey, value: phone);
  }

  /// 사용자 전화번호 가져오기
  Future<String?> getUserPhone() async {
    return await _storage.read(key: AppConstants.userPhoneKey);
  }

  /// 사용자 이름 저장
  Future<void> saveUserName(String name) async {
    await _storage.write(key: AppConstants.userNameKey, value: name);
  }

  /// 사용자 이름 가져오기
  Future<String?> getUserName() async {
    return await _storage.read(key: AppConstants.userNameKey);
  }

  /// 모든 토큰/사용자 정보 삭제 (로그아웃)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// 토큰만 삭제
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.accessTokenKey),
      _storage.delete(key: AppConstants.refreshTokenKey),
    ]);
  }
}

/// TokenStorage Provider
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});
