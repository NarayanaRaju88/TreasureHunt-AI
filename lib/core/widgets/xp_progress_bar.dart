import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';

/// An animated XP progress bar with an optional glowing effect and level
/// indicators on either end.
///
/// [progress] must be in the range [0, 1]. The fill animates smoothly whenever
/// [progress] changes.
class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.progress,
    this.level,
    this.nextLevel,
    this.label,
    this.height = 14,
    this.showLevelBadges = true,
    this.glow = true,
    this.animationDuration = const Duration(milliseconds: 900),
  });

  final double progress;
  final int? level;
  final int? nextLevel;

  /// Optional caption shown above the bar (e.g. "120 / 300 XP").
  final String? label;
  final double height;
  final bool showLevelBadges;
  final bool glow;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                label!,
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '${(clamped * 100).round()}%',
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: <Widget>[
            if (showLevelBadges && level != null) ...<Widget>[
              _LevelDot(level: level!),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    height: height,
                    child: Stack(
                      children: <Widget>[
                        // Track
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.xpBarTrack.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(height),
                          ),
                        ),
                        // Animated fill
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: clamped),
                          duration: animationDuration,
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value <= 0 ? 0.001 : value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: <Color>[
                                      AppColors.accentLight,
                                      AppColors.accent,
                                      AppColors.accentDark,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(height),
                                  boxShadow: glow
                                      ? <BoxShadow>[
                                          BoxShadow(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.6),
                                            blurRadius: 10,
                                            spreadRadius: 0.5,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 3),
                                    child: value > 0.08
                                        ? Container(
                                            width: height * 0.42,
                                            height: height * 0.42,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (showLevelBadges && nextLevel != null) ...<Widget>[
              const SizedBox(width: 8),
              _LevelDot(level: nextLevel!, muted: true),
            ],
          ],
        ),
      ],
    );
  }
}

class _LevelDot extends StatelessWidget {
  const _LevelDot({required this.level, this.muted = false});

  final int level;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        gradient: muted ? null : AppColors.accentGradient,
        color: muted ? AppColors.xpBarTrack.withValues(alpha: 0.5) : null,
        shape: BoxShape.circle,
        border: Border.all(
          color: muted
              ? Colors.white.withValues(alpha: 0.3)
              : AppColors.accentDark,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: muted ? Colors.white.withValues(alpha: 0.85) : AppColors.onAccent,
        ),
      ),
    );
  }
}
