import 'package:equatable/equatable.dart';

/// 친구 엔티티
class Friend extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? profileUrl;
  final FriendStatus status;
  final DateTime? lastEventDate;
  final int eventCount;
  final DateTime createdAt;

  const Friend({
    required this.id,
    required this.name,
    this.phone,
    this.profileUrl,
    required this.status,
    this.lastEventDate,
    required this.eventCount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        profileUrl,
        status,
        lastEventDate,
        eventCount,
        createdAt,
      ];
}

/// 친구 상태
enum FriendStatus {
  accepted, // 친구
  pending, // 대기 중 (내가 보낸 요청)
  received, // 받은 요청
  blocked, // 차단됨
}

extension FriendStatusExtension on FriendStatus {
  String get displayName {
    switch (this) {
      case FriendStatus.accepted:
        return '친구';
      case FriendStatus.pending:
        return '요청 중';
      case FriendStatus.received:
        return '요청 받음';
      case FriendStatus.blocked:
        return '차단됨';
    }
  }
}
