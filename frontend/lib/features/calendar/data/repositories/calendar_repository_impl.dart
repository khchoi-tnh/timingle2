import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/utils/token_storage.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_remote_datasource.dart';

/// Calendar Repository 구현
class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;
  final WebSocketClient _wsClient;
  final GoogleSignIn _googleSignIn;

  /// Calendar scope 상수
  static const String calendarScope =
      'https://www.googleapis.com/auth/calendar';

  CalendarRepositoryImpl({
    required CalendarRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
    required ApiClient apiClient,
    required WebSocketClient wsClient,
    GoogleSignIn? googleSignIn,
  })  : _remoteDataSource = remoteDataSource,
        _tokenStorage = tokenStorage,
        _apiClient = apiClient,
        _wsClient = wsClient,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [
                'email',
                'profile',
                calendarScope,
              ],
            );

  @override
  Future<Either<Failure, CalendarStatus>> getCalendarStatus() async {
    try {
      final status = await _remoteDataSource.getCalendarStatus();
      return Right(status);
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
  Future<Either<Failure, List<CalendarEvent>>> getCalendarEvents({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final events = await _remoteDataSource.getCalendarEvents(
        startTime: startTime,
        endTime: endTime,
      );
      return Right(events);
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
  Future<Either<Failure, SyncedCalendarEvent>> syncEventToCalendar(
      int eventId) async {
    try {
      final syncedEvent = await _remoteDataSource.syncEventToCalendar(eventId);
      return Right(syncedEvent);
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
  Future<Either<Failure, void>> loginWithCalendarPermission() async {
    try {
      // Google Sign-In 실행 (Calendar scope 포함)
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Left(AuthFailure(
          message: 'Google 로그인이 취소되었습니다',
          code: 'GOOGLE_SIGN_IN_CANCELLED',
        ));
      }

      // 토큰 가져오기
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return const Left(AuthFailure(
          message: 'Google ID 토큰을 가져올 수 없습니다',
          code: 'NO_ID_TOKEN',
        ));
      }

      // 플랫폼 확인
      final platform = Platform.isAndroid ? 'android' : 'ios';

      // Backend API 호출 (Calendar 권한 포함 로그인)
      final (jwtAccessToken, jwtRefreshToken) =
          await _remoteDataSource.loginWithCalendar(
        idToken: idToken,
        accessToken: accessToken,
        refreshToken: null, // google_sign_in은 refresh_token을 직접 제공하지 않음
        platform: platform,
      );

      // JWT 토큰 저장
      await _tokenStorage.saveTokens(
        accessToken: jwtAccessToken,
        refreshToken: jwtRefreshToken,
      );

      // API 클라이언트에 토큰 설정
      _apiClient.setAccessToken(jwtAccessToken);
      _wsClient.setAccessToken(jwtAccessToken);

      return const Right(null);
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

  /// 추가 Calendar scope 요청 (기존 로그인 사용자용)
  Future<Either<Failure, void>> requestCalendarScope() async {
    try {
      // 현재 로그인된 사용자가 있는지 확인
      final currentUser = _googleSignIn.currentUser;
      if (currentUser == null) {
        // 로그인되지 않은 경우 새로 로그인
        return loginWithCalendarPermission();
      }

      // 추가 scope 요청
      final granted = await _googleSignIn.requestScopes([calendarScope]);
      if (!granted) {
        return const Left(AuthFailure(
          message: 'Calendar 권한이 거부되었습니다',
          code: 'CALENDAR_PERMISSION_DENIED',
        ));
      }

      // 새 토큰으로 다시 로그인
      return loginWithCalendarPermission();
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
