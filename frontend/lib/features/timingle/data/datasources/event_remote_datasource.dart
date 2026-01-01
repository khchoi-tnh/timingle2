import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/event_model.dart';

/// 이벤트 원격 데이터소스 인터페이스
abstract class EventRemoteDataSource {
  Future<List<EventModel>> getEvents({String? status, int page, int limit});
  Future<EventModel> getEvent(int id);
  Future<EventModel> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<int>? participantIds,
  });
  Future<EventModel> updateEvent(int id, Map<String, dynamic> data);
  Future<EventModel> confirmEvent(int id);
  Future<void> cancelEvent(int id);
}

/// 이벤트 원격 데이터소스 구현
class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final ApiClient _apiClient;

  EventRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<EventModel>> getEvents({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        ApiConstants.events,
        queryParameters: queryParams,
      );

      final data = response.data;

      // 응답이 리스트인 경우
      if (data is List) {
        return data
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // 응답이 { events: [...] } 형태인 경우
      if (data is Map<String, dynamic> && data.containsKey('events')) {
        final events = data['events'] as List;
        return events
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? '이벤트 목록을 가져올 수 없습니다',
      );
    }
  }

  @override
  Future<EventModel> getEvent(int id) async {
    try {
      final response = await _apiClient.get(ApiConstants.eventById(id));
      return EventModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? '이벤트를 찾을 수 없습니다',
      );
    }
  }

  @override
  Future<EventModel> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<int>? participantIds,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.events,
        data: {
          'title': title,
          'description': description,
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
          'location': location,
          'participant_ids': participantIds,
        },
      );
      return EventModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? '이벤트 생성에 실패했습니다',
      );
    }
  }

  @override
  Future<EventModel> updateEvent(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        ApiConstants.eventById(id),
        data: data,
      );
      return EventModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? '이벤트 수정에 실패했습니다',
      );
    }
  }

  @override
  Future<EventModel> confirmEvent(int id) async {
    try {
      final response = await _apiClient.post(ApiConstants.eventConfirm(id));
      return EventModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? '이벤트 확정에 실패했습니다',
      );
    }
  }

  @override
  Future<void> cancelEvent(int id) async {
    try {
      await _apiClient.delete(ApiConstants.eventById(id));
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? '이벤트 취소에 실패했습니다',
      );
    }
  }
}
