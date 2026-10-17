import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Three bouncing dots for inline async feedback (buttons, cards, overlays).
class AppLoadingDots extends StatefulWidget {
  const AppLoadingDots({
    super.key,
    this.color,
    this.dotSize = 6,
    this.spacing = 5,
    this.bounce = 4,
  });

  final Color? color;
  final double dotSize;
  final double spacing;
  final double bounce;

  @override
  State<AppLoadingDots> createState() => _AppLoadingDotsState();
}

class _AppLoadingDotsState extends State<AppLoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.onPrimary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final wave = _controller.value * 2 * math.pi;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final offset = -widget.bounce * math.sin(wave + index * (2 * math.pi / 3));
            return Padding(
              padding: EdgeInsets.only(right: index < 2 ? widget.spacing : 0),
              child: Transform.translate(
                offset: Offset(0, offset),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class AsyncActionOverlay extends StatelessWidget {
  const AsyncActionOverlay({
    super.key,
    required this.active,
    required this.child,
    this.borderRadius,
  });

  final bool active;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (active)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: borderRadius ?? BorderRadius.circular(12),
              ),
              child: const Center(child: AppLoadingDots(color: Colors.white)),
            ),
          ),
      ],
    );
  }
}
