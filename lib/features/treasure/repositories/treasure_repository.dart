import 'dart:async';
import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
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
    // 1) Return cached daily treasure only if it is still near the user
    //    and is a place-style offer (not an old walking-challenge-only pin).
    if (!forceRegenerate) {
      try {
        final existing = await _firestore
            .getDailyTreasure(uid)
            .timeout(const Duration(seconds: 4));
        if (existing != null && existing.category.isPlaceOffer) {
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
        // Never surface challenge-only categories as the daily treasure.
        if (!treasure.category.isPlaceOffer) {
          treasure = treasure.copyWith(
            category: TreasureCategoryX
                .placeCategories[DateTime.now().day %
                TreasureCategoryX.placeCategories.length],
          );
        }
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
    final dayIndex = now.difference(DateTime(now.year)).inDays;
    final categories = TreasureCategoryX.placeCategories;
    final category = categories[dayIndex % categories.length];
    return _buildLocalOffer(
      id: 'local-daily-${now.year}-${now.month}-${now.day}',
      lat: lat,
      lng: lng,
      cityName: cityName,
      category: category,
      bearingIndex: dayIndex,
      createdAt: now,
    );
  }

  /// Several varied nearby offers so Home isn't only one walking challenge.
  List<TreasureModel> _localNearbyOffers({
    required double lat,
    required double lng,
    String? cityName,
    int limit = 6,
  }) {
    final now = DateTime.now();
    final categories = TreasureCategoryX.placeCategories;
    final count = limit.clamp(1, categories.length);
    final start = now.day % categories.length;
    final result = <TreasureModel>[];
    for (var i = 0; i < count; i++) {
      final category = categories[(start + i) % categories.length];
      result.add(
        _buildLocalOffer(
          id: 'local-near-${now.year}-${now.month}-${now.day}-$i',
          lat: lat,
          lng: lng,
          cityName: cityName,
          category: category,
          bearingIndex: start + i,
          createdAt: now,
        ),
      );
    }
    result.sort((a, b) => a.distance.compareTo(b.distance));
    return result;
  }

  TreasureModel _buildLocalOffer({
    required String id,
    required double lat,
    required double lng,
    required TreasureCategory category,
    required int bearingIndex,
    required DateTime createdAt,
    String? cityName,
  }) {
    final place = (cityName == null || cityName.trim().isEmpty)
        ? 'your area'
        : cityName.trim();

    // Spread pins around the player (~120–280 m) so they feel like nearby offers.
    final radius = 0.0011 + (bearingIndex % 5) * 0.00025;
    final angle = (bearingIndex % 8) * (3.14159 / 4);
    final dLat = radius * math.cos(angle);
    final dLng = radius * math.sin(angle);
    final tLat = lat + dLat;
    final tLng = lng + dLng;
    final distance = _location.calculateDistance(
      startLat: lat,
      startLng: lng,
      endLat: tLat,
      endLng: tLng,
    );

    final copy = _offerCopy(category, place);
    return TreasureModel(
      id: id,
      title: copy.$1,
      description: copy.$2,
      category: category,
      lat: tLat,
      lng: tLng,
      difficulty: TreasureDifficulty.easy,
      xpReward: 35 + (bearingIndex % 4) * 10,
      distance: distance,
      estimatedWalkingMinutes: math.max(2, (distance / 80).round()),
      funFacts: copy.$3,
      aiStory: copy.$4,
      nearbyRecommendations: copy.$5,
      createdAt: createdAt,
      expiresAt: DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
        23,
        59,
        59,
      ),
    );
  }

  (String, String, List<String>, String, List<String>) _offerCopy(
    TreasureCategory category,
    String place,
  ) {
    switch (category) {
      case TreasureCategory.hiddenCafe:
        return (
          'Cozy Corner Café',
          'A warm café vibe near $place. Step inside, notice the aroma, and claim your discovery.',
          const <String>[
            'Independent cafés often hide the best local stories.',
            'Order something simple and observe the room like an explorer.',
          ],
          'Follow the pin to a café-style stop nearby. Take in the atmosphere, then collect your XP.',
          const <String>['Look for a quiet table', 'Check the specials board'],
        );
      case TreasureCategory.hiddenPark:
        return (
          'Quiet Green Escape',
          'A peaceful park pocket near $place. Stretch your legs and enjoy a short nature break.',
          const <String>[
            'Even small parks can reset your energy for the next adventure.',
            'Listen for birds — city parks are fuller of life than they look.',
          ],
          'Walk to the green pin, take a mindful minute outdoors, then collect your reward.',
          const <String>['Find a shaded bench', 'Take a short loop walk'],
        );
      case TreasureCategory.streetFood:
        return (
          'Local Flavor Stop',
          'A street-food style find near $place. Hunt for smells, colors, and a tasty detour.',
          const <String>[
            'Street food is one of the fastest ways to taste a neighborhood.',
            'Busy stalls are often the most trusted by locals.',
          ],
          'Follow your nose toward the pin. Discover a flavorful corner and collect XP.',
          const <String>['Watch what locals order', 'Try a small snack'],
        );
      case TreasureCategory.photoSpot:
        return (
          'Snapshot Moment',
          'A photogenic corner near $place. Frame a great shot and capture the mood.',
          const <String>[
            'The best photos often come from ordinary streets in good light.',
            'Look for leading lines, contrast, and interesting textures.',
          ],
          'Reach the pin, take your favorite photo angle, then claim your XP.',
          const <String>['Try a low angle', 'Capture a detail close-up'],
        );
      case TreasureCategory.bookStore:
        return (
          'Pages & Curiosity',
          'A bookish stop near $place. Browse covers, titles, and ideas for a few minutes.',
          const <String>[
            'Bookstores are treasure rooms of other people\'s adventures.',
            'Open a random page — serendipity is part of the hunt.',
          ],
          'Visit the pin, spend a curious minute with books, then collect XP.',
          const <String>['Browse a new shelf', 'Note one interesting title'],
        );
      case TreasureCategory.lake:
        return (
          'Waterfront Pause',
          'A calm water-side spot near $place. Watch the surface and slow your pace.',
          const <String>[
            'Water views naturally lower stress and invite reflection.',
            'Look for reflections — they turn ordinary scenes cinematic.',
          ],
          'Walk to the water pin, take a short pause, then collect your treasure XP.',
          const <String>['Watch the water for a minute', 'Feel the breeze'],
        );
      case TreasureCategory.sunsetPoint:
        return (
          'Golden Hour Lookout',
          'An open view near $place made for light, sky, and a short scenic stop.',
          const <String>[
            'Even without sunset, open sky spots feel expansive.',
            'Face west and notice how the light changes.',
          ],
          'Reach the lookout pin, soak in the view, then collect XP.',
          const <String>['Find the widest view', 'Take a sky photo'],
        );
      case TreasureCategory.temple:
        return (
          'Calm Heritage Spot',
          'A peaceful heritage-style place near $place. Move quietly and observe the details.',
          const <String>[
            'Sacred and heritage spaces reward slow, respectful attention.',
            'Architecture often hides symbols in plain sight.',
          ],
          'Approach the pin calmly, notice the craftsmanship, then collect XP.',
          const <String>['Observe the entrance details', 'Stay quiet and mindful'],
        );
      case TreasureCategory.museum:
        return (
          'Culture Peek',
          'A culture-forward stop near $place. Look for exhibits, plaques, or creative displays.',
          const <String>[
            'Museums and cultural corners turn a walk into a learning hunt.',
            'One interesting object can spark a whole day of curiosity.',
          ],
          'Arrive at the pin, find one fascinating detail, then collect XP.',
          const <String>['Read one plaque', 'Pick a favorite object'],
        );
      case TreasureCategory.historicalPlace:
        return (
          'Story of the Street',
          'A historic-feeling corner near $place. Imagine who walked here before you.',
          const <String>[
            'Every neighborhood has layers of history under today\'s shops.',
            'Old walls and plaques are clues waiting to be noticed.',
          ],
          'Walk to the historic pin, discover one story in the surroundings, then collect XP.',
          const <String>['Look for old signage', 'Notice building materials'],
        );
      default:
        return (
          'Nearby Explorer Spot',
          'A walkable discovery near $place. Head to the pin and collect XP when you arrive.',
          const <String>[
            'Every great explorer starts with a short walk.',
            'New nearby spots appear as you keep exploring each day.',
          ],
          'Your hunt begins close to home. Walk toward the pin and claim your XP on arrival.',
          const <String>['Look for a landmark nearby', 'Take a short walking detour'],
        );
    }
  }

  @override
  Future<List<TreasureModel>> getNearbyTreasures({
    required double lat,
    required double lng,
    String? categoryKey,
    int limit = 50,
  }) async {
    final desired = math.min(limit, 6);
    final remote = <TreasureModel>[];

    try {
      final treasures = await _firestore
          .getTreasures(
            categoryKey: categoryKey,
            limit: limit,
          )
          .timeout(const Duration(seconds: 5));
      for (final t in treasures) {
        final distance = _location.calculateDistance(
          startLat: lat,
          startLng: lng,
          endLat: t.lat,
          endLng: t.lng,
        );
        // Keep only nearby, place-style offers — skip distant / challenge pins.
        if (distance > AppConstants.maxSearchRadiusMeters) continue;
        if (!t.category.isPlaceOffer) continue;
        remote.add(t.copyWith(distance: distance));
      }
      remote.sort((a, b) => a.distance.compareTo(b.distance));
    } catch (_) {
      // Fall through to local nearby offers.
    }

    if (remote.length >= desired) {
      return remote.take(desired).toList();
    }

    String? cityName;
    try {
      cityName = await _location.getCityName(lat, lng);
    } catch (_) {
      cityName = null;
    }
    final local = _localNearbyOffers(
      lat: lat,
      lng: lng,
      cityName: cityName,
      limit: desired,
    );

    if (remote.isEmpty) return local;

    // Merge remote place offers with local variety, de-dupe by id.
    final merged = <TreasureModel>[...remote];
    final ids = remote.map((t) => t.id).toSet();
    for (final offer in local) {
      if (merged.length >= desired) break;
      if (ids.add(offer.id)) merged.add(offer);
    }
    merged.sort((a, b) => a.distance.compareTo(b.distance));
    return merged;
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
    // Must physically reach the treasure before collecting XP.
    final pos = await _location.getLocationFast(
      timeout: const Duration(seconds: 6),
    );
    if (pos == null) {
      throw LocationException.permissionDenied();
    }

    final distance = _location.calculateDistance(
      startLat: pos.latitude,
      startLng: pos.longitude,
      endLat: treasure.lat,
      endLng: treasure.lng,
    );
    if (distance > AppConstants.treasureUnlockRadiusMeters) {
      throw LocationException(
        'Get closer to collect this treasure. You are about '
        '${distance.round()} m away (need within '
        '${AppConstants.treasureUnlockRadiusMeters.round()} m).',
        code: 'too-far',
      );
    }

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
      walkingDistance: walkingDistance > 0 ? walkingDistance : distance,
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
