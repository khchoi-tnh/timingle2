import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/event.dart';

/// 이벤트 Repository 인터페이스
abstract class EventRepository {
  /// 이벤트 목록 조회
  Future<Either<Failure, List<Event>>> getEvents({
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// 이벤트 상세 조회
  Future<Either<Failure, Event>> getEvent(int id);

  /// 이벤트 생성
  Future<Either<Failure, Event>> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<int>? participantIds,
  });

  /// 이벤트 수정
  Future<Either<Failure, Event>> updateEvent(
    int id,
    Map<String, dynamic> data,
  );

  /// 이벤트 확정
  Future<Either<Failure, Event>> confirmEvent(int id);

  /// 이벤트 취소
  Future<Either<Failure, void>> cancelEvent(int id);
}
