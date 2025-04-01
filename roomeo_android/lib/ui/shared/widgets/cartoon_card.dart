// lib/ui/shared/widgets/cartoon_card.dart
import 'package:flutter/material.dart';
import '../styles/cartoon_theme.dart';

class CartoonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final bool hasShadow;
  final double borderRadius;
  final VoidCallback? onTap;
  final BorderSide? borderSide;

  const CartoonCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = CartoonTheme.cardColor,
    this.hasShadow = true,
    this.borderRadius = CartoonTheme.borderRadius,
    this.onTap,
    this.borderSide,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderSide?.color ?? Color(0xFF333333),
          width: borderSide?.width ?? 2,
        ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Color(0xFF333333).withOpacity(0.1),
                  offset: Offset(0, 3),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}
