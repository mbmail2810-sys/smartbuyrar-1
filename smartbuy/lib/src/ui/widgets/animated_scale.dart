import 'package:flutter/material.dart';

class PressableAnimatedScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableAnimatedScale({super.key, required this.child, this.onTap});

  @override
  State<PressableAnimatedScale> createState() => _PressableAnimatedScaleState();
}

class _PressableAnimatedScaleState extends State<PressableAnimatedScale> {
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
      child: Transform.scale(
        scale: _pressed ? 0.95 : 1.0,
        child: widget.child,
      ),
    );
  }
}
