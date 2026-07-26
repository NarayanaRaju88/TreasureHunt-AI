import 'package:flutter/material.dart';

import '../../features/treasure/models/treasure_model.dart';
import '../theme/app_colors.dart';

/// A small colored pill showing a treasure's difficulty (Easy/Medium/Hard).
///
/// Colors follow a semantic scale: green (easy), amber (medium), red (hard).
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.compact = false,
    this.showIcon = true,
  });

  final TreasureDifficulty difficulty;

  /// When true renders a tighter chip (used inside dense cards).
  final bool compact;
  final bool showIcon;

  Color get _color {
    switch (difficulty) {
      case TreasureDifficulty.easy:
        return AppColors.success;
      case TreasureDifficulty.medium:
        return AppColors.warning;
      case TreasureDifficulty.hard:
        return AppColors.error;
    }
  }

  IconData get _icon {
    switch (difficulty) {
      case TreasureDifficulty.easy:
        return Icons.sentiment_satisfied_rounded;
      case TreasureDifficulty.medium:
        return Icons.local_fire_department_rounded;
      case TreasureDifficulty.hard:
        return Icons.bolt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showIcon) ...<Widget>[
            Icon(_icon, size: compact ? 12 : 14, color: color),
            SizedBox(width: compact ? 3 : 5),
          ],
          Text(
            difficulty.displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
