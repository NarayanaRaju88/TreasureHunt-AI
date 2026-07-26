import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';

/// Wraps [Geolocator] and [geocoding] with permission handling and the app's
/// error surface. All distance math delegates to Geolocator's Haversine
/// implementation for accuracy.
class LocationService {
  LocationService();

  /// Requests location permission, prompting the user if needed.
  ///
  /// Throws a [LocationException] if services are disabled or permission is
  /// denied/denied-forever.
  Future<LocationPermission> requestPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException.serviceDisabled();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationException.permissionDenied();
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException.permissionDeniedForever();
    }
    return permission;
  }

  /// Returns the current permission status without prompting.
  Future<LocationPermission> checkPermissionStatus() {
    return Geolocator.checkPermission();
  }

  /// Whether the OS location service is enabled.
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Gets a single, current position fix (ensuring permissions first).
  Future<Position> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    await requestPermissions();
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: AppConstants.locationDistanceFilterMeters,
        ),
      );
    } catch (e, st) {
      throw LocationException(
        'Could not determine your location. Please try again.',
        code: 'position-unavailable',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Returns the last known position if available (fast, may be stale).
  Future<Position?> getLastKnownLocation() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// A continuous stream of position updates for live tracking.
  Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = AppConstants.locationDistanceFilterMeters,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  /// Distance in meters between two coordinates (Haversine).
  double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Bearing (degrees) from the start point to the end point.
  double calculateBearing({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  /// Whether the [target] is within [radiusMeters] of the [current] position.
  bool isWithinRadius({
    required Position current,
    required double targetLat,
    required double targetLng,
    double radiusMeters = AppConstants.treasureUnlockRadiusMeters,
  }) {
    final distance = calculateDistance(
      startLat: current.latitude,
      startLng: current.longitude,
      endLat: targetLat,
      endLng: targetLng,
    );
    return distance <= radiusMeters;
  }

  /// Reverse-geocodes coordinates into a human-readable address string.
  ///
  /// Returns `null` if no placemark is found. Never throws for "no result".
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = <String?>[
        p.name,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ].where((s) => s != null && s.trim().isNotEmpty).cast<String>().toList();
      // De-duplicate consecutive identical parts (common in geocoding).
      final deduped = <String>[];
      for (final part in parts) {
        if (deduped.isEmpty || deduped.last != part) deduped.add(part);
      }
      return deduped.join(', ');
    } catch (e, st) {
      throw LocationException(
        'Could not resolve the address for this location.',
        code: 'geocoding-failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Forward-geocodes an address string into coordinates.
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      return locations.isEmpty ? null : locations.first;
    } catch (e, st) {
      throw LocationException(
        'Could not find that place. Please try another search.',
        code: 'forward-geocoding-failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Opens the OS app settings so the user can grant permission manually.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Opens the OS location settings.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
