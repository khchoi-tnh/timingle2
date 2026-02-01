import 'package:flutter/material.dart';
import '../tokens/ff_colors.dart';
import '../tokens/ff_typography.dart';
import '../tokens/ff_radius.dart';
import '../tokens/ff_spacing.dart';
import '../tokens/ff_shadows.dart';

class FFPasswordField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const FFPasswordField({
    Key? key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
  }) : super(key: key);

  @override
  State<FFPasswordField> createState() => _FFPasswordFieldState();
}

class _FFPasswordFieldState extends State<FFPasswordField> {
  late FocusNode _focusNode;
  bool _showPassword = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
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
            obscureText: !_showPassword,
            validator: widget.validator,
            style: FFTypography.body.copyWith(
              color: FFColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              filled: true,
              fillColor: _isFocused ? FFColors.backgroundLight : FFColors.backgroundDark,
              contentPadding: EdgeInsets.symmetric(
                horizontal: FFSpacing.lg,
                vertical: FFSpacing.md,
              ),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _showPassword = !_showPassword),
                child: Padding(
                  padding: EdgeInsets.all(FFSpacing.md),
                  child: Icon(
                    _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: FFColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
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
              errorStyle: FFTypography.bodySm.copyWith(color: FFColors.error),
            ),
          ),
        ),
      ],
    );
  }
}
