import 'package:flutter/material.dart';
import '../tokens/ff_colors.dart';
import '../tokens/ff_typography.dart';
import '../tokens/ff_radius.dart';
import '../tokens/ff_spacing.dart';
import '../tokens/ff_shadows.dart';

class FFTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int? maxLength;

  const FFTextField({
    Key? key,
    required this.label,
    this.hint,
    this.helperText,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLength,
  }) : super(key: key);

  @override
  State<FFTextField> createState() => _FFTextFieldState();
}

class _FFTextFieldState extends State<FFTextField> {
  late FocusNode _focusNode;
  late bool _isFocused;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _isFocused = false;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: FFSpacing.sm),
            child: Text(
              widget.label,
              style: FFTypography.labelLg.copyWith(
                color: FFColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FFRadius.lg),
            boxShadow: _isFocused ? FFShadows.lg : FFShadows.sm,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            obscureText: widget.obscureText,
            maxLength: widget.maxLength,
            style: FFTypography.body.copyWith(
              color: FFColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helperText,
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: EdgeInsets.all(FFSpacing.md),
                      child: widget.prefixIcon,
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? Padding(
                      padding: EdgeInsets.all(FFSpacing.md),
                      child: widget.suffixIcon,
                    )
                  : null,
              filled: true,
              fillColor: _isFocused ? FFColors.backgroundLight : FFColors.backgroundDark,
              contentPadding: EdgeInsets.symmetric(
                horizontal: FFSpacing.lg,
                vertical: FFSpacing.md,
              ),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FFRadius.lg),
                borderSide: BorderSide(color: FFColors.border, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FFRadius.lg),
                borderSide: BorderSide(color: FFColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FFRadius.lg),
                borderSide: BorderSide(color: FFColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FFRadius.lg),
                borderSide: BorderSide(color: FFColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FFRadius.lg),
                borderSide: BorderSide(color: FFColors.error, width: 2),
              ),
              hintStyle: FFTypography.body.copyWith(color: FFColors.textTertiary),
              helperStyle: FFTypography.bodySm.copyWith(color: FFColors.textTertiary),
              errorStyle: FFTypography.bodySm.copyWith(color: FFColors.error),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
          ),
        ),
      ],
    );
  }
}
