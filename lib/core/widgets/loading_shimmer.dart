import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../extensions/context_extensions.dart';

/// Skeleton loading widgets built on top of the `shimmer` package.
///
/// Provides a reusable [LoadingShimmer] wrapper plus ready-made skeletons for
/// treasure cards and list rows so screens can show a polished loading state.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool dark = context.isDarkMode;
    return Shimmer.fromColors(
      baseColor: dark ? Colors.white10 : Colors.black.withValues(alpha: 0.07),
      highlightColor:
          dark ? Colors.white24 : Colors.black.withValues(alpha: 0.03),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// A single shimmer "bone" — a rounded rectangle placeholder.
class ShimmerBone extends StatelessWidget {
  const ShimmerBone({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: shape == BoxShape.circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(radius) : null,
      ),
    );
  }
}

/// Skeleton placeholder mimicking a large treasure card.
class TreasureCardSkeleton extends StatelessWidget {
  const TreasureCardSkeleton({super.key, this.height = 320});

  final double height;

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ShimmerBone(width: double.infinity, radius: 18, height: height),
            ),
            const SizedBox(height: 14),
            const ShimmerBone(width: 160, height: 18),
            const SizedBox(height: 10),
            const ShimmerBone(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            const ShimmerBone(width: 220, height: 12),
            const SizedBox(height: 14),
            Row(
              children: const <Widget>[
                ShimmerBone(width: 70, height: 26, radius: 999),
                SizedBox(width: 8),
                ShimmerBone(width: 70, height: 26, radius: 999),
                SizedBox(width: 8),
                ShimmerBone(width: 70, height: 26, radius: 999),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder for a compact list row (avatar + two lines).
class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            const ShimmerBone(height: 52, shape: BoxShape.circle),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  ShimmerBone(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  ShimmerBone(width: 140, height: 12),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const ShimmerBone(width: 44, height: 24, radius: 999),
          ],
        ),
      ),
    );
  }
}

/// A vertical list of [ListTileSkeleton]s.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(
        itemCount,
        (_) => const ListTileSkeleton(),
      ),
    );
  }
}
