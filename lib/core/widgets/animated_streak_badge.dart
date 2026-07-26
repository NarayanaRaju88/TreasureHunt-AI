import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A daily-streak counter badge with an animated fire emoji and a pulsing glow.
///
/// The flame gently flickers (scale + rotation) and the surrounding glow
/// pulses to draw attention to the user's active streak.
class AnimatedStreakBadge extends StatefulWidget {
  const AnimatedStreakBadge({
    super.key,
    required this.streak,
    this.compact = false,
    this.onTap,
  });

  final int streak;
  final bool compact;
  final VoidCallback? onTap;

  @override
  State<AnimatedStreakBadge> createState() => _AnimatedStreakBadgeState();
}

class _AnimatedStreakBadgeState extends State<AnimatedStreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.streak > 0;
    final double h = widget.compact ? 34 : 42;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double t = _controller.value;
          final double glow = active ? (0.35 + 0.35 * t) : 0.0;
          return Container(
            height: h,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
            ),
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      colors: <Color>[Color(0xFFFF8A65), Color(0xFFFF5722)],
                    )
                  : null,
              color: active ? null : AppColors.grey400.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(999),
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFFFF5722).withValues(alpha: glow),
                        blurRadius: 16 + 8 * t,
                        spreadRadius: 1 + t,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Transform.rotate(
                  angle: active ? math.sin(t * math.pi * 2) * 0.12 : 0,
                  child: Transform.scale(
                    scale: active ? 1.0 + 0.14 * t : 1.0,
                    child: Text(
                      '🔥',
                      style: TextStyle(fontSize: widget.compact ? 15 : 18),
                    ),
                  ),
                ),
                SizedBox(width: widget.compact ? 4 : 6),
                Text(
                  '${widget.streak}',
                  style: TextStyle(
                    fontSize: widget.compact ? 14 : 17,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : AppColors.grey600,
                  ),
                ),
                if (!widget.compact) ...<Widget>[
                  const SizedBox(width: 4),
                  Text(
                    widget.streak == 1 ? 'day' : 'days',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.grey600,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
