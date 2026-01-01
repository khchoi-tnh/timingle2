import '../../domain/entities/event.dart';

/// 이벤트 참여자 모델
class EventParticipantModel extends EventParticipant {
  const EventParticipantModel({
    required super.id,
    required super.name,
    super.displayName,
    super.profileImageUrl,
    super.confirmed = false,
    super.confirmedAt,
  });

  factory EventParticipantModel.fromJson(Map<String, dynamic> json) {
    return EventParticipantModel(
      id: json['id'] as int,
      name: json['name'] as String,
      displayName: json['display_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      confirmed: json['confirmed'] as bool? ?? false,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'profile_image_url': profileImageUrl,
      'confirmed': confirmed,
      'confirmed_at': confirmedAt?.toIso8601String(),
    };
  }
}

/// 이벤트 모델
class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.title,
    super.description,
    required super.startTime,
    required super.endTime,
    super.location,
    super.status,
    required super.creatorId,
    super.creator,
    super.participants = const [],
    super.unreadMessages,
    required super.createdAt,
    super.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // 참여자 파싱
    List<EventParticipant> participants = [];
    if (json['participants'] != null) {
      participants = (json['participants'] as List)
          .map((p) => EventParticipantModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    // 생성자 파싱
    EventParticipant? creator;
    if (json['creator'] != null) {
      creator =
          EventParticipantModel.fromJson(json['creator'] as Map<String, dynamic>);
    }

    return EventModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      location: json['location'] as String?,
      status: json['status'] as String? ?? 'PROPOSED',
      creatorId: json['creator_id'] as int,
      creator: creator,
      participants: participants,
      unreadMessages: json['unread_messages'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'status': status,
      'creator_id': creatorId,
      'unread_messages': unreadMessages,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory EventModel.fromEntity(Event event) {
    return EventModel(
      id: event.id,
      title: event.title,
      description: event.description,
      startTime: event.startTime,
      endTime: event.endTime,
      location: event.location,
      status: event.status,
      creatorId: event.creatorId,
      creator: event.creator,
      participants: event.participants,
      unreadMessages: event.unreadMessages,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    );
  }
}
