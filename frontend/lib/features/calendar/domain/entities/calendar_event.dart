import 'package:equatable/equatable.dart';

/// Google Calendar 이벤트 엔티티
class CalendarEvent extends Equatable {
  final String id;
  final String summary;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final String? htmlLink;

  const CalendarEvent({
    required this.id,
    required this.summary,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    this.htmlLink,
  });

  @override
  List<Object?> get props => [
        id,
        summary,
        description,
        location,
        startTime,
        endTime,
        htmlLink,
      ];
}

/// Calendar 연동 상태
class CalendarStatus extends Equatable {
  final bool hasCalendarAccess;

  const CalendarStatus({required this.hasCalendarAccess});

  @override
  List<Object?> get props => [hasCalendarAccess];
}

/// 동기화된 Calendar 이벤트 결과
class SyncedCalendarEvent extends Equatable {
  final String id;
  final String summary;
  final DateTime startTime;
  final DateTime endTime;
  final String? htmlLink;

  const SyncedCalendarEvent({
    required this.id,
    required this.summary,
    required this.startTime,
    required this.endTime,
    this.htmlLink,
  });

  @override
  List<Object?> get props => [id, summary, startTime, endTime, htmlLink];
}
