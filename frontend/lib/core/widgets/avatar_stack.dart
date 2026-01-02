import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// 아바타에 표시할 데이터
class AvatarData {
  final String name;
  final String? imageUrl;

  const AvatarData({
    required this.name,
    this.imageUrl,
  });
}

/// 참여자 아바타 스택 위젯
class AvatarStack extends StatelessWidget {
  final List<AvatarData> avatars;
  final int maxDisplay;
  final double avatarSize;
  final double overlap;
  final bool showCount;

  const AvatarStack({
    super.key,
    required this.avatars,
    this.maxDisplay = 3,
    this.avatarSize = 28,
    this.overlap = 0.35,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) {
      return Text(
        '참여자 없음',
        style: TextStyle(
          color: AppColors.grayMedium,
          fontSize: avatarSize * 0.43,
        ),
      );
    }

    final displayCount = avatars.length > maxDisplay ? maxDisplay : avatars.length;
    final remainingCount = avatars.length - displayCount;
    final overlapPixels = avatarSize * (1 - overlap);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: overlapPixels * displayCount + (remainingCount > 0 ? overlapPixels : 0),
          height: avatarSize,
          child: Stack(
            children: [
              ...List.generate(displayCount, (index) {
                final avatar = avatars[index];
                return Positioned(
                  left: index * overlapPixels,
                  child: _buildAvatar(avatar),
                );
              }),
              if (remainingCount > 0)
                Positioned(
                  left: displayCount * overlapPixels,
                  child: _buildRemainingCount(remainingCount),
                ),
            ],
          ),
        ),
        if (showCount) ...[
          const SizedBox(width: 8),
          Text(
            '${avatars.length}명',
            style: TextStyle(
              color: AppColors.grayMedium,
              fontSize: avatarSize * 0.43,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar(AvatarData avatar) {
    final radius = avatarSize / 2;
    final fontSize = avatarSize * 0.43;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryBlue,
      backgroundImage:
          avatar.imageUrl != null ? NetworkImage(avatar.imageUrl!) : null,
      child: avatar.imageUrl == null
          ? Text(
              avatar.name.isNotEmpty ? avatar.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildRemainingCount(int count) {
    final radius = avatarSize / 2;
    final fontSize = avatarSize * 0.36;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.grayLight,
      child: Text(
        '+$count',
        style: TextStyle(
          color: AppColors.grayDark,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 단일 사용자 아바타
class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryBlue,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );

    Widget child = avatar;

    if (showBorder) {
      child = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? AppColors.primaryBlue,
            width: 2,
          ),
        ),
        child: avatar,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }

    return child;
  }
}
