import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../error/exceptions.dart';

/// Dio API 클라이언트
class ApiClient {
  late final Dio _dio;
  String? _accessToken;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 로깅 (개발 환경에서만)
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: true,
      ),
    );

    // 에러 인터셉터
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          final exception = _handleError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: exception,
              type: error.type,
              response: error.response,
            ),
          );
        },
      ),
    );
  }

  /// Access Token 설정
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Access Token 가져오기
  String? get accessToken => _accessToken;

  /// Dio 인스턴스 가져오기
  Dio get dio => _dio;

  /// GET 요청
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }

  /// POST 요청
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }

  /// PUT 요청
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }

  /// PATCH 요청
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }

  /// DELETE 요청
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException {
      rethrow;
    }
  }

  /// DioException -> Custom Exception
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        String message = '서버 오류가 발생했습니다';
        String? code;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('error')) {
            final errorData = data['error'];
            if (errorData is Map<String, dynamic>) {
              message = errorData['message'] ?? message;
              code = errorData['code'];
            } else if (errorData is String) {
              message = errorData;
            }
          } else if (data.containsKey('message')) {
            message = data['message'];
          }
        }

        switch (statusCode) {
          case 401:
            return AuthException(message: message, code: code ?? 'UNAUTHORIZED');
          case 403:
            return ServerException(
              message: '접근 권한이 없습니다',
              code: code ?? 'FORBIDDEN',
              statusCode: statusCode,
            );
          case 404:
            return ServerException(
              message: '요청한 정보를 찾을 수 없습니다',
              code: code ?? 'NOT_FOUND',
              statusCode: statusCode,
            );
          case 422:
            return ServerException(
              message: message,
              code: code ?? 'VALIDATION_ERROR',
              statusCode: statusCode,
            );
          default:
            return ServerException(
              message: message,
              code: code,
              statusCode: statusCode,
            );
        }

      case DioExceptionType.cancel:
        return const ServerException(message: '요청이 취소되었습니다');

      case DioExceptionType.badCertificate:
        return const NetworkException(message: '보안 인증서 오류');

      case DioExceptionType.unknown:
        if (error.error is Exception) {
          return error.error as Exception;
        }
        return ServerException(message: error.message ?? '알 수 없는 오류');
    }
  }
}

/// ApiClient Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
