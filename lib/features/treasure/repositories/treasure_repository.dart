import '../../../core/services/firestore_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/weather_service.dart';
import '../models/daily_challenge_model.dart';
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
    // 1) Return the already-stored daily treasure if present.
    if (!forceRegenerate) {
      final existing = await _firestore.getDailyTreasure(uid);
      if (existing != null) return existing;
    }

    // 2) Gather context (weather + previous discoveries) best-effort.
    String? weatherSummary;
    final weatherSvc = _weather;
    if (weatherSvc != null && weatherSvc.isConfigured) {
      try {
        final weather = await weatherSvc.getCurrentWeather(lat, lng);
        weatherSummary = weather.summary;
      } catch (_) {
        weatherSummary = null;
      }
    }

    List<String> previous = const <String>[];
    try {
      final history = await _firestore.getUserHistory(uid, limit: 20);
      previous = history.map((h) => h.title).toList();
    } catch (_) {
      previous = _hive.getHistory().map((h) => h.title).toList();
    }

    String? cityName;
    try {
      cityName = await _location.getAddressFromCoordinates(lat, lng);
    } catch (_) {
      cityName = null;
    }

    // 3) Generate via Gemini and persist.
    final treasure = await _gemini.generateDailyTreasure(
      lat: lat,
      lng: lng,
      weather: weatherSummary,
      interests: interests,
      previousDiscoveries: previous,
      cityName: cityName,
    );

    try {
      await _firestore.saveDailyTreasure(uid, treasure);
    } catch (_) {
      // Non-fatal: still return the generated treasure for this session.
    }
    return treasure;
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

    try {
      await _firestore.saveTreasureCollection(uid, history);
    } catch (_) {
      // Remote save can be retried later; local cache holds the record.
    }
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
