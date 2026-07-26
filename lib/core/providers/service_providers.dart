import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/fcm_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../services/hive_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/weather_service.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/gamification/repositories/gamification_repository.dart';
import '../../features/treasure/repositories/treasure_repository.dart';

// =============================================================================
// Low-level services
// =============================================================================

/// Firebase Authentication + Google Sign-In wrapper.
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Cloud Firestore data access.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Gemini generative AI service.
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Device location + geocoding service.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// OpenWeatherMap weather service.
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// Firebase Cloud Messaging + local notifications service.
final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

/// Firebase Storage service.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Local persistence (Hive). This instance is created eagerly; call
/// [HiveService.init] during app bootstrap before first use.
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

// =============================================================================
// Repositories
// =============================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authService: ref.watch(firebaseAuthServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
    hiveService: ref.watch(hiveServiceProvider),
    fcmService: ref.watch(fcmServiceProvider),
  );
});

final treasureRepositoryProvider = Provider<TreasureRepository>((ref) {
  return TreasureRepositoryImpl(
    firestoreService: ref.watch(firestoreServiceProvider),
    geminiService: ref.watch(geminiServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    hiveService: ref.watch(hiveServiceProvider),
    weatherService: ref.watch(weatherServiceProvider),
  );
});

final gamificationRepositoryProvider =
    Provider<GamificationRepository>((ref) {
  return GamificationRepositoryImpl(
    firestoreService: ref.watch(firestoreServiceProvider),
    hiveService: ref.watch(hiveServiceProvider),
  );
});
