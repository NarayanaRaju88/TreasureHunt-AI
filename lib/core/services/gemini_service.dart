import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';
import '../../features/treasure/models/treasure_category.dart';
import '../../features/treasure/models/treasure_model.dart';

/// A single AI-generated quiz question.
class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];
    var index = (json['correctIndex'] as num?)?.toInt() ?? 0;
    if (index < 0 || index >= options.length) index = 0;
    return QuizQuestion(
      question: (json['question'] ?? '').toString(),
      options: options,
      correctIndex: index,
      explanation: json['explanation'] as String?,
    );
  }
}

/// Wraps the Gemini generative model with domain-specific prompts, robust JSON
/// parsing and error translation.
class GeminiService {
  GeminiService({
    String? apiKey,
    GenerativeModel? model,
    Uuid? uuid,
  })  : _apiKey = apiKey ?? AppConstants.geminiApiKey,
        _uuid = uuid ?? const Uuid(),
        _injectedModel = model;

  final String _apiKey;
  final Uuid _uuid;
  final GenerativeModel? _injectedModel;
  GenerativeModel? _cachedModel;

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Lazily constructs a JSON-mode model, reused across calls.
  GenerativeModel get _model {
    if (_injectedModel != null) return _injectedModel!;
    if (!isConfigured) {
      throw const AIServiceException(
        'AI features are not configured. Missing Gemini API key.',
        code: 'not-configured',
      );
    }
    return _cachedModel ??= GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.9,
        topK: 40,
        topP: 0.95,
        responseMimeType: 'application/json',
      ),
      safetySettings: <SafetySetting>[
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
      ],
    );
  }

  // ===========================================================================
  // Public API
  // ===========================================================================

  /// Generates a single, contextual daily treasure near [lat]/[lng].
  Future<TreasureModel> generateDailyTreasure({
    required double lat,
    required double lng,
    String? weather,
    List<String> interests = const <String>[],
    List<String> previousDiscoveries = const <String>[],
    String? cityName,
  }) async {
    final prompt = '''
You are the game master for "AI Treasure Hunt", a walkable real-world discovery game.
Design ONE surprising, safe, publicly-accessible "treasure" (a real-world place or a
lightweight challenge) near the player's current location.

Player context:
- Approx location: lat=$lat, lng=$lng${cityName != null ? ' ($cityName)' : ''}
- Weather now: ${weather ?? 'unknown'}
- Interests: ${interests.isEmpty ? 'general exploration' : interests.join(', ')}
- Already discovered (avoid repeats): ${previousDiscoveries.isEmpty ? 'none' : previousDiscoveries.join(', ')}

Rules:
- Keep it within a short walking distance (roughly 300-1500 meters).
- Pick a category from this exact list: ${TreasureCategoryX.allKeys.join(', ')}.
- Difficulty must be one of: easy, medium, hard.
- Provide small, plausible latitude/longitude offsets from the player.
- Make the description evocative but concise (max 2 sentences).
- funFacts: 2-3 short, delightful facts.
- nearbyRecommendations: 2-3 short suggestions.

Respond with ONLY a JSON object of this shape:
{
  "title": string,
  "description": string,
  "category": string,
  "lat": number,
  "lng": number,
  "difficulty": "easy" | "medium" | "hard",
  "xpReward": number,
  "estimatedWalkingMinutes": number,
  "funFacts": string[],
  "aiStory": string,
  "nearbyRecommendations": string[],
  "isRare": boolean
}
''';

    final json = await _generateJsonObject(prompt);
    return TreasureModel(
      id: _uuid.v4(),
      title: (json['title'] ?? 'Mystery Treasure').toString(),
      description: (json['description'] ?? '').toString(),
      category: TreasureCategoryX.fromKey(json['category'] as String?),
      lat: _asDouble(json['lat'], fallback: lat),
      lng: _asDouble(json['lng'], fallback: lng),
      difficulty: TreasureDifficultyX.fromKey(json['difficulty'] as String?),
      xpReward: _asInt(json['xpReward'], fallback: AppConstants.xpTreasureFound),
      estimatedWalkingMinutes: _asInt(json['estimatedWalkingMinutes'], fallback: 10),
      funFacts: _asStringList(json['funFacts']),
      aiStory: json['aiStory'] as String?,
      nearbyRecommendations: _asStringList(json['nearbyRecommendations']),
      isRare: json['isRare'] as bool? ?? false,
      createdAt: DateTime.now(),
    );
  }

  /// Generates 3-5 fun facts about a place/treasure.
  Future<List<String>> generateFunFacts(
    String treasureName,
    TreasureCategory category,
  ) async {
    final prompt = '''
Give 3 to 5 short, surprising, family-friendly fun facts about "$treasureName"
(category: ${category.displayName}). Each fact should be a single concise sentence.

Respond with ONLY JSON: { "facts": string[] }
''';
    final json = await _generateJsonObject(prompt);
    final facts = _asStringList(json['facts']);
    if (facts.isEmpty) throw AIServiceException.emptyResponse();
    return facts;
  }

  /// Generates an immersive short story for a treasure.
  Future<String> generateTreasureStory(TreasureModel treasure) async {
    final prompt = '''
Write a short (90-140 words), atmospheric second-person mini-story that makes the
player excited to visit "${treasure.title}" (${treasure.category.displayName}).
Base description: ${treasure.description}
Keep it grounded, warm and evocative. No markdown.

Respond with ONLY JSON: { "story": string }
''';
    final json = await _generateJsonObject(prompt);
    final story = (json['story'] ?? '').toString().trim();
    if (story.isEmpty) throw AIServiceException.emptyResponse();
    return story;
  }

  /// Recommends nearby places aligned to the player's interests.
  Future<List<String>> recommendNearbyPlaces({
    required double lat,
    required double lng,
    List<String> interests = const <String>[],
    String? cityName,
  }) async {
    final prompt = '''
Suggest 4 to 6 interesting, real-world-plausible places to explore near
lat=$lat, lng=$lng${cityName != null ? ' ($cityName)' : ''}.
Tailor to interests: ${interests.isEmpty ? 'general exploration' : interests.join(', ')}.
Each item: "Name — one short reason to visit".

Respond with ONLY JSON: { "places": string[] }
''';
    final json = await _generateJsonObject(prompt);
    return _asStringList(json['places']);
  }

  /// Interprets a free-text search and returns matching treasure suggestions.
  Future<List<TreasureModel>> naturalLanguageSearch({
    required String query,
    required double lat,
    required double lng,
    String? cityName,
  }) async {
    final prompt = '''
The player typed this search: "$query".
Return up to 5 treasure suggestions near lat=$lat, lng=$lng${cityName != null ? ' ($cityName)' : ''}
that best match the intent. Use categories from: ${TreasureCategoryX.allKeys.join(', ')}.
Provide small plausible lat/lng offsets from the player's position.

Respond with ONLY JSON:
{ "results": [
  { "title": string, "description": string, "category": string,
    "lat": number, "lng": number, "difficulty": "easy"|"medium"|"hard",
    "xpReward": number, "estimatedWalkingMinutes": number }
] }
''';
    final json = await _generateJsonObject(prompt);
    final results = json['results'];
    if (results is! List) return const <TreasureModel>[];
    return results.whereType<Map>().map((raw) {
      final map = Map<String, dynamic>.from(raw);
      return TreasureModel(
        id: _uuid.v4(),
        title: (map['title'] ?? 'Result').toString(),
        description: (map['description'] ?? '').toString(),
        category: TreasureCategoryX.fromKey(map['category'] as String?),
        lat: _asDouble(map['lat'], fallback: lat),
        lng: _asDouble(map['lng'], fallback: lng),
        difficulty: TreasureDifficultyX.fromKey(map['difficulty'] as String?),
        xpReward: _asInt(map['xpReward'], fallback: AppConstants.xpTreasureFound),
        estimatedWalkingMinutes: _asInt(map['estimatedWalkingMinutes'], fallback: 10),
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  /// Generates a multiple-choice quiz question about [topic].
  Future<QuizQuestion> generateQuizQuestion(String topic) async {
    final prompt = '''
Create ONE multiple-choice trivia question about "$topic".
Provide exactly 4 options, exactly one correct, and a one-sentence explanation.

Respond with ONLY JSON:
{ "question": string, "options": [string, string, string, string],
  "correctIndex": number, "explanation": string }
''';
    final json = await _generateJsonObject(prompt);
    final question = QuizQuestion.fromJson(json);
    if (question.question.isEmpty || question.options.length < 2) {
      throw AIServiceException.emptyResponse();
    }
    return question;
  }

  // ===========================================================================
  // Internals
  // ===========================================================================

  /// Runs a prompt and returns the parsed top-level JSON object.
  Future<Map<String, dynamic>> _generateJsonObject(String prompt) async {
    final raw = await _generateRaw(prompt);
    final decoded = _decodeJson(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const AIServiceException(
      'The AI returned an unexpected format. Please try again.',
      code: 'bad-format',
    );
  }

  Future<String> _generateRaw(String prompt) async {
    try {
      final response = await _model.generateContent(<Content>[
        Content.text(prompt),
      ]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw AIServiceException.emptyResponse();
      }
      return text;
    } on AIServiceException {
      rethrow;
    } on GenerativeAIException catch (e, st) {
      final msg = e.message.toLowerCase();
      if (msg.contains('quota') || msg.contains('rate')) {
        throw AIServiceException.quotaExceeded();
      }
      throw AIServiceException(
        'The AI service failed to respond. Please try again.',
        code: 'generation-failed',
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      throw AIServiceException(
        'Unexpected AI error. Please try again.',
        code: 'unknown',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Tolerant JSON decoder that strips markdown code fences if present.
  dynamic _decodeJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(json)?', caseSensitive: false), '');
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
      text = text.trim();
    }
    // If there is surrounding prose, extract the first {...} or [...] block.
    if (!(text.startsWith('{') || text.startsWith('['))) {
      final objStart = text.indexOf('{');
      final arrStart = text.indexOf('[');
      final start = <int>[objStart, arrStart]
          .where((i) => i >= 0)
          .fold<int>(-1, (acc, i) => acc == -1 ? i : (i < acc ? i : acc));
      if (start >= 0) text = text.substring(start);
    }
    try {
      return jsonDecode(text);
    } catch (e, st) {
      debugPrint('Gemini JSON decode failed: $e');
      throw AIServiceException(
        'Could not understand the AI response. Please try again.',
        code: 'json-decode-failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  static double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList(growable: false);
    }
    return const <String>[];
  }
}
