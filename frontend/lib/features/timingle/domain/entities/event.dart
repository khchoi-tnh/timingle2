import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// 이벤트 참여자
class EventParticipant extends Equatable {
  final int id;
  final String name;
  final String? displayName;
  final String? profileImageUrl;
  final bool confirmed;
  final DateTime? confirmedAt;

  const EventParticipant({
    required this.id,
    required this.name,
    this.displayName,
    this.profileImageUrl,
    this.confirmed = false,
    this.confirmedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        profileImageUrl,
        confirmed,
        confirmedAt,
      ];
}

/// 이벤트 엔티티
class Event extends Equatable {
  final int id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String status;
  final int creatorId;
  final EventParticipant? creator;
  final List<EventParticipant> participants;
  final int? unreadMessages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.status = AppConstants.statusProposed,
    required this.creatorId,
    this.creator,
    this.participants = const [],
    this.unreadMessages,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startTime,
        endTime,
        location,
        status,
        creatorId,
        creator,
        participants,
        unreadMessages,
        createdAt,
        updatedAt,
      ];

  /// 상태 체크 헬퍼
  bool get isProposed => status == AppConstants.statusProposed;
  bool get isConfirmed => status == AppConstants.statusConfirmed;
  bool get isCanceled => status == AppConstants.statusCanceled;
  bool get isDone => status == AppConstants.statusDone;

  /// 읽지 않은 메시지 있는지 확인
  bool get hasUnreadMessages => (unreadMessages ?? 0) > 0;

  /// 복사 메서드
  Event copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? status,
    int? creatorId,
    EventParticipant? creator,
    List<EventParticipant>? participants,
    int? unreadMessages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      creator: creator ?? this.creator,
      participants: participants ?? this.participants,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
