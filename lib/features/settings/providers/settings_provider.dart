import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/hive_service.dart';
import '../models/settings_model.dart';

/// Manages app settings, persisting them to Hive on every change.
///
/// NOTE: This is the feature-level source of truth for settings. The
/// `themeModeProvider` exposed here is derived from [settingsProvider]; screens
/// that need the theme mode should prefer it so theme changes stay in sync with
/// all other persisted preferences.
class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier(this._hive) : super(_hive.getSettings());

  final HiveService _hive;

  Future<void> _persist(SettingsModel next) async {
    state = next;
    await _hive.saveSettings(next);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _persist(state.copyWith(themeMode: mode));

  Future<void> toggleTheme() {
    final next =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    return setThemeMode(next);
  }

  Future<void> setNotificationsEnabled(bool enabled) =>
      _persist(state.copyWith(notificationsEnabled: enabled));

  Future<void> setMorningNotifTime(TimeOfDay time) => _persist(
        state.copyWith(morningNotifTime: TimeOfDaySpec.fromTimeOfDay(time)),
      );

  Future<void> setLanguage(String languageCode) =>
      _persist(state.copyWith(language: languageCode));

  Future<void> setLocationPermission(LocationPermissionStatus status) =>
      _persist(state.copyWith(locationPermission: status));

  Future<void> setSoundEnabled(bool enabled) =>
      _persist(state.copyWith(soundEnabled: enabled));

  Future<void> setHapticsEnabled(bool enabled) =>
      _persist(state.copyWith(hapticsEnabled: enabled));

  /// Resets all preferences to their defaults.
  Future<void> reset() => _persist(SettingsModel.defaults());
}

/// Primary settings provider.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier(ref.watch(hiveServiceProvider));
});

/// Derived theme mode — kept in sync with all persisted settings.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider.select((s) => s.themeMode));
});

/// Derived: whether notifications are enabled.
final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((s) => s.notificationsEnabled));
});

/// Derived: the selected language code.
final languageProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider.select((s) => s.language));
});
