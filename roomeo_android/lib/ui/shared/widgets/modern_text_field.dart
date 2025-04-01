// lib/ui/shared/widgets/modern_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/modern_theme.dart';

class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool isPassword;
  final TextInputType keyboardType;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? contentPadding;
  final BoxConstraints? constraints;
  final bool filled;
  final Color? fillColor;

  const ModernTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.prefixIcon,
    this.suffix,
    this.inputFormatters,
    this.autovalidateMode,
    this.contentPadding,
    this.constraints,
    this.filled = true,
    this.fillColor,
  }) : super(key: key);

  @override
  _ModernTextFieldState createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: widget.constraints,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 2),
              child: Text(
                widget.label,
                style: ModernTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
            focusNode: widget.focusNode,
            inputFormatters: widget.inputFormatters,
            autovalidateMode: widget.autovalidateMode,
            style: ModernTheme.bodyStyle,
            decoration: InputDecoration(
              hintText: widget.hintText,
              helperText: widget.helperText,
              errorText: widget.errorText,
              filled: widget.filled,
              fillColor: widget.fillColor ?? ModernTheme.backgroundLight,
              contentPadding: widget.contentPadding ?? EdgeInsets.all(16),
              prefixIcon:
                  widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: ModernTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : widget.suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
                borderSide: BorderSide(
                  color: ModernTheme.borderColor,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
                borderSide: BorderSide(
                  color: ModernTheme.borderColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
                borderSide: BorderSide(
                  color: ModernTheme.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
                borderSide: BorderSide(
                  color: ModernTheme.error,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
                borderSide: BorderSide(
                  color: ModernTheme.error,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
