import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../extensions/context_extensions.dart';
import '../l10n/app_strings.dart';
import '../providers/service_providers.dart';
import '../routes/app_router.dart';
import '../theme/app_colors.dart';
import '../utils/app_utils.dart';
import '../../features/treasure/models/treasure_model.dart';

/// Compact Google Map showing the walking route from the user to a treasure pin.
class TreasureRouteMiniMap extends ConsumerStatefulWidget {
  const TreasureRouteMiniMap({
    super.key,
    required this.treasure,
    this.height = 200,
  });

  final TreasureModel treasure;
  final double height;

  @override
  ConsumerState<TreasureRouteMiniMap> createState() =>
      _TreasureRouteMiniMapState();
}

class _TreasureRouteMiniMapState extends ConsumerState<TreasureRouteMiniMap> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  LatLng? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  Future<void> _loadUser() async {
    final pos = await ref.read(locationServiceProvider).getLocationFast(
          timeout: const Duration(seconds: 6),
        );
    if (!mounted) return;
    setState(() {
      _user = pos == null ? null : LatLng(pos.latitude, pos.longitude);
      _loading = false;
    });
    if (_user != null) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await _fitBounds();
    }
  }

  Future<void> _fitBounds() async {
    final user = _user;
    if (user == null || !_controller.isCompleted) return;
    final treasure = LatLng(widget.treasure.lat, widget.treasure.lng);
    final controller = await _controller.future;
    final bounds = LatLngBounds(
      southwest: LatLng(
        user.latitude < treasure.latitude ? user.latitude : treasure.latitude,
        user.longitude < treasure.longitude
            ? user.longitude
            : treasure.longitude,
      ),
      northeast: LatLng(
        user.latitude > treasure.latitude ? user.latitude : treasure.latitude,
        user.longitude > treasure.longitude
            ? user.longitude
            : treasure.longitude,
      ),
    );
    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
    } catch (_) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(treasure, 15),
      );
    }
  }

  Future<void> _startNavigation() async {
    final dest =
        '${widget.treasure.lat},${widget.treasure.lng}';
    final origin = _user == null
        ? null
        : '${_user!.latitude},${_user!.longitude}';
    final uri = Uri.parse(
      origin == null
          ? 'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=walking'
          : 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=walking',
    );
    try {
      final can = await canLaunchUrl(uri);
      final ok = can &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        context.showSnackBar('Could not open navigation', isError: true);
      }
    } catch (_) {
      if (mounted) {
        context.showSnackBar('Could not open navigation', isError: true);
      }
    }
  }

  void _openFullMap() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    }
    context.goNamed(AppRoutes.map);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final treasurePos = LatLng(widget.treasure.lat, widget.treasure.lng);
    final distanceLabel = _user == null
        ? AppUtils.formatDistance(widget.treasure.distance)
        : AppUtils.formatDistance(
            ref.read(locationServiceProvider).calculateDistance(
                  startLat: _user!.latitude,
                  startLng: _user!.longitude,
                  endLat: widget.treasure.lat,
                  endLng: widget.treasure.lng,
                ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.route_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strings.t('route_map'),
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              distanceLabel,
              style: context.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          strings.t('reach_pin_title'),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: _loading
                ? const ColoredBox(
                    color: Color(0x11000000),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : AppConstants.googleMapsApiKey.isEmpty
                    ? _MissingMapsKey(onOpenFullMap: _openFullMap)
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: treasurePos,
                          zoom: 15,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        liteModeEnabled: false,
                        markers: <Marker>{
                          if (_user != null)
                            Marker(
                              markerId: const MarkerId('me'),
                              position: _user!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueAzure,
                              ),
                              infoWindow:
                                  const InfoWindow(title: 'You are here'),
                            ),
                          Marker(
                            markerId: MarkerId('treasure-${widget.treasure.id}'),
                            position: treasurePos,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueOrange,
                            ),
                            infoWindow: InfoWindow(
                              title: widget.treasure.title,
                              snippet: distanceLabel,
                            ),
                          ),
                        },
                        polylines: _user == null
                            ? <Polyline>{}
                            : <Polyline>{
                                Polyline(
                                  polylineId: const PolylineId('route'),
                                  points: <LatLng>[_user!, treasurePos],
                                  color: AppColors.primary,
                                  width: 5,
                                  patterns: <PatternItem>[
                                    PatternItem.dash(24),
                                    PatternItem.gap(12),
                                  ],
                                  geodesic: true,
                                ),
                              },
                        gestureRecognizers: <Factory<
                            OneSequenceGestureRecognizer>>{
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                        onMapCreated: (controller) {
                          if (!_controller.isCompleted) {
                            _controller.complete(controller);
                          }
                          _fitBounds();
                        },
                      ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openFullMap,
                icon: const Icon(Icons.map_rounded),
                label: Text(strings.t('open_full_map')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _startNavigation,
                icon: const Icon(Icons.navigation_rounded),
                label: Text(strings.t('start_navigation')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MissingMapsKey extends StatelessWidget {
  const _MissingMapsKey({required this.onOpenFullMap});

  final VoidCallback onOpenFullMap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.map_outlined, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                'Map preview needs GOOGLE_MAPS_API_KEY. You can still open the Map tab.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall,
              ),
              TextButton(onPressed: onOpenFullMap, child: const Text('Open Map')),
            ],
          ),
        ),
      ),
    );
  }
}
