import 'dart:ui';

import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// A reusable frosted-glass ("glassmorphism") container.
///
/// Wraps [child] in a [BackdropFilter] blur with a translucent tint, subtle
/// border and soft shadow. All visual tokens default to the app's
/// [GlassmorphismTheme] but can be overridden per-instance.
class GlassmorphicContainer extends StatelessWidget {
  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.blur,
    this.tint,
    this.borderColor,
    this.borderWidth = 1.2,
    this.gradient,
    this.boxShadow,
    this.alignment,
    this.onTap,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final double? blur;
  final Color? tint;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry? alignment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = borderRadius ??
        BorderRadius.circular(glass.borderRadius);
    final effectiveBlur = blur ?? glass.blurSigma;
    final effectiveTint = tint ?? glass.tint;

    Widget content = ClipRRect(
      borderRadius: radius is BorderRadius
          ? radius
          : BorderRadius.circular(glass.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          alignment: alignment,
          decoration: BoxDecoration(
            color: gradient == null ? effectiveTint : null,
            gradient: gradient,
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? glass.borderColor,
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radius is BorderRadius
            ? radius
            : BorderRadius.circular(glass.borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius is BorderRadius
              ? radius
              : BorderRadius.circular(glass.borderRadius),
          child: content,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ??
            <BoxShadow>[
              BoxShadow(
                color: glass.shadowColor,
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
      ),
      child: content,
    );
  }
}
