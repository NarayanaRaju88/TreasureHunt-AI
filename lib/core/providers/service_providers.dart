import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/fcm_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/weather_service.dart';

import '../../data/repositories/auth_repository_impl.dart';

import '../../domain/repositories/auth_repository.dart';

import '../../features/gamification/repositories/gamification_repository.dart';
import '../../features/treasure/repositories/treasure_repository.dart';

/// Shared Preferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Override in main.dart',
  );
});

/// Firebase Authentication
final firebaseAuthServiceProvider =
    Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Firestore
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Hive
final hiveServiceProvider =
    Provider<HiveService>((ref) {
  return HiveService();
});

/// Gemini
final geminiServiceProvider =
    Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Location
final locationServiceProvider =
    Provider<LocationService>((ref) {
  return LocationService();
});

/// Weather
final weatherServiceProvider =
    Provider<WeatherService>((ref) {
  return WeatherService();
});

/// Storage
final storageServiceProvider =
    Provider<StorageService>((ref) {
  return StorageService();
});

/// Notifications
final fcmServiceProvider =
    Provider<FcmService>((ref) {
  return FcmService();
});

/// Authentication Repository
final authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authService: ref.watch(
      firebaseAuthServiceProvider,
    ),
    firestoreService: ref.watch(
      firestoreServiceProvider,
    ),
    hiveService: ref.watch(
      hiveServiceProvider,
    ),
    fcmService: ref.watch(
      fcmServiceProvider,
    ),
  );
});

/// Treasure Repository
final treasureRepositoryProvider =
    Provider<TreasureRepository>((ref) {
  return TreasureRepositoryImpl(
    firestoreService: ref.watch(
      firestoreServiceProvider,
    ),
    geminiService: ref.watch(
      geminiServiceProvider,
    ),
    locationService: ref.watch(
      locationServiceProvider,
    ),
    hiveService: ref.watch(
      hiveServiceProvider,
    ),
    weatherService: ref.watch(
      weatherServiceProvider,
    ),
  );
});

/// Gamification Repository
final gamificationRepositoryProvider =
    Provider<GamificationRepository>((ref) {
  return GamificationRepositoryImpl(
    firestoreService: ref.watch(
      firestoreServiceProvider,
    ),
    hiveService: ref.watch(
      hiveServiceProvider,
    ),
  );
});
