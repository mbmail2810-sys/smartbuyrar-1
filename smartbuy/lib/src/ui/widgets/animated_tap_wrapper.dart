import 'package:flutter/material.dart';

class AnimatedTapWrapper extends StatefulWidget {
  const AnimatedTapWrapper({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.95,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;
  final Duration duration;

  @override
  State<AnimatedTapWrapper> createState() => _AnimatedTapWrapperState();
}

class _AnimatedTapWrapperState extends State<AnimatedTapWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _controller.forward();
  }

  void _onTapUp(_) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap, // Ensure onTap is still triggered for simple taps
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
