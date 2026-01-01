/// 서버 예외
class ServerException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (code: $code, status: $statusCode)';
}

/// 네트워크 예외
class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = '네트워크 연결을 확인해주세요'});

  @override
  String toString() => 'NetworkException: $message';
}

/// 인증 예외
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException({
    this.message = '인증이 필요합니다',
    this.code,
  });

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// 캐시 예외
class CacheException implements Exception {
  final String message;

  const CacheException({this.message = '캐시 데이터를 불러올 수 없습니다'});

  @override
  String toString() => 'CacheException: $message';
}

/// WebSocket 예외
class WebSocketException implements Exception {
  final String message;

  const WebSocketException({this.message = 'WebSocket 연결에 실패했습니다'});

  @override
  String toString() => 'WebSocketException: $message';
}
