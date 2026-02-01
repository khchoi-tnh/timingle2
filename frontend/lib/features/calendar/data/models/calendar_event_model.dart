import '../../domain/entities/calendar_event.dart';

/// Calendar 이벤트 모델
class CalendarEventModel extends CalendarEvent {
  const CalendarEventModel({
    required super.id,
    required super.summary,
    super.description,
    super.location,
    required super.startTime,
    required super.endTime,
    super.htmlLink,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      summary: json['summary'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      htmlLink: json['html_link'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'summary': summary,
      'description': description,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'html_link': htmlLink,
    };
  }
}

/// Calendar 상태 모델
class CalendarStatusModel extends CalendarStatus {
  const CalendarStatusModel({required super.hasCalendarAccess});

  factory CalendarStatusModel.fromJson(Map<String, dynamic> json) {
    return CalendarStatusModel(
      hasCalendarAccess: json['has_calendar_access'] as bool? ?? false,
    );
  }
}

/// 동기화된 Calendar 이벤트 모델
class SyncedCalendarEventModel extends SyncedCalendarEvent {
  const SyncedCalendarEventModel({
    required super.id,
    required super.summary,
    required super.startTime,
    required super.endTime,
    super.htmlLink,
  });

  factory SyncedCalendarEventModel.fromJson(Map<String, dynamic> json) {
    return SyncedCalendarEventModel(
      id: json['id'] as String,
      summary: json['summary'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      htmlLink: json['html_link'] as String?,
    );
  }
}
