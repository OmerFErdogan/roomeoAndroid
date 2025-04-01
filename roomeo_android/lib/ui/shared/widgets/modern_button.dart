// lib/ui/shared/widgets/modern_button.dart
import 'package:flutter/material.dart';
import '../styles/modern_theme.dart';

enum ModernButtonType {
  primary,
  secondary,
  outline,
  text,
  success,
  warning,
  error,
}

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // null olabilir
  final IconData? icon;
  final bool isLoading;
  final ModernButtonType type;
  final double? width;
  final bool isDisabled;
  final EdgeInsetsGeometry? padding;
  final double? iconSize;
  final bool iconOnRight;

  const ModernButton({
    Key? key,
    required this.text,
    required this.onPressed, // null olabilir
    this.icon,
    this.isLoading = false,
    this.type = ModernButtonType.primary,
    this.width,
    this.isDisabled = false,
    this.padding,
    this.iconSize,
    this.iconOnRight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Buton içeriği
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !iconOnRight) ...[
          Icon(icon, size: iconSize ?? 20),
          SizedBox(width: 8),
        ],
        Text(
          text,
          style: ModernTheme.buttonTextStyle,
        ),
        if (icon != null && iconOnRight) ...[
          SizedBox(width: 8),
          Icon(icon, size: iconSize ?? 20),
        ],
      ],
    );

    // Yükleniyor durumu
    if (isLoading) {
      buttonContent = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
        ),
      );
    }

    // Buton devre dışı mı yükleniyor mu kontrol et
    final bool buttonDisabled = isDisabled || isLoading || onPressed == null;

    // Buton tipine göre tasarım
    switch (type) {
      case ModernButtonType.primary:
        return _buildElevatedButton(buttonContent,
            color: null, disabled: buttonDisabled);
      case ModernButtonType.secondary:
        return _buildSecondaryButton(buttonContent, disabled: buttonDisabled);
      case ModernButtonType.outline:
        return _buildOutlinedButton(buttonContent, disabled: buttonDisabled);
      case ModernButtonType.text:
        return _buildTextButton(buttonContent, disabled: buttonDisabled);
      case ModernButtonType.success:
        return _buildElevatedButton(buttonContent,
            color: ModernTheme.success, disabled: buttonDisabled);
      case ModernButtonType.warning:
        return _buildElevatedButton(buttonContent,
            color: ModernTheme.warning, disabled: buttonDisabled);
      case ModernButtonType.error:
        return _buildElevatedButton(buttonContent,
            color: ModernTheme.error, disabled: buttonDisabled);
    }
  }

  Widget _buildElevatedButton(Widget child,
      {Color? color, required bool disabled}) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? ModernTheme.primary,
          disabledBackgroundColor:
              (color ?? ModernTheme.primary).withOpacity(0.5),
          foregroundColor: Colors.white,
          padding:
              padding ?? EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
          ),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }

  Widget _buildSecondaryButton(Widget child, {required bool disabled}) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[100],
          foregroundColor: ModernTheme.primary,
          padding:
              padding ?? EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
            side: BorderSide(
              color: disabled ? Colors.grey[300]! : ModernTheme.primary,
              width: 1.5,
            ),
          ),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }

  Widget _buildOutlinedButton(Widget child, {required bool disabled}) {
    return SizedBox(
      width: width,
      child: OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ModernTheme.primary,
          side: BorderSide(
            color: disabled ? Colors.grey[300]! : ModernTheme.primary,
            width: 1.5,
          ),
          padding:
              padding ?? EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildTextButton(Widget child, {required bool disabled}) {
    return SizedBox(
      width: width,
      child: TextButton(
        onPressed: disabled ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: ModernTheme.primary,
          padding: padding ?? EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }

  Color _getTextColor() {
    switch (type) {
      case ModernButtonType.primary:
      case ModernButtonType.success:
      case ModernButtonType.warning:
      case ModernButtonType.error:
        return Colors.white;
      case ModernButtonType.secondary:
      case ModernButtonType.outline:
      case ModernButtonType.text:
        return ModernTheme.primary;
    }
  }
}
