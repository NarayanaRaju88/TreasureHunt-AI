import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// A collection of pure, side-effect-free utility functions used across the
/// AI Treasure Hunt app.
class AppUtils {
  AppUtils._();

  // ---------------------------------------------------------------------------
  // Distance formatting
  // ---------------------------------------------------------------------------

  /// Formats a distance given in [meters] into a compact human string.
  ///
  /// Examples: 45 -> "45 m", 1250 -> "1.3 km", 15400 -> "15 km".
  static String formatDistance(double meters, {bool imperial = false}) {
    if (meters.isNaN || meters.isInfinite || meters < 0) return '--';

    if (imperial) {
      final double feet = meters * 3.28084;
      if (feet < 1000) return '${feet.round()} ft';
      final double miles = meters / 1609.344;
      return miles < 10
          ? '${miles.toStringAsFixed(1)} mi'
          : '${miles.round()} mi';
    }

    if (meters < 1000) return '${meters.round()} m';
    final double km = meters / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }

  // ---------------------------------------------------------------------------
  // Time / date formatting
  // ---------------------------------------------------------------------------

  /// Formats a [DateTime] as a clock time, e.g. "14:05" or "2:05 PM".
  static String formatTime(DateTime dateTime, {bool use24h = false}) {
    final DateFormat formatter = use24h
        ? DateFormat.Hm()
        : DateFormat('h:mm a');
    return formatter.format(dateTime);
  }

  /// Formats a [DateTime] as a readable date, e.g. "Jul 18, 2026".
  static String formatDate(DateTime dateTime) =>
      DateFormat('MMM d, yyyy').format(dateTime);

  /// Formats a [DateTime] as date + time, e.g. "Jul 18, 2026 · 2:05 PM".
  static String formatDateTime(DateTime dateTime, {bool use24h = false}) =>
      '${formatDate(dateTime)} · ${formatTime(dateTime, use24h: use24h)}';

  /// Returns a relative "time ago" string, e.g. "3h ago", "just now".
  static String timeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Formats a [Duration] as "1h 05m 30s", "05m 30s" or "30s".
  static String formatDuration(Duration duration) {
    if (duration.isNegative) duration = Duration.zero;
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');

    if (hours > 0) return '${hours}h ${mm}m ${ss}s';
    if (minutes > 0) return '${minutes}m ${ss}s';
    return '${seconds}s';
  }

  /// Formats a [Duration] as a digital clock "HH:MM:SS" or "MM:SS".
  static String formatClock(Duration duration) {
    if (duration.isNegative) duration = Duration.zero;
    final int hours = duration.inHours;
    final String mm =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String ss =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0
        ? '${hours.toString().padLeft(2, '0')}:$mm:$ss'
        : '$mm:$ss';
  }

  // ---------------------------------------------------------------------------
  // Weather
  // ---------------------------------------------------------------------------

  /// Maps an OpenWeather-style [condition] string to a Material icon.
  static IconData getWeatherIcon(String condition) {
    final String c = condition.toLowerCase();
    if (c.contains('thunder') || c.contains('storm')) {
      return Icons.thunderstorm_rounded;
    }
    if (c.contains('drizzle')) return Icons.grain_rounded;
    if (c.contains('rain')) return Icons.umbrella_rounded;
    if (c.contains('snow') || c.contains('sleet')) return Icons.ac_unit_rounded;
    if (c.contains('mist') ||
        c.contains('fog') ||
        c.contains('haze') ||
        c.contains('smoke')) {
      return Icons.foggy;
    }
    if (c.contains('cloud')) {
      return c.contains('few') || c.contains('scattered')
          ? Icons.wb_cloudy_outlined
          : Icons.cloud_rounded;
    }
    if (c.contains('clear') || c.contains('sun')) return Icons.wb_sunny_rounded;
    if (c.contains('wind')) return Icons.air_rounded;
    return Icons.wb_cloudy_rounded;
  }

  /// Returns an emoji for a weather [condition], useful for compact UIs.
  static String getWeatherEmoji(String condition) {
    final String c = condition.toLowerCase();
    if (c.contains('thunder') || c.contains('storm')) return '⛈️';
    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    if (c.contains('snow')) return '❄️';
    if (c.contains('fog') || c.contains('mist') || c.contains('haze')) {
      return '🌫️';
    }
    if (c.contains('cloud')) return '☁️';
    if (c.contains('clear') || c.contains('sun')) return '☀️';
    return '🌤️';
  }

  // ---------------------------------------------------------------------------
  // Gamification math
  // ---------------------------------------------------------------------------

  /// Returns the cumulative XP required to *reach* the start of [level].
  ///
  /// Level 1 starts at 0 XP. Each subsequent level uses a geometric growth
  /// curve based on [AppConstants.baseXpPerLevel] and
  /// [AppConstants.xpGrowthFactor].
  static int totalXpForLevel(int level) {
    if (level <= 1) return 0;
    double total = 0;
    for (int l = 1; l < level; l++) {
      total += AppConstants.baseXpPerLevel *
          math.pow(AppConstants.xpGrowthFactor, l - 1);
    }
    return total.round();
  }

  /// Calculates the current level for a given [totalXp].
  static int calculateLevel(int totalXp) {
    if (totalXp <= 0) return 1;
    int level = 1;
    while (level < AppConstants.maxLevel &&
        totalXp >= totalXpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// XP required to advance from [currentLevel] to the next level.
  static int calculateXPForNextLevel(int currentLevel) {
    if (currentLevel >= AppConstants.maxLevel) return 0;
    return totalXpForLevel(currentLevel + 1) - totalXpForLevel(currentLevel);
  }

  /// XP the user has accumulated *within* their current level.
  static int xpInCurrentLevel(int totalXp) {
    final int level = calculateLevel(totalXp);
    return totalXp - totalXpForLevel(level);
  }

  /// Progress [0.0, 1.0] toward the next level for a given [totalXp].
  static double levelProgress(int totalXp) {
    final int level = calculateLevel(totalXp);
    if (level >= AppConstants.maxLevel) return 1.0;
    final int needed = calculateXPForNextLevel(level);
    if (needed <= 0) return 1.0;
    final double progress = xpInCurrentLevel(totalXp) / needed;
    return progress.clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Numbers / strings
  // ---------------------------------------------------------------------------

  /// Formats large numbers compactly, e.g. 1500 -> "1.5K", 2_000_000 -> "2M".
  static String formatCompactNumber(num value) =>
      NumberFormat.compact().format(value);

  /// Formats a number with thousands separators, e.g. 12345 -> "12,345".
  static String formatNumber(num value) => NumberFormat.decimalPattern().format(value);

  /// Clamps and formats a percentage from a [fraction] in [0, 1].
  static String formatPercent(double fraction) =>
      '${(fraction.clamp(0.0, 1.0) * 100).round()}%';

  /// Returns initials (max 2 chars) from a display [name].
  static String initialsFromName(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  /// Returns a rarity label capitalized for display.
  static String rarityLabel(String rarity) =>
      rarity.isEmpty ? '' : rarity[0].toUpperCase() + rarity.substring(1);

  // ---------------------------------------------------------------------------
  // Geo helpers
  // ---------------------------------------------------------------------------

  /// Computes the great-circle distance (in meters) between two lat/lng points
  /// using the Haversine formula.
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
