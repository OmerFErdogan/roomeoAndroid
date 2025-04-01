// lib/ui/shared/widgets/modern_card.dart
import 'package:flutter/material.dart';
import '../styles/modern_theme.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final bool hasShadow;
  final double borderRadius;
  final VoidCallback? onTap;
  final BorderSide? borderSide;
  final Color? highlightColor;
  final Widget? header;
  final List<Widget>? footerActions;

  const ModernCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = Colors.white,
    this.hasShadow = true,
    this.borderRadius = ModernTheme.borderRadius,
    this.onTap,
    this.borderSide,
    this.highlightColor,
    this.header,
    this.footerActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: hasShadow ? ModernTheme.lightShadow : null,
        border: borderSide != null
            ? Border.all(
                color: borderSide!.color,
                width: borderSide!.width,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (highlightColor != null)
              Container(
                height: 6,
                color: highlightColor,
              ),
            if (header != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(
                    bottom: BorderSide(
                      color: ModernTheme.borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: header,
              ),
            Padding(
              padding: padding,
              child: child,
            ),
            if (footerActions != null && footerActions!.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ModernTheme.backgroundLight,
                  border: Border(
                    top: BorderSide(
                      color: ModernTheme.borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: footerActions!
                      .map((widget) => Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: widget,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
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
