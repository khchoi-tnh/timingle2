import 'package:equatable/equatable.dart';

/// 사용자 엔티티
class User extends Equatable {
  final int id;
  final String phone;
  final String name;
  final String? email;
  final String? displayName;
  final String? profileImageUrl;
  final String? region;
  final List<String>? interests;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    this.displayName,
    this.profileImageUrl,
    this.region,
    this.interests,
    this.role = 'USER',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        phone,
        name,
        email,
        displayName,
        profileImageUrl,
        region,
        interests,
        role,
        isActive,
        createdAt,
        updatedAt,
      ];

  /// 복사 메서드
  User copyWith({
    int? id,
    String? phone,
    String? name,
    String? email,
    String? displayName,
    String? profileImageUrl,
    String? region,
    List<String>? interests,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      region: region ?? this.region,
      interests: interests ?? this.interests,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
