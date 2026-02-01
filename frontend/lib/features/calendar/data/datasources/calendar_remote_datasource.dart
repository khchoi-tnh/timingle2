import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/calendar_event_model.dart';

/// Calendar 원격 데이터소스 인터페이스
abstract class CalendarRemoteDataSource {
  /// Calendar 연동 상태 확인
  Future<CalendarStatusModel> getCalendarStatus();

  /// Calendar 이벤트 조회
  Future<List<CalendarEventModel>> getCalendarEvents({
    DateTime? startTime,
    DateTime? endTime,
  });

  /// timingle 이벤트를 Google Calendar에 동기화
  Future<SyncedCalendarEventModel> syncEventToCalendar(int eventId);

  /// Calendar 권한 포함 Google 로그인
  Future<(String accessToken, String refreshToken)> loginWithCalendar({
    required String idToken,
    required String? accessToken,
    required String? refreshToken,
    required String platform,
  });
}

/// Calendar 원격 데이터소스 구현
class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final ApiClient _apiClient;

  CalendarRemoteDataSourceImpl(this._apiClient);

  @override
  Future<CalendarStatusModel> getCalendarStatus() async {
    try {
      final response = await _apiClient.get(ApiConstants.calendarStatus);
      final data = response.data as Map<String, dynamic>;
      return CalendarStatusModel.fromJson(data);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? 'Calendar 상태 확인에 실패했습니다',
      );
    }
  }

  @override
  Future<List<CalendarEventModel>> getCalendarEvents({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startTime != null) {
        queryParams['start_time'] = startTime.toUtc().toIso8601String();
      }
      if (endTime != null) {
        queryParams['end_time'] = endTime.toUtc().toIso8601String();
      }

      final response = await _apiClient.get(
        ApiConstants.calendarEvents,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final events = (data['events'] as List<dynamic>?) ?? [];

      return events
          .map((e) => CalendarEventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? 'Calendar 이벤트 조회에 실패했습니다',
      );
    }
  }

  @override
  Future<SyncedCalendarEventModel> syncEventToCalendar(int eventId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.calendarSync(eventId),
      );

      final data = response.data as Map<String, dynamic>;
      final calendarEvent = data['calendar_event'] as Map<String, dynamic>;

      return SyncedCalendarEventModel.fromJson(calendarEvent);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? 'Calendar 동기화에 실패했습니다',
      );
    }
  }

  @override
  Future<(String accessToken, String refreshToken)> loginWithCalendar({
    required String idToken,
    required String? accessToken,
    required String? refreshToken,
    required String platform,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.authGoogleCalendar,
        data: {
          'id_token': idToken,
          if (accessToken != null) 'access_token': accessToken,
          if (refreshToken != null) 'refresh_token': refreshToken,
          'platform': platform,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final jwtAccessToken = data['access_token'] as String;
      final jwtRefreshToken = data['refresh_token'] as String;

      return (jwtAccessToken, jwtRefreshToken);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? 'Calendar 권한 로그인에 실패했습니다',
      );
    }
  }
}
