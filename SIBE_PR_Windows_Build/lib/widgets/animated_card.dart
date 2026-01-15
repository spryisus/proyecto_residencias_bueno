import 'package:flutter/material.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Duration? animationDuration;
  final bool enableHover;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.color,
    this.elevation = 2,
    this.borderRadius,
    this.animationDuration,
    this.enableHover = true,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
        curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) + 4.0,
    ).animate(CurvedAnimation(
      parent: _controller,
        curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
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
      _controller.reverse();
      if (widget.onTap != null) {
        // Pequeño delay para que se vea la animación
        Future.delayed(const Duration(milliseconds: 50), () {
          widget.onTap!();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: _elevationAnimation.value,
            color: widget.color ?? Theme.of(context).cardColor,
            shadowColor: Theme.of(context).shadowColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: widget.padding!,
                child: GestureDetector(
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  behavior: HitTestBehavior.opaque,
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
