import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/chat_message_model.dart';

/// 채팅 원격 데이터소스 인터페이스
abstract class ChatRemoteDataSource {
  /// 채팅 메시지 목록 조회
  Future<List<ChatMessageModel>> getMessages(int eventId, {int limit});
}

/// 채팅 원격 데이터소스 구현
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _apiClient;

  ChatRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<ChatMessageModel>> getMessages(
    int eventId, {
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.eventMessages(eventId),
        queryParameters: {'limit': limit},
      );

      final data = response.data;

      // 응답이 리스트인 경우
      if (data is List) {
        return data
            .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // 응답이 { messages: [...] } 형태인 경우
      if (data is Map<String, dynamic> && data.containsKey('messages')) {
        final messages = data['messages'] as List;
        return messages
            .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw ServerException(
        message: e.message ?? '메시지를 불러올 수 없습니다',
      );
    }
  }
}
