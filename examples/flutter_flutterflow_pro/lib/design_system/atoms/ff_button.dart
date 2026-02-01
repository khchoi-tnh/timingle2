import 'package:flutter/material.dart';
import '../tokens/ff_colors.dart';
import '../tokens/ff_typography.dart';
import '../tokens/ff_radius.dart';
import '../tokens/ff_shadows.dart';
import '../tokens/ff_gradients.dart';

class FFButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;
  final bool useGradient;
  final IconData? iconLeft;
  final IconData? iconRight;

  const FFButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 50,
    this.backgroundColor,
    this.textColor,
    this.useGradient = true,
    this.iconLeft,
    this.iconRight,
  }) : super(key: key);

  @override
  State<FFButton> createState() => _FFButtonState();
}

class _FFButtonState extends State<FFButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? FFColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.useGradient ? FFGradients.primary : null,
            color: widget.useGradient ? null : bgColor,
            borderRadius: BorderRadius.circular(FFRadius.lg),
            boxShadow: _isHovered ? FFShadows.lg : FFShadows.md,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(FFRadius.lg),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.textColor ?? FFColors.textInverse,
                          ),
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.iconLeft != null) ...[
                            Icon(
                              widget.iconLeft,
                              color: widget.textColor ?? FFColors.textInverse,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: FFTypography.labelLg.copyWith(
                              color: widget.textColor ?? FFColors.textInverse,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.iconRight != null) ...[
                            SizedBox(width: 8),
                            Icon(
                              widget.iconRight,
                              color: widget.textColor ?? FFColors.textInverse,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FFTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? textColor;
  final IconData? icon;

  const FFTextButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.textColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? FFColors.primary,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor ?? FFColors.primary),
            SizedBox(width: 4),
          ],
          Text(
            label,
            style: FFTypography.labelLg.copyWith(
              color: textColor ?? FFColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
