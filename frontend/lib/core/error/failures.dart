import 'package:equatable/equatable.dart';

/// 실패 기본 클래스
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// 서버 에러
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// 네트워크 에러 (연결 불가)
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = '네트워크 연결을 확인해주세요',
    super.code = 'NETWORK_ERROR',
  });
}

/// 인증 에러
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = '인증이 필요합니다',
    super.code = 'AUTH_ERROR',
  });
}

/// 토큰 만료
class TokenExpiredFailure extends AuthFailure {
  const TokenExpiredFailure({
    super.message = '세션이 만료되었습니다. 다시 로그인해주세요',
    super.code = 'TOKEN_EXPIRED',
  });
}

/// 권한 없음
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    super.message = '접근 권한이 없습니다',
    super.code = 'FORBIDDEN',
  });
}

/// 리소스 없음
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = '요청한 정보를 찾을 수 없습니다',
    super.code = 'NOT_FOUND',
  });
}

/// 입력값 검증 에러
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    super.message = '입력값을 확인해주세요',
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// 캐시 에러
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = '로컬 데이터를 불러올 수 없습니다',
    super.code = 'CACHE_ERROR',
  });
}

/// WebSocket 에러
class WebSocketFailure extends Failure {
  const WebSocketFailure({
    super.message = '실시간 연결에 실패했습니다',
    super.code = 'WEBSOCKET_ERROR',
  });
}

/// 알 수 없는 에러
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = '알 수 없는 오류가 발생했습니다',
    super.code = 'UNKNOWN_ERROR',
  });
}
