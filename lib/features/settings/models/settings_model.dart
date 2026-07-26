import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// App-level permission state for location, mirrored from the OS.
enum LocationPermissionStatus {
  unknown,
  denied,
  deniedForever,
  whileInUse,
  always,
}

extension LocationPermissionStatusX on LocationPermissionStatus {
  String get key => name;

  bool get isGranted =>
      this == LocationPermissionStatus.whileInUse ||
      this == LocationPermissionStatus.always;

  static LocationPermissionStatus fromKey(String? value) {
    if (value == null) return LocationPermissionStatus.unknown;
    final normalized = value.trim();
    for (final s in LocationPermissionStatus.values) {
      if (s.name == normalized) return s;
    }
    return LocationPermissionStatus.unknown;
  }
}

/// Persisted user preferences. Stored in Hive (settings box) as a JSON map and
/// mirrored to SharedPreferences by higher layers when needed.
class SettingsModel extends Equatable {
  const SettingsModel({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.morningNotifTime = const TimeOfDaySpec(hour: 8, minute: 0),
    this.language = 'en',
    this.locationPermission = LocationPermissionStatus.unknown,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;

  /// Time of day (local) for the daily morning treasure notification.
  final TimeOfDaySpec morningNotifTime;
  final String language;
  final LocationPermissionStatus locationPermission;
  final bool soundEnabled;
  final bool hapticsEnabled;

  /// Sensible defaults used on first launch.
  factory SettingsModel.defaults() => const SettingsModel();

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      themeMode: _themeFromString(json['themeMode'] as String?),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      morningNotifTime: TimeOfDaySpec.fromMinutes(
        _asInt(json['morningNotifTime'], fallback: 8 * 60),
      ),
      language: (json['language'] ?? 'en').toString(),
      locationPermission:
          LocationPermissionStatusX.fromKey(json['locationPermission'] as String?),
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    );
  }

  /// Reads settings from a raw Hive map (values may be `dynamic`).
  factory SettingsModel.fromHive(Map<dynamic, dynamic>? map) {
    if (map == null || map.isEmpty) return SettingsModel.defaults();
    final json = map.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
    return SettingsModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'themeMode': themeMode.name,
      'notificationsEnabled': notificationsEnabled,
      'morningNotifTime': morningNotifTime.totalMinutes,
      'language': language,
      'locationPermission': locationPermission.key,
      'soundEnabled': soundEnabled,
      'hapticsEnabled': hapticsEnabled,
    };
  }

  /// Map suitable for writing to a Hive box.
  Map<String, dynamic> toHive() => toJson();

  SettingsModel copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    TimeOfDaySpec? morningNotifTime,
    String? language,
    LocationPermissionStatus? locationPermission,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) {
    return SettingsModel(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      morningNotifTime: morningNotifTime ?? this.morningNotifTime,
      language: language ?? this.language,
      locationPermission: locationPermission ?? this.locationPermission,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  static ThemeMode _themeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  @override
  List<Object?> get props => <Object?>[
        themeMode,
        notificationsEnabled,
        morningNotifTime,
        language,
        locationPermission,
        soundEnabled,
        hapticsEnabled,
      ];

  @override
  bool get stringify => true;
}

/// A lightweight, serializable time-of-day value (framework-independent so it
/// can be persisted without importing `dart:ui` semantics into storage code).
class TimeOfDaySpec extends Equatable {
  const TimeOfDaySpec({required this.hour, required this.minute});

  final int hour;
  final int minute;

  factory TimeOfDaySpec.fromMinutes(int totalMinutes) {
    final normalized = totalMinutes % (24 * 60);
    final safe = normalized < 0 ? normalized + 24 * 60 : normalized;
    return TimeOfDaySpec(hour: safe ~/ 60, minute: safe % 60);
  }

  factory TimeOfDaySpec.fromTimeOfDay(TimeOfDay tod) =>
      TimeOfDaySpec(hour: tod.hour, minute: tod.minute);

  int get totalMinutes => hour * 60 + minute;

  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);

  String format() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  List<Object?> get props => <Object?>[hour, minute];
}
