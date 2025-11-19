// lib/widgets/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? width;
  final double borderRadius;
  final bool isLoading;
  final IconData? icon;
  final double iconSize;
  final bool withShadow;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.height = 50,
    this.width,
    this.borderRadius = 16,
    this.isLoading = false,
    this.icon,
    this.iconSize = 20,
    this.withShadow = true,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultBg =
        widget.backgroundColor ?? Theme.of(context).colorScheme.primary;
    final defaultText =
        widget.textColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Theme.of(context).colorScheme.onPrimary);

    Widget child = Container(
      alignment: Alignment.center,
      height: widget.height,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.withShadow
            ? [
                BoxShadow(
                  color: defaultBg.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: widget.isLoading
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(defaultText),
              strokeWidth: 2,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null)
                  Icon(widget.icon, size: widget.iconSize, color: defaultText),
                if (widget.icon != null) const SizedBox(width: 8),
                Text(
                  widget.text,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: defaultText,
                  ),
                ),
              ],
            ),
    );

    return widget.onPressed == null
        ? Opacity(opacity: 0.5, child: child)
        : ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              onTap: widget.onPressed,
              child: child,
            ),
          );
  }
}
