import 'package:flutter/material.dart';

class AnimatedScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AnimatedScaleWidget({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<AnimatedScaleWidget> createState() => _AnimatedScaleWidgetState();
}

class _AnimatedScaleWidgetState extends State<AnimatedScaleWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _pressed ? 0.95 : 1.0,
        child: widget.child,
      ),
    );
  }
}
