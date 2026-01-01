import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_tokens.dart';
import '../entities/user.dart';

/// 인증 Repository 인터페이스
abstract class AuthRepository {
  /// 전화번호로 회원가입/로그인
  Future<Either<Failure, (User, AuthTokens)>> registerWithPhone({
    required String phone,
    required String name,
  });

  /// 토큰 갱신
  Future<Either<Failure, String>> refreshToken(String refreshToken);

  /// 로그아웃
  Future<Either<Failure, void>> logout();

  /// 현재 사용자 정보 조회
  Future<Either<Failure, User>> getCurrentUser();

  /// 저장된 토큰 확인
  Future<bool> hasValidToken();

  /// 저장된 토큰으로 자동 로그인 시도
  Future<Either<Failure, User>> tryAutoLogin();
}
