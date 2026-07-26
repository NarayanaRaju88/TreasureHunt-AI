import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/difficulty_badge.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../treasure/models/treasure_model.dart';
import '../../treasure/providers/treasure_provider.dart';

/// Full-screen Google Maps experience that guides the explorer to their daily
/// treasure with an animated route, a bouncing treasure pin, live distance/ETA
/// and one-tap turn-by-turn navigation.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  late final AnimationController _routeAnimController;

  Position? _current;
  bool _loadingLocation = true;
  String? _locationError;

  Set<Marker> _markers = <Marker>{};

  // Average human walking speed (~5 km/h) used as an ETA fallback.
  static const double _walkingMetersPerMinute = 83.0;

  @override
  void initState() {
    super.initState();
    _routeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _routeAnimController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final location = ref.read(locationServiceProvider);
      final pos = await location.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _current = pos;
        _loadingLocation = false;
      });
      // Load (and lazily generate) the daily treasure for this position.
      await ref.read(treasureProvider.notifier).loadDailyTreasure(
            lat: pos.latitude,
            lng: pos.longitude,
          );
      _routeAnimController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _locationError =
            'We need your location to reveal nearby treasures. Please enable '
            'location and try again.';
      });
    }
  }

  double _distanceMeters(TreasureModel treasure) {
    final pos = _current;
    if (pos == null) return treasure.distance;
    return ref.read(locationServiceProvider).calculateDistance(
          startLat: pos.latitude,
          startLng: pos.longitude,
          endLat: treasure.lat,
          endLng: treasure.lng,
        );
  }

  int _etaMinutes(TreasureModel treasure) {
    if (treasure.estimatedWalkingMinutes > 0) {
      return treasure.estimatedWalkingMinutes;
    }
    final meters = _distanceMeters(treasure);
    final mins = (meters / _walkingMetersPerMinute).ceil();
    return mins < 1 ? 1 : mins;
  }

  void _rebuildMarkers(TreasureModel treasure) {
    final pos = _current;
    final markers = <Marker>{
      if (pos != null)
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(pos.latitude, pos.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      Marker(
        markerId: MarkerId('treasure-${treasure.id}'),
        position: LatLng(treasure.lat, treasure.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(treasure)),
        infoWindow: InfoWindow(
          title: treasure.title,
          snippet: '${AppUtils.formatDistance(_distanceMeters(treasure))} away',
        ),
      ),
    };
    _markers = markers;
  }

  double _hueFor(TreasureModel treasure) {
    final c = treasure.category.color;
    final hsl = HSLColor.fromColor(c);
    return hsl.hue;
  }

  /// Progressively-drawn polyline from the user to the treasure, animated by
  /// [_routeAnimController].
  Set<Polyline> _buildPolylines(TreasureModel treasure) {
    final pos = _current;
    if (pos == null) return <Polyline>{};
    final t = _routeAnimController.value.clamp(0.0, 1.0);
    final start = LatLng(pos.latitude, pos.longitude);
    final end = LatLng(treasure.lat, treasure.lng);

    // Interpolate a set of intermediate points so the line "grows" toward the
    // treasure as the animation progresses.
    const segments = 40;
    final points = <LatLng>[];
    final visible = (segments * t).round().clamp(1, segments);
    for (var i = 0; i <= visible; i++) {
      final f = i / segments;
      points.add(
        LatLng(
          start.latitude + (end.latitude - start.latitude) * f,
          start.longitude + (end.longitude - start.longitude) * f,
        ),
      );
    }
    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: AppColors.primary,
        width: 5,
        patterns: <PatternItem>[
          PatternItem.dash(28),
          PatternItem.gap(14),
        ],
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      ),
    };
  }

  Future<void> _centerOnMe() async {
    final pos = _current;
    if (pos == null) return;
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude),
        16.5,
      ),
    );
  }

  Future<void> _fitBounds(TreasureModel treasure) async {
    final pos = _current;
    if (pos == null) return;
    final controller = await _mapController.future;
    final sw = LatLng(
      pos.latitude < treasure.lat ? pos.latitude : treasure.lat,
      pos.longitude < treasure.lng ? pos.longitude : treasure.lng,
    );
    final ne = LatLng(
      pos.latitude > treasure.lat ? pos.latitude : treasure.lat,
      pos.longitude > treasure.lng ? pos.longitude : treasure.lng,
    );
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: sw, northeast: ne),
          90,
        ),
      );
    } catch (_) {
      await _centerOnMe();
    }
  }

  Future<void> _startNavigation(TreasureModel treasure) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${treasure.lat},${treasure.lng}'
      '&travelmode=walking',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      context.showSnackBar('Could not open navigation', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(dailyTreasureProvider);
    final treasure = daily.asData?.value;

    if (treasure != null && _current != null) {
      _rebuildMarkers(treasure);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Treasure Map'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          // ---- Map or loading skeleton -------------------------------------
          if (_loadingLocation)
            const _MapSkeleton()
          else if (_locationError != null)
            _MapError(message: _locationError!, onRetry: _bootstrap)
          else if (_current != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_current!.latitude, _current!.longitude),
                zoom: 16,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              markers: _markers,
              polylines:
                  treasure != null ? _buildPolylines(treasure) : <Polyline>{},
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
                if (treasure != null) _fitBounds(treasure);
              },
            ),

          // ---- Prominent distance + ETA banner -----------------------------
          if (treasure != null && !_loadingLocation && _locationError == null)
            Positioned(
              top: context.padding.top + kToolbarHeight,
              left: 16,
              right: 16,
              child: _DistanceEtaBanner(
                distanceLabel:
                    AppUtils.formatDistance(_distanceMeters(treasure)),
                etaMinutes: _etaMinutes(treasure),
              ),
            ),

          // ---- Bouncing treasure pin (TweenAnimationBuilder) ---------------
          if (treasure != null && !_loadingLocation && _locationError == null)
            const Align(
              alignment: Alignment(0, -0.15),
              child: _BouncingTreasurePin(),
            ),

          // ---- Floating action buttons -------------------------------------
          if (treasure != null && !_loadingLocation && _locationError == null)
            Positioned(
              right: 16,
              bottom: 260,
              child: Column(
                children: <Widget>[
                  FloatingActionButton.small(
                    heroTag: 'fitBounds',
                    backgroundColor: context.colors.surface,
                    foregroundColor: AppColors.primary,
                    onPressed: () => _fitBounds(treasure),
                    child: const Icon(Icons.zoom_out_map_rounded),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'centerOnMe',
                    backgroundColor: context.colors.surface,
                    foregroundColor: AppColors.primary,
                    onPressed: _centerOnMe,
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ],
              ),
            ),

          // ---- Bottom treasure info sheet ----------------------------------
          if (treasure != null && !_loadingLocation && _locationError == null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _TreasureInfoSheet(
                treasure: treasure,
                distanceLabel:
                    AppUtils.formatDistance(_distanceMeters(treasure)),
                etaMinutes: _etaMinutes(treasure),
                onNavigate: () => _startNavigation(treasure),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Distance + ETA banner
// =============================================================================
class _DistanceEtaBanner extends StatelessWidget {
  const _DistanceEtaBanner({
    required this.distanceLabel,
    required this.etaMinutes,
  });

  final String distanceLabel;
  final int etaMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _Metric(
            icon: Icons.straighten_rounded,
            value: distanceLabel,
            label: 'Distance',
            color: AppColors.primary,
          ),
          Container(
            width: 1,
            height: 34,
            color: context.colors.outlineVariant.withValues(alpha: 0.5),
          ),
          _Metric(
            icon: Icons.directions_walk_rounded,
            value: '$etaMinutes min',
            label: 'Walking ETA',
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Bouncing treasure pin — uses a looping TweenAnimationBuilder.
// =============================================================================
class _BouncingTreasurePin extends StatefulWidget {
  const _BouncingTreasurePin();

  @override
  State<_BouncingTreasurePin> createState() => _BouncingTreasurePinState();
}

class _BouncingTreasurePinState extends State<_BouncingTreasurePin> {
  double _target = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _target = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _target),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      onEnd: () {
        // Reverse the target to create a continuous bounce loop.
        if (mounted) setState(() => _target = _target == 1 ? 0 : 1);
      },
      builder: (context, value, child) {
        final offset = -12.0 * value; // rise up to 12px
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppColors.onAccent,
              size: 28,
            ),
          ),
          Container(
            width: 3,
            height: 14,
            color: AppColors.accentDark,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bottom treasure info sheet
// =============================================================================
class _TreasureInfoSheet extends StatelessWidget {
  const _TreasureInfoSheet({
    required this.treasure,
    required this.distanceLabel,
    required this.etaMinutes,
    required this.onNavigate,
  });

  final TreasureModel treasure;
  final String distanceLabel;
  final int etaMinutes;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: treasure.category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  treasure.category.icon,
                  color: treasure.category.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      treasure.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      treasure.category.displayName,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              DifficultyBadge(difficulty: treasure.difficulty, compact: true),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _Chip(
                icon: Icons.straighten_rounded,
                label: distanceLabel,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.schedule_rounded,
                label: '$etaMinutes min walk',
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.bolt_rounded,
                label: '+${treasure.effectiveXpReward} XP',
                color: AppColors.accentDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.navigation_rounded),
              label: const Text(
                'Start Navigation',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
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
// Loading skeleton + error states
// =============================================================================
class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: LoadingShimmer(
            child: Container(color: context.colors.surfaceContainerHighest),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              Text(
                'Pinpointing your location…',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapError extends StatelessWidget {
  const _MapError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.location_off_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Location needed',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
