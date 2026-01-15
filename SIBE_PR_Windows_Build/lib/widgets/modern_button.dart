import 'package:flutter/material.dart';
import '../app/theme/app_theme.dart';

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? elevation;
  final bool isLoading;
  final bool enableAnimation;
  final Duration? animationDuration;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.elevation,
    this.isLoading = false,
    this.enableAnimation = true,
    this.animationDuration,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableAnimation) {
      _controller = AnimationController(
        duration: widget.animationDuration ?? AppTheme.fastAnimation,
        vsync: this,
      );
      
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: AppTheme.easeInOutCurve,
      ));
    }
  }

  @override
  void dispose() {
    if (widget.enableAnimation) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading && widget.enableAnimation) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _onTapEnd();
  }

  void _onTapCancel() {
    _onTapEnd();
  }

  void _onTapEnd() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      if (widget.enableAnimation) {
        _controller.reverse();
      }
      if (widget.onPressed != null && !widget.isLoading) {
        widget.onPressed!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    Color backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    Color foregroundColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;
    
    if (!isEnabled) {
      backgroundColor = theme.disabledColor;
      foregroundColor = theme.disabledColor;
    }

    Widget buttonContent = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          );

    Widget button = ElevatedButton(
      onPressed: isEnabled ? widget.onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: widget.elevation ?? 2.0,
        shadowColor: backgroundColor.withOpacity(0.3),
        padding: widget.padding ?? EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? 12,
          ),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: buttonContent,
    );

    if (widget.enableAnimation && !widget.isLoading) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              behavior: HitTestBehavior.opaque,
              child: button,
            ),
          );
        },
      );
    }

    return button;
  }
}


