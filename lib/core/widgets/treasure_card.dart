import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../features/treasure/models/treasure_model.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../utils/app_utils.dart';
import 'category_icon.dart';
import 'difficulty_badge.dart';

/// A reusable treasure card with glassmorphism, category coloring and an
/// animated gradient border for rare treasures.
///
/// Two layouts are supported:
///  * [TreasureCard] — a compact card suited for lists/grids.
///  * [TreasureCard.large] — a hero card for the home dashboard.
class TreasureCard extends StatefulWidget {
  const TreasureCard({
    super.key,
    required this.treasure,
    this.onTap,
    this.large = false,
    this.showShimmer = true,
    this.heroTag,
  });

  /// Convenience constructor for the large hero variant.
  const TreasureCard.large({
    super.key,
    required this.treasure,
    this.onTap,
    this.showShimmer = true,
    this.heroTag,
  }) : large = true;

  final TreasureModel treasure;
  final VoidCallback? onTap;
  final bool large;

  /// Animate a subtle sheen sweep across the image (used for the daily card).
  final bool showShimmer;
  final String? heroTag;

  @override
  State<TreasureCard> createState() => _TreasureCardState();
}

class _TreasureCardState extends State<TreasureCard>
    with TickerProviderStateMixin {
  late final AnimationController _borderController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.showShimmer) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _borderController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.treasure;
    final radius = BorderRadius.circular(widget.large ? 28 : 20);

    Widget card = _buildCardBody(context);

    // Rare treasures get an animated gradient border.
    if (t.isRare) {
      card = AnimatedBuilder(
        animation: _borderController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: SweepGradient(
                transform:
                    GradientRotation(_borderController.value * 6.2831853),
                colors: const <Color>[
                  AppColors.legendary,
                  AppColors.accent,
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.legendary,
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.legendary.withValues(alpha: 0.4),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          );
        },
        child: card,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: radius,
        child: card,
      ),
    );
  }

  Widget _buildCardBody(BuildContext context) {
    final t = widget.treasure;
    final radius = BorderRadius.circular(widget.large ? 26 : 18);
    final double imageHeight = widget.large ? 200 : 130;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: context.isDarkMode
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        border: t.isRare
            ? null
            : Border.all(
                color: t.category.color.withValues(alpha: 0.3),
                width: 1.2,
              ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: t.category.color.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildImage(context, imageHeight),
          Padding(
            padding: EdgeInsets.all(widget.large ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CategoryIcon(
                      category: t.category,
                      size: widget.large ? 40 : 32,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (widget.large
                                    ? context.textTheme.titleLarge
                                    : context.textTheme.titleMedium)
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            t.category.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: t.category.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.large) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    t.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    DifficultyBadge(difficulty: t.difficulty, compact: !widget.large),
                    _InfoPill(
                      icon: Icons.place_rounded,
                      label: AppUtils.formatDistance(t.distance),
                      color: AppColors.info,
                    ),
                    if (t.estimatedWalkingMinutes > 0)
                      _InfoPill(
                        icon: Icons.directions_walk_rounded,
                        label: '${t.estimatedWalkingMinutes} min',
                        color: AppColors.secondary,
                      ),
                    _InfoPill(
                      icon: Icons.stars_rounded,
                      label: '+${t.effectiveXpReward} XP',
                      color: AppColors.accentDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, double height) {
    final t = widget.treasure;

    Widget imageLayer;
    if (t.hasImage) {
      imageLayer = CachedNetworkImage(
        imageUrl: t.imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => _fallback(context, loading: true),
        errorWidget: (context, url, error) => _fallback(context),
      );
    } else {
      imageLayer = _fallback(context);
    }

    Widget hero = widget.heroTag != null
        ? Hero(tag: widget.heroTag!, child: imageLayer)
        : imageLayer;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          hero,
          // Gradient scrim for legibility.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.transparent, Color(0x66000000)],
              ),
            ),
          ),
          // Animated sheen sweep.
          if (widget.showShimmer)
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, _) {
                return FractionallySizedBox(
                  widthFactor: 1,
                  child: ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (rect) {
                      final double v = _shimmerController.value;
                      return LinearGradient(
                        begin: Alignment(-1 + 2 * v - 0.3, -0.3),
                        end: Alignment(-1 + 2 * v + 0.3, 0.3),
                        colors: const <Color>[
                          Colors.transparent,
                          Color(0x33FFFFFF),
                          Colors.transparent,
                        ],
                      ).createShader(rect);
                    },
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          // Rare ribbon.
          if (t.isRare)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.legendary, Color(0xFF7C4DFF)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.legendary.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(Icons.auto_awesome_rounded,
                        size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'RARE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Collected check.
          if (t.isCollected)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback(BuildContext context, {bool loading = false}) {
    final t = widget.treasure;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            t.category.color.withValues(alpha: 0.85),
            t.category.color.withValues(alpha: 0.45),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(
              t.category.icon,
              size: 54,
              color: Colors.white.withValues(alpha: 0.9),
            ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
