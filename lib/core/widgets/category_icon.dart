import 'package:flutter/material.dart';

import '../../features/treasure/models/treasure_category.dart';

/// A circular / rounded icon badge representing a [TreasureCategory].
///
/// Uses the category's own [TreasureCategoryX.color] and [TreasureCategoryX.icon]
/// to render a tinted background with the icon in the category color.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 44,
    this.iconSize,
    this.shape = BoxShape.circle,
    this.borderRadius = 14,
    this.showBorder = true,
    this.filled = false,
  });

  final TreasureCategory category;
  final double size;
  final double? iconSize;

  /// Whether to render a circle or rounded rectangle background.
  final BoxShape shape;

  /// Corner radius when [shape] is [BoxShape.rectangle].
  final double borderRadius;

  final bool showBorder;

  /// When true the background is a solid category color and the icon is white.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    final Color bg = filled ? color : color.withValues(alpha: 0.16);
    final Color fg = filled ? Colors.white : color;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(borderRadius) : null,
        border: showBorder && !filled
            ? Border.all(color: color.withValues(alpha: 0.35), width: 1.2)
            : null,
        boxShadow: filled
            ? <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Icon(
        category.icon,
        color: fg,
        size: iconSize ?? size * 0.52,
      ),
    );
  }
}
