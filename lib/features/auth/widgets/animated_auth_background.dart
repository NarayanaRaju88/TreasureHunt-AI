import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A subtly animated gradient background with drifting translucent blobs,
/// used behind the authentication screens.
class AnimatedAuthBackground extends StatefulWidget {
  const AnimatedAuthBackground({super.key});

  @override
  State<AnimatedAuthBackground> createState() => _AnimatedAuthBackgroundState();
}

class _AnimatedAuthBackgroundState extends State<AnimatedAuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double t = _controller.value * 2 * math.pi;
        return DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Stack(
            children: <Widget>[
              _blob(
                dx: 0.2 + 0.1 * math.sin(t),
                dy: 0.15 + 0.08 * math.cos(t),
                size: 220,
                color: AppColors.accent.withValues(alpha: 0.35),
                context: context,
              ),
              _blob(
                dx: 0.8 + 0.1 * math.cos(t * 0.8),
                dy: 0.3 + 0.1 * math.sin(t * 1.2),
                size: 180,
                color: AppColors.secondary.withValues(alpha: 0.3),
                context: context,
              ),
              _blob(
                dx: 0.5 + 0.15 * math.sin(t * 1.5),
                dy: 0.85 + 0.06 * math.cos(t),
                size: 260,
                color: AppColors.tertiary.withValues(alpha: 0.28),
                context: context,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _blob({
    required double dx,
    required double dy,
    required double size,
    required Color color,
    required BuildContext context,
  }) {
    final Size screen = MediaQuery.sizeOf(context);
    return Positioned(
      left: dx * screen.width - size / 2,
      top: dy * screen.height - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
