import '../../domain/entities/user.dart';

/// 사용자 데이터 모델
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.phone,
    required super.name,
    super.email,
    super.displayName,
    super.profileImageUrl,
    super.region,
    super.interests,
    super.role = 'USER',
    super.isActive = true,
    required super.createdAt,
    super.updatedAt,
  });

  /// JSON -> UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      phone: json['phone'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      region: json['region'] as String?,
      interests: json['interests'] != null
          ? List<String>.from(json['interests'] as List)
          : null,
      role: json['role'] as String? ?? 'USER',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// UserModel -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'display_name': displayName,
      'profile_image_url': profileImageUrl,
      'region': region,
      'interests': interests,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// User -> UserModel
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      phone: user.phone,
      name: user.name,
      email: user.email,
      displayName: user.displayName,
      profileImageUrl: user.profileImageUrl,
      region: user.region,
      interests: user.interests,
      role: user.role,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }
}
