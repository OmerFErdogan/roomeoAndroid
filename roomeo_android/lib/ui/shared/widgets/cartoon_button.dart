// lib/ui/shared/widgets/cartoon_button.dart
import 'package:flutter/material.dart';
import '../styles/cartoon_theme.dart';

class CartoonButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final double width;
  final bool isOutlined;
  final bool isDisabled;

  const CartoonButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color = CartoonTheme.primary,
    this.textColor = Colors.white,
    this.width = double.infinity,
    this.isOutlined = false,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  _CartoonButtonState createState() => _CartoonButtonState();
}

class _CartoonButtonState extends State<CartoonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isDisabled) {
          _controller.forward();
        }
      },
      onTapUp: (_) {
        if (!widget.isDisabled) {
          _controller.reverse();
          widget.onPressed();
        }
      },
      onTapCancel: () {
        if (!widget.isDisabled) {
          _controller.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.width,
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? Colors.grey.shade300
                : (widget.isOutlined ? Colors.transparent : widget.color),
            borderRadius: BorderRadius.circular(CartoonTheme.borderRadius),
            border: Border.all(
              color:
                  widget.isDisabled ? Colors.grey.shade400 : Color(0xFF333333),
              width: 2,
            ),
            boxShadow: widget.isDisabled || widget.isOutlined
                ? null
                : [
                    BoxShadow(
                      color: Color(0xFF333333).withOpacity(0.2),
                      offset: Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.isDisabled
                          ? Colors.grey.shade600
                          : (widget.isOutlined
                              ? widget.color
                              : widget.textColor),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: CartoonTheme.buttonTextStyle.copyWith(
                      color: widget.isDisabled
                          ? Colors.grey.shade600
                          : (widget.isOutlined
                              ? widget.color
                              : widget.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
