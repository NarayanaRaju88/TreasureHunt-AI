import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/treasure_card.dart';
import '../../../core/widgets/xp_progress_bar.dart';
import '../../../core/widgets/animated_streak_badge.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../treasure/models/treasure_model.dart';
import '../../treasure/providers/treasure_provider.dart';

/// The main dashboard shown after sign-in.
///
/// Aggregates the daily treasure, gamification stats, weather and quick actions
/// into a single animated, pull-to-refresh scroll view.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Fallback coordinates (San Francisco) if device location is unavailable.
  static const double _fallbackLat = 37.7749;
  static const double _fallbackLng = -122.4194;

  double _lat = _fallbackLat;
  double _lng = _fallbackLng;

  WeatherModel? _weather;
  bool _weatherLoading = true;

  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickCountdown(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _resolveLocation();
    if (!mounted) return;
    // Register daily activity for streaks (best-effort).
    unawaited(ref.read(gamificationProvider.notifier).registerDailyActivity());
    await Future.wait<void>(<Future<void>>[
      _loadDaily(),
      _loadWeather(),
    ]);
  }

  Future<void> _resolveLocation() async {
    try {
      // getCurrentLocation() ensures permissions internally and throws a
      // LocationException if they are denied or the service is disabled.
      final service = ref.read(locationServiceProvider);
      final pos = await service.getCurrentLocation();
      _lat = pos.latitude;
      _lng = pos.longitude;
    } catch (_) {
      // Keep fallback coordinates.
    }
  }

  Future<void> _loadDaily() async {
    await ref
        .read(treasureProvider.notifier)
        .loadDailyTreasure(lat: _lat, lng: _lng);
  }

  Future<void> _loadWeather() async {
    setState(() => _weatherLoading = true);
    try {
      final service = ref.read(weatherServiceProvider);
      if (service.isConfigured) {
        final weather = await service.getCurrentWeather(_lat, _lng);
        if (mounted) setState(() => _weather = weather);
      }
    } catch (_) {
      // Ignore — weather widget will show a friendly placeholder.
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  void _tickCountdown() {
    final daily = ref.read(dailyTreasureProvider);
    final treasure = daily.asData?.value;
    if (treasure?.expiresAt == null) {
      if (_timeRemaining != Duration.zero) {
        setState(() => _timeRemaining = Duration.zero);
      }
      return;
    }
    final remaining = treasure!.expiresAt!.difference(DateTime.now());
    setState(() {
      _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  Future<void> _refresh() async {
    await _bootstrap();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).user;
    final daily = ref.watch(dailyTreasureProvider);

    return Scaffold(
      extendBody: true,
      floatingActionButton: _ExploreFab(
        onPressed: () => context.goNamed(AppRoutes.discovery),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverToBoxAdapter(child: _TopBar(user: user)),
              SliverToBoxAdapter(child: _GreetingSection(greeting: _greeting, user: user)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(child: _ProgressSection(user: user)),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: "Today's Treasure",
                  actionLabel: 'Refresh',
                  onAction: _loadDaily,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DailyTreasure(
                    daily: daily,
                    timeRemaining: _timeRemaining,
                    onRetry: _loadDaily,
                    onTap: () => context.goNamed(AppRoutes.discovery),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _WeatherWidget(
                    weather: _weather,
                    loading: _weatherLoading,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(
                child: _SectionHeader(title: 'Your Progress'),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(child: _QuickStats(user: user)),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Top bar
// =============================================================================
class _TopBar extends StatelessWidget {
  const _TopBar({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => context.goNamed(AppRoutes.profile),
            child: _Avatar(user: user, radius: 24),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.military_tech_rounded,
                    size: 16, color: AppColors.onAccent),
                const SizedBox(width: 4),
                Text(
                  'Lvl ${user?.level ?? 1}',
                  style: const TextStyle(
                    color: AppColors.onAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _NotificationBell(onTap: () => context.goNamed(AppRoutes.settings)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, this.radius = 22});

  final UserModel? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundImage:
            (user?.hasPhoto ?? false) ? NetworkImage(user!.photoUrl!) : null,
        child: (user?.hasPhoto ?? false)
            ? null
            : Text(
                user?.initials ?? 'E',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: radius * 0.7,
                ),
              ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Icon(Icons.notifications_none_rounded,
                color: context.colors.onSurface, size: 24),
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Greeting + XP + Streak
// =============================================================================
class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.greeting, required this.user});

  final String greeting;
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final name = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName.split(' ').first
        : 'Explorer';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$greeting,',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            name,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends ConsumerWidget {
  const _ProgressSection({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(levelProvider);
    final progress = ref.watch(levelProgressProvider);
    final toNext = ref.watch(xpToNextLevelProvider);
    final streak = ref.watch(streakProvider);
    final xp = ref.watch(xpProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.workspace_premium_rounded,
                        color: AppColors.accent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Level $level Explorer',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                AnimatedStreakBadge(streak: streak, compact: true),
              ],
            ),
            const SizedBox(height: 16),
            XpProgressBar(
              progress: progress,
              level: level,
              nextLevel: level + 1,
              label: '${AppUtils.formatNumber(xp)} XP · $toNext XP to next level',
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Section header
// =============================================================================
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            title,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (actionLabel != null)
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Daily treasure
// =============================================================================
class _DailyTreasure extends StatelessWidget {
  const _DailyTreasure({
    required this.daily,
    required this.timeRemaining,
    required this.onRetry,
    required this.onTap,
  });

  final AsyncValue<TreasureModel?> daily;
  final Duration timeRemaining;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return daily.when(
      loading: () => const TreasureCardSkeleton(),
      error: (error, _) => _ErrorCard(onRetry: onRetry),
      data: (treasure) {
        if (treasure == null) return _EmptyCard(onRetry: onRetry);
        return Column(
          children: <Widget>[
            TreasureCard.large(treasure: treasure, onTap: onTap),
            if (timeRemaining > Duration.zero) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.timer_outlined,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Expires in ${AppUtils.formatClock(timeRemaining)}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.grey500),
          const SizedBox(height: 12),
          Text(
            "Couldn't load today's treasure",
            style: context.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.auto_awesome_rounded, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'No treasure yet',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Generate one',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Weather
// =============================================================================
class _WeatherWidget extends StatelessWidget {
  const _WeatherWidget({required this.weather, required this.loading});

  final WeatherModel? weather;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(height: 84, child: ListTileSkeleton());
    }
    final w = weather;
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              w != null
                  ? AppUtils.getWeatherIcon(w.condition)
                  : Icons.cloud_off_rounded,
              color: AppColors.info,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  w != null ? '${w.temperature.round()}°C' : '--',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  w != null
                      ? '${w.condition}${w.cityName != null ? ' · ${w.cityName}' : ''}'
                      : 'Weather unavailable',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (w != null)
            Text(
              AppUtils.getWeatherEmoji(w.condition),
              style: const TextStyle(fontSize: 32),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Quick stats
// =============================================================================
class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final km = ((user?.totalWalkingDistance ?? 0) / 1000);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StatTile(
              icon: Icons.explore_rounded,
              value: '${user?.totalDiscoveries ?? 0}',
              label: 'Discoveries',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              icon: Icons.emoji_events_rounded,
              value: '${user?.badges.length ?? 0}',
              label: 'Badges',
              color: AppColors.accentDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              icon: Icons.directions_walk_rounded,
              value: km >= 10
                  ? km.round().toString()
                  : km.toStringAsFixed(1),
              label: 'Walking KM',
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Explore FAB with bounce animation
// =============================================================================
class _ExploreFab extends StatefulWidget {
  const _ExploreFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ExploreFab> createState() => _ExploreFabState();
}

class _ExploreFabState extends State<_ExploreFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: child,
        );
      },
      child: FloatingActionButton.extended(
        onPressed: widget.onPressed,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.explore_rounded),
        label: const Text(
          'Explore Now',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
