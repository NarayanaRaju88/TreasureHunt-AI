import 'dart:async';

import '../../../core/services/firestore_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/weather_service.dart';
import '../models/daily_challenge_model.dart';
import '../models/treasure_category.dart';
import '../models/treasure_history_model.dart';
import '../models/treasure_model.dart';

/// Contract for discovering, generating and collecting treasures.
abstract class TreasureRepository {
  /// Returns (and lazily generates + persists) the user's daily treasure.
  Future<TreasureModel> getDailyTreasure({
    required String uid,
    required double lat,
    required double lng,
    List<String> interests,
    bool forceRegenerate,
  });

  /// Loads treasures near the user, sorted by distance.
  Future<List<TreasureModel>> getNearbyTreasures({
    required double lat,
    required double lng,
    String? categoryKey,
    int limit,
  });

  /// AI-powered free-text search.
  Future<List<TreasureModel>> searchTreasures({
    required String query,
    required double lat,
    required double lng,
  });

  /// Enriches a treasure with AI-generated fun facts + story if missing.
  Future<TreasureModel> enrichTreasure(TreasureModel treasure);

  /// Collects a treasure, persisting a discovery record locally and remotely.
  Future<TreasureHistoryModel> collectTreasure({
    required String uid,
    required TreasureModel treasure,
    double walkingDistance,
    String? userPhotoUrl,
  });

  Future<List<TreasureHistoryModel>> getHistory(String uid);

  Future<List<DailyChallengeModel>> getDailyChallenges(String uid);
}

/// Default implementation combining Firestore, Gemini, weather, location and
/// a Hive cache.
class TreasureRepositoryImpl implements TreasureRepository {
  TreasureRepositoryImpl({
    required FirestoreService firestoreService,
    required GeminiService geminiService,
    required LocationService locationService,
    required HiveService hiveService,
    WeatherService? weatherService,
  })  : _firestore = firestoreService,
        _gemini = geminiService,
        _location = locationService,
        _hive = hiveService,
        _weather = weatherService;

  final FirestoreService _firestore;
  final GeminiService _gemini;
  final LocationService _location;
  final HiveService _hive;
  final WeatherService? _weather;

  @override
  Future<TreasureModel> getDailyTreasure({
    required String uid,
    required double lat,
    required double lng,
    List<String> interests = const <String>[],
    bool forceRegenerate = false,
  }) async {
    // 1) Return cached daily treasure only if it is still near the user.
    if (!forceRegenerate) {
      try {
        final existing = await _firestore
            .getDailyTreasure(uid)
            .timeout(const Duration(seconds: 4));
        if (existing != null) {
          final distance = _location.calculateDistance(
            startLat: lat,
            startLng: lng,
            endLat: existing.lat,
            endLng: existing.lng,
          );
          // Keep cache only when within ~3 km of the player.
          if (distance <= 3000) return existing;
        }
      } catch (_) {
        // Continue to generate / fallback.
      }
    }

    // 2) Gather context best-effort with tight timeouts so Home never hangs.
    String? weatherSummary;
    final weatherSvc = _weather;
    if (weatherSvc != null && weatherSvc.isConfigured) {
      try {
        final weather = await weatherSvc
            .getCurrentWeather(lat, lng)
            .timeout(const Duration(seconds: 4));
        weatherSummary = weather.summary;
      } catch (_) {
        weatherSummary = null;
      }
    }

    List<String> previous = const <String>[];
    try {
      final history = await _firestore
          .getUserHistory(uid, limit: 10)
          .timeout(const Duration(seconds: 3));
      previous = history.map((h) => h.title).toList();
    } catch (_) {
      previous = _hive.getHistory().map((h) => h.title).toList();
    }

    String? cityName;
    try {
      cityName = await _location
          .getCityName(lat, lng)
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      cityName = null;
    }

    // 3) Generate via Gemini (with timeout), or fall back locally.
    TreasureModel treasure;
    try {
      if (!_gemini.isConfigured) {
        treasure = _localDailyTreasure(
          lat: lat,
          lng: lng,
          cityName: cityName,
        );
      } else {
        treasure = await _gemini
            .generateDailyTreasure(
              lat: lat,
              lng: lng,
              weather: weatherSummary,
              interests: interests,
              previousDiscoveries: previous,
              cityName: cityName,
            )
            .timeout(const Duration(seconds: 12));
      }
    } catch (_) {
      treasure = _localDailyTreasure(
        lat: lat,
        lng: lng,
        cityName: cityName,
      );
    }

    // Persist in background — don't block the UI on Firestore writes.
    unawaited(() async {
      try {
        await _firestore.saveDailyTreasure(uid, treasure);
      } catch (_) {}
    }());
    return treasure;
  }

