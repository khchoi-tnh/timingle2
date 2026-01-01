import 'package:equatable/equatable.dart';

/// 오픈 타이밍글 슬롯 엔티티
/// 비즈니스 사용자가 공개한 예약 가능 시간대
class OpenSlot extends Equatable {
  final int id;
  final int hostId;
  final String hostName;
  final String? hostProfileUrl;
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final int currentParticipants;
  final bool isAvailable;
  final double? price;
  final String? category;
  final List<String>? tags;
  final DateTime createdAt;

  const OpenSlot({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.hostProfileUrl,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.isAvailable,
    this.price,
    this.category,
    this.tags,
    required this.createdAt,
  });

  /// 예약 가능 여부
  bool get canBook => isAvailable && currentParticipants < maxParticipants;

  /// 남은 자리 수
  int get remainingSlots => maxParticipants - currentParticipants;

  @override
  List<Object?> get props => [
        id,
        hostId,
        hostName,
        hostProfileUrl,
        title,
        description,
        location,
        startTime,
        endTime,
        maxParticipants,
        currentParticipants,
        isAvailable,
        price,
        category,
        tags,
        createdAt,
      ];
}
