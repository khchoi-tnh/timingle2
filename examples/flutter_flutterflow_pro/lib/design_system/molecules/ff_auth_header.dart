import 'package:flutter/material.dart';
import '../tokens/ff_colors.dart';
import '../tokens/ff_typography.dart';
import '../tokens/ff_spacing.dart';
import '../tokens/ff_radius.dart';
import '../tokens/ff_shadows.dart';
import '../tokens/ff_gradients.dart';

class FFAuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final bool showIcon;

  const FFAuthHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Container with gradient
        if (showIcon && icon != null)
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: FFGradients.primary,
                    borderRadius: BorderRadius.circular(FFRadius.lg),
                    boxShadow: FFShadows.lg,
                  ),
                  child: Icon(
                    icon,
                    size: 44,
                    color: FFColors.textInverse,
                  ),
                ),
              );
            },
          ),
        if (showIcon && icon != null) SizedBox(height: FFSpacing.xxl),

        // Title
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Text(
            title,
            style: FFTypography.heading1.copyWith(
              color: FFColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: FFSpacing.md),

        // Subtitle
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Text(
            subtitle,
            style: FFTypography.body.copyWith(
              color: FFColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