  /// Offline / unconfigured AI fallback near the user.
  TreasureModel _localDailyTreasure({
    required double lat,
    required double lng,
    String? cityName,
  }) {
    final now = DateTime.now();
    final dayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final place = (cityName == null || cityName.trim().isEmpty)
        ? 'your area'
        : cityName.trim();
    // Offset ~150m so the pin is nearby but not exactly on the user.
    const offset = 0.0014;
    return TreasureModel(
      id: 'local-daily-$dayKey',
      title: 'Nearby Explorer Spot',
      description:
          'A walkable discovery near $place. Head to the pin, look around, '
          'and collect XP when you arrive.',
      category: TreasureCategory.walkingChallenge,
      lat: lat + offset,
      lng: lng + offset,
      difficulty: TreasureDifficulty.easy,
      xpReward: 40,
      distance: _location.calculateDistance(
        startLat: lat,
        startLng: lng,
        endLat: lat + offset,
        endLng: lng + offset,
      ),
      estimatedWalkingMinutes: 3,
      funFacts: const <String>[
        'Every great explorer starts with a short walk.',
        'New nearby spots appear as you keep exploring each day.',
      ],
      aiStory:
          'Your daily hunt begins close to home. Walk toward the pin, notice '
          'what makes this corner unique, and claim your XP when you arrive.',
      nearbyRecommendations: const <String>[
        'Look for a park, cafe, or quiet street corner nearby.',
      ],
      createdAt: now,
      expiresAt: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  @override
  Future<List<TreasureModel>> getNearbyTreasures({
    required double lat,
    required double lng,
    String? categoryKey,
    int limit = 50,
  }) async {
    final treasures = await _firestore.getTreasures(
      categoryKey: categoryKey,
      limit: limit,
    );
    final withDistance = treasures.map((t) {
      final distance = _location.calculateDistance(
        startLat: lat,
        startLng: lng,
        endLat: t.lat,
        endLng: t.lng,
      );
      return t.copyWith(distance: distance);
    }).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
    return withDistance;
  }

  @override
  Future<List<TreasureModel>> searchTreasures({
    required String query,
    required double lat,
    required double lng,
  }) async {
    String? cityName;
    try {
      cityName = await _location.getAddressFromCoordinates(lat, lng);
    } catch (_) {
      cityName = null;
    }
    final results = await _gemini.naturalLanguageSearch(
      query: query,
      lat: lat,
      lng: lng,
      cityName: cityName,
    );
    return results.map((t) {
      final distance = _location.calculateDistance(
        startLat: lat,
        startLng: lng,
        endLat: t.lat,
        endLng: t.lng,
      );
      return t.copyWith(distance: distance);
    }).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
  }

  @override
  Future<TreasureModel> enrichTreasure(TreasureModel treasure) async {
    var enriched = treasure;
    if (enriched.funFacts.isEmpty) {
      try {
        final facts =
            await _gemini.generateFunFacts(treasure.title, treasure.category);
        enriched = enriched.copyWith(funFacts: facts);
      } catch (_) {/* keep as-is on failure */}
    }
    if (!enriched.hasStory) {
      try {
        final story = await _gemini.generateTreasureStory(enriched);
        enriched = enriched.copyWith(aiStory: story);
      } catch (_) {/* keep as-is on failure */}
    }
    return enriched;
  }

  @override
  Future<TreasureHistoryModel> collectTreasure({
    required String uid,
    required TreasureModel treasure,
    double walkingDistance = 0,
    String? userPhotoUrl,
  }) async {
    final now = DateTime.now();
    final history = TreasureHistoryModel(
      id: treasure.id.isNotEmpty
          ? treasure.id
          : now.microsecondsSinceEpoch.toString(),
      treasureId: treasure.id,
      title: treasure.title,
      category: treasure.category,
      collectedAt: now,
      imageUrl: treasure.imageUrl,
      xpEarned: treasure.effectiveXpReward,
      lat: treasure.lat,
      lng: treasure.lng,
      userPhotoUrl: userPhotoUrl,
      walkingDistance: walkingDistance,
      wasRare: treasure.isRare,
    );

    // Cache locally first for instant UI + offline safety.
    await _hive.addHistory(history);

    unawaited(() async {
      try {
        await _firestore
            .saveTreasureCollection(uid, history)
            .timeout(const Duration(seconds: 8));
      } catch (_) {}
    }());
    return history;
  }

  @override
  Future<List<TreasureHistoryModel>> getHistory(String uid) async {
    try {
      final remote = await _firestore.getUserHistory(uid);
      // Refresh the local cache.
      for (final h in remote) {
        await _hive.addHistory(h);
      }
      return remote;
    } catch (_) {
      return _hive.getHistory();
    }
  }

  @override
  Future<List<DailyChallengeModel>> getDailyChallenges(String uid) {
    return _firestore.getDailyChallenges(uid);
  }
}
