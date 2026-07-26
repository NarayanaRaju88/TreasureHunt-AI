import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/difficulty_badge.dart';
import '../../treasure/models/treasure_model.dart';
import '../../treasure/providers/treasure_provider.dart';
import '../../gamification/providers/gamification_provider.dart';

/// Hero tag shared between the map/home cards and the discovery image.
const String kDiscoveryHeroTag = 'discovery-treasure-image';

/// Immersive treasure detail & discovery screen: a hero image, AI-generated
/// fun facts and story, nearby places, and a celebratory "Collect" flow with
/// confetti, an XP-gain animation and screenshot sharing.
class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final GlobalKey _shareBoundaryKey = GlobalKey();
  late final ConfettiController _confetti;

  bool _collected = false;
  bool _collecting = false;
  bool _sharing = false;
  bool _showXpBurst = false;
  int _xpGained = 0;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _collect(TreasureModel treasure) async {
    if (_collected || _collecting) return;
    setState(() => _collecting = true);

    final history =
        await ref.read(treasureProvider.notifier).collectTreasure(treasure);
    final xp = treasure.effectiveXpReward;
    await ref.read(gamificationProvider.notifier).awardXp(xp);

    if (!mounted) return;
    setState(() {
      _collecting = false;
      _collected = true;
      _xpGained = history?.xpEarned ?? xp;
      _showXpBurst = true;
    });
    _confetti.play();

    // Auto-hide the XP burst after its animation completes.
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showXpBurst = false);
    });
  }

  Future<void> _shareScreenshot(TreasureModel treasure) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _shareBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Nothing to capture');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Capture failed');
      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/treasure_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: 'I just discovered "${treasure.title}" on AI Treasure Hunt! '
            '🏆 +${treasure.effectiveXpReward} XP',
      );
    } catch (_) {
      if (mounted) {
        context.showSnackBar('Could not share screenshot', isError: true);
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(dailyTreasureProvider);

    return Scaffold(
      body: daily.when(
        loading: () => const _DiscoveryLoading(),
        error: (e, _) => _DiscoveryError(
          message: 'Could not load treasure details.',
          onRetry: () => setState(() {}),
        ),
        data: (treasure) {
          if (treasure == null) {
            return const _DiscoveryEmpty();
          }
          return Stack(
            children: <Widget>[
              RepaintBoundary(
                key: _shareBoundaryKey,
                child: _DiscoveryContent(
                  treasure: treasure,
                  collected: _collected,
                  collecting: _collecting,
                  sharing: _sharing,
                  onCollect: () => _collect(treasure),
                  onShare: () => _shareScreenshot(treasure),
                ),
              ),

              // Confetti celebration overlay.
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 30,
                  maxBlastForce: 22,
                  minBlastForce: 8,
                  gravity: 0.28,
                  emissionFrequency: 0.05,
                  colors: const <Color>[
                    AppColors.primary,
                    AppColors.accent,
                    AppColors.secondary,
                    AppColors.gold,
                    AppColors.legendary,
                  ],
                ),
              ),

              // XP-gain burst animation.
              if (_showXpBurst)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(child: _XpBurst(xp: _xpGained)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// Main scrollable content
// =============================================================================
class _DiscoveryContent extends StatelessWidget {
  const _DiscoveryContent({
    required this.treasure,
    required this.collected,
    required this.collecting,
    required this.sharing,
    required this.onCollect,
    required this.onShare,
  });

  final TreasureModel treasure;
  final bool collected;
  final bool collecting;
  final bool sharing;
  final VoidCallback onCollect;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: treasure.category.color,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: _HeroImage(treasure: treasure),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _BadgesRow(treasure: treasure),
                const SizedBox(height: 16),
                Text(
                  treasure.title,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  treasure.description,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _FunFactsSection(facts: treasure.funFacts),
                const SizedBox(height: 20),
                if (treasure.hasStory) ...<Widget>[
                  _StorySection(story: treasure.aiStory!),
                  const SizedBox(height: 20),
                ],
                if (treasure.nearbyRecommendations.isNotEmpty) ...<Widget>[
                  _NearbySection(places: treasure.nearbyRecommendations),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24 + context.padding.bottom,
            ),
            child: _ActionButtons(
              treasure: treasure,
              collected: collected,
              collecting: collecting,
              sharing: sharing,
              onCollect: onCollect,
              onShare: onShare,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Hero image (with gradient placeholder fallback)
// =============================================================================
class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.treasure});

  final TreasureModel treasure;

  @override
  Widget build(BuildContext context) {
    final gradientPlaceholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            treasure.category.color,
            treasure.category.color.withValues(alpha: 0.55),
            AppColors.primary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          treasure.category.icon,
          size: 96,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );

    return Hero(
      tag: kDiscoveryHeroTag,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (treasure.hasImage)
            CachedNetworkImage(
              imageUrl: treasure.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => gradientPlaceholder,
              errorWidget: (_, __, ___) => gradientPlaceholder,
            )
          else
            gradientPlaceholder,
          // Bottom scrim for legibility.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Category / difficulty / XP badges
// =============================================================================
class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.treasure});

  final TreasureModel treasure;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: treasure.category.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(treasure.category.icon,
                  size: 16, color: treasure.category.color),
              const SizedBox(width: 6),
              Text(
                treasure.category.displayName,
                style: TextStyle(
                  color: treasure.category.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        DifficultyBadge(difficulty: treasure.difficulty),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.bolt_rounded,
                  size: 16, color: AppColors.onAccent),
              const SizedBox(width: 4),
              Text(
                '+${treasure.effectiveXpReward} XP',
                style: const TextStyle(
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        if (treasure.isRare)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.legendary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.legendary.withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.auto_awesome_rounded,
                    size: 16, color: AppColors.legendary),
                SizedBox(width: 4),
                Text(
                  'Rare',
                  style: TextStyle(
                    color: AppColors.legendary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Fun Facts (expandable)
// =============================================================================
class _FunFactsSection extends StatelessWidget {
  const _FunFactsSection({required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final displayFacts = facts.isNotEmpty
        ? facts.take(3).toList()
        : const <String>[
            'This spot has a story waiting to be uncovered.',
            'Explore a little further to reveal hidden details.',
            'Every discovery adds to your explorer journal.',
          ];

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const Icon(Icons.lightbulb_rounded,
              color: AppColors.accentDark),
          title: Text(
            'Fun Facts',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          children: <Widget>[
            for (int i = 0; i < displayFacts.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: AppColors.onAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayFacts[i],
                        style: context.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// The Story (italic narrative)
// =============================================================================
class _StorySection extends StatelessWidget {
  const _StorySection({required this.story});

  final String story;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.auto_stories_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'The Story',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
          child: Text(
            story,
            style: context.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.55,
              color: context.colors.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Nearby places (horizontal chips)
// =============================================================================
class _NearbySection extends StatelessWidget {
  const _NearbySection({required this.places});

  final List<String> places;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.place_rounded,
                size: 20, color: AppColors.secondary),
            const SizedBox(width: 8),
            Text(
              'Nearby Places',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.near_me_rounded,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      places[i],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Action buttons (Collect + Share)
// =============================================================================
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.treasure,
    required this.collected,
    required this.collecting,
    required this.sharing,
    required this.onCollect,
    required this.onShare,
  });

  final TreasureModel treasure;
  final bool collected;
  final bool collecting;
  final bool sharing;
  final VoidCallback onCollect;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Animated collect button — scales/updates its label on collection.
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: collected
                ? const LinearGradient(
                    colors: <Color>[AppColors.success, AppColors.success],
                  )
                : AppColors.accentGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: (collected ? AppColors.success : AppColors.accent)
                    .withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: (collected || collecting) ? null : onCollect,
              child: Center(
                child: collecting
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.onAccent),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            collected
                                ? Icons.check_circle_rounded
                                : Icons.emoji_events_rounded,
                            color: AppColors.onAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            collected ? 'Treasure Collected!' : 'Collect Treasure',
                            style: const TextStyle(
                              color: AppColors.onAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: sharing ? null : onShare,
            icon: sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
            label: Text(
              sharing ? 'Preparing…' : 'Share Screenshot',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// XP-gain burst animation
// =============================================================================
class _XpBurst extends StatefulWidget {
  const _XpBurst({required this.xp});

  final int xp;

  @override
  State<_XpBurst> createState() => _XpBurstState();
}

class _XpBurstState extends State<_XpBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _rise;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 60,
      ),
    ]).animate(_controller);
    _rise = Tween<double>(begin: 0, end: -70).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _fade = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 30),
    ]).animate(_controller);
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
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _rise.value),
            child: Transform.scale(scale: _scale.value, child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.55),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.bolt_rounded,
                color: AppColors.onAccent, size: 40),
            const SizedBox(height: 4),
            Text(
              '+${AppUtils.formatNumber(widget.xp)} XP',
              style: const TextStyle(
                color: AppColors.onAccent,
                fontWeight: FontWeight.w900,
                fontSize: 28,
              ),
            ),
            const Text(
              'Nice find!',
              style: TextStyle(
                color: AppColors.onAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Loading / error / empty states
// =============================================================================
class _DiscoveryLoading extends StatelessWidget {
  const _DiscoveryLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Uncovering your treasure…',
            style: context.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryError extends StatelessWidget {
  const _DiscoveryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryEmpty extends StatelessWidget {
  const _DiscoveryEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Transform.rotate(
              angle: -math.pi / 12,
              child: const Icon(Icons.travel_explore_rounded,
                  size: 72, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No treasure yet',
              style: context.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Head to the map to reveal your daily treasure!',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
