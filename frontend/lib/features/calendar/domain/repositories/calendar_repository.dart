import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/calendar_event.dart';

/// Calendar Repository 인터페이스
abstract class CalendarRepository {
  /// Google Calendar 연동 상태 확인
  Future<Either<Failure, CalendarStatus>> getCalendarStatus();

  /// Google Calendar 이벤트 조회
  Future<Either<Failure, List<CalendarEvent>>> getCalendarEvents({
    DateTime? startTime,
    DateTime? endTime,
  });

  /// timingle 이벤트를 Google Calendar에 동기화
  Future<Either<Failure, SyncedCalendarEvent>> syncEventToCalendar(int eventId);

  /// Calendar 권한 포함 Google 로그인
  Future<Either<Failure, void>> loginWithCalendarPermission();
}
