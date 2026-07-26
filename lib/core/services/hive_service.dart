import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/settings/models/settings_model.dart';
import '../../features/treasure/models/treasure_history_model.dart';

/// Hive type ids. Keep these stable across releases — changing an existing id
/// breaks previously persisted data.
class HiveTypeIds {
  HiveTypeIds._();
  static const int user = 10;
  static const int settings = 11;
  static const int treasureHistory = 12;
}

/// Box name for cached treasure discovery history (not present in
/// [AppConstants] which only tracks the phase-1 boxes).
const String _treasureHistoryBoxName = 'treasure_history_box';

/// Initializes Hive, registers [TypeAdapter]s and exposes typed CRUD helpers
/// for the app's persisted models.
///
/// The adapters are hand-written (no build_runner codegen) and serialize each
/// model via its `toJson`/`fromJson` map so nested lists and dates round-trip
/// safely as Hive primitives.
class HiveService {
  HiveService();

  static const String _userKey = 'current_user';
  static const String _settingsKey = 'app_settings';

  bool _initialized = false;

  // Box getters --------------------------------------------------------------
  Box get userBox => Hive.box(AppConstants.hiveUserBox);
  Box get settingsBox => Hive.box(AppConstants.hiveSettingsBox);
  Box get cacheBox => Hive.box(AppConstants.hiveCacheBox);
  Box get treasureHistoryBox => Hive.box(_treasureHistoryBoxName);

  /// Registers adapters and opens all boxes. Idempotent.
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    registerAdapters();
    await Future.wait<void>([
      _openBox(AppConstants.hiveUserBox),
      _openBox(AppConstants.hiveSettingsBox),
      _openBox(AppConstants.hiveCacheBox),
      _openBox(AppConstants.hiveHuntsBox),
      _openBox(_treasureHistoryBoxName),
    ]);
    _initialized = true;
  }

  /// Registers all [TypeAdapter]s exactly once.
  void registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveTypeIds.user)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.settings)) {
      Hive.registerAdapter(SettingsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.treasureHistory)) {
      Hive.registerAdapter(TreasureHistoryModelAdapter());
    }
  }

  Future<void> _openBox(String name) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<dynamic>(name);
    }
  }

  // ===========================================================================
  // User
  // ===========================================================================
  Future<void> saveUser(UserModel user) async {
    try {
      await userBox.put(_userKey, user);
    } catch (e, st) {
      throw CacheException('Failed to cache user.', cause: e, stackTrace: st);
    }
  }

  UserModel? getUser() {
    final value = userBox.get(_userKey);
    if (value is UserModel) return value;
    if (value is Map) return UserModel.fromJson(_asStringMap(value));
    return null;
  }

  Future<void> clearUser() async {
    await userBox.delete(_userKey);
  }

  // ===========================================================================
  // Settings
  // ===========================================================================
  Future<void> saveSettings(SettingsModel settings) async {
    try {
      await settingsBox.put(_settingsKey, settings);
    } catch (e, st) {
      throw CacheException('Failed to save settings.', cause: e, stackTrace: st);
    }
  }

  SettingsModel getSettings() {
    final value = settingsBox.get(_settingsKey);
    if (value is SettingsModel) return value;
    if (value is Map) return SettingsModel.fromHive(value);
    return SettingsModel.defaults();
  }

  // ===========================================================================
  // Treasure history
  // ===========================================================================
  Future<void> addHistory(TreasureHistoryModel history) async {
    try {
      await treasureHistoryBox.put(history.id, history);
    } catch (e, st) {
      throw CacheException('Failed to cache discovery.',
          cause: e, stackTrace: st);
    }
  }

  List<TreasureHistoryModel> getHistory() {
    final result = <TreasureHistoryModel>[];
    for (final value in treasureHistoryBox.values) {
      if (value is TreasureHistoryModel) {
        result.add(value);
      } else if (value is Map) {
        result.add(TreasureHistoryModel.fromJson(_asStringMap(value)));
      }
    }
    result.sort((a, b) => b.collectedAt.compareTo(a.collectedAt));
    return result;
  }

  Future<void> removeHistory(String id) async {
    await treasureHistoryBox.delete(id);
  }

  Future<void> clearHistory() async {
    await treasureHistoryBox.clear();
  }

  // ===========================================================================
  // Generic cache (JSON-serializable values keyed by string)
  // ===========================================================================
  Future<void> cachePut(String key, dynamic value) async {
    await cacheBox.put(key, value);
  }

  T? cacheGet<T>(String key) {
    final value = cacheBox.get(key);
    if (value is T) return value;
    return null;
  }

  Future<void> cacheDelete(String key) async {
    await cacheBox.delete(key);
  }

  Future<void> clearCache() async {
    await cacheBox.clear();
  }

  /// Clears all app data (used on sign-out / reset).
  Future<void> clearAll() async {
    await Future.wait<void>([
      userBox.clear(),
      treasureHistoryBox.clear(),
      cacheBox.clear(),
    ]);
  }

  static Map<String, dynamic> _asStringMap(Map map) =>
      map.map((key, value) => MapEntry(key.toString(), value));
}

// =============================================================================
// Hand-written TypeAdapters (map-backed, no codegen)
// =============================================================================

/// Serializes [UserModel] as its JSON map.
class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = HiveTypeIds.user;

  @override
  UserModel read(BinaryReader reader) {
    final map = reader.readMap();
    return UserModel.fromJson(_stringKeyed(map));
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeMap(obj.toJson());
  }
}

/// Serializes [SettingsModel] as its JSON map.
class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = HiveTypeIds.settings;

  @override
  SettingsModel read(BinaryReader reader) {
    final map = reader.readMap();
    return SettingsModel.fromJson(_stringKeyed(map));
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer.writeMap(obj.toJson());
  }
}

/// Serializes [TreasureHistoryModel] as its JSON map.
class TreasureHistoryModelAdapter extends TypeAdapter<TreasureHistoryModel> {
  @override
  final int typeId = HiveTypeIds.treasureHistory;

  @override
  TreasureHistoryModel read(BinaryReader reader) {
    final map = reader.readMap();
    return TreasureHistoryModel.fromJson(_stringKeyed(map));
  }

  @override
  void write(BinaryWriter writer, TreasureHistoryModel obj) {
    writer.writeMap(obj.toJson());
  }
}

Map<String, dynamic> _stringKeyed(Map<dynamic, dynamic> map) =>
    map.map((key, value) => MapEntry(key.toString(), value));
