import 'package:flutter/material.dart';

/// A gentle breathing fade animation that replaces shimmer effects.
/// Suitable for loading placeholders in nature‑themed apps.
class FadePulse extends StatefulWidget {
  final Widget child;
  const FadePulse({super.key, required this.child});

  @override
  State<FadePulse> createState() => _FadePulseState();
}

class _FadePulseState extends State<FadePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: widget.child,
      ),
    );
  }
}