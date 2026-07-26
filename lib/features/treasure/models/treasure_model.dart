import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'treasure_category.dart';

/// Difficulty tier of a treasure — affects XP reward and marker styling.
enum TreasureDifficulty { easy, medium, hard }

extension TreasureDifficultyX on TreasureDifficulty {
  String get key => name;

  String get displayName {
    switch (this) {
      case TreasureDifficulty.easy:
        return 'Easy';
      case TreasureDifficulty.medium:
        return 'Medium';
      case TreasureDifficulty.hard:
        return 'Hard';
    }
  }

  /// Multiplier applied to XP based on difficulty.
  double get xpMultiplier {
    switch (this) {
      case TreasureDifficulty.easy:
        return 1.0;
      case TreasureDifficulty.medium:
        return 1.5;
      case TreasureDifficulty.hard:
        return 2.0;
    }
  }

  static TreasureDifficulty fromKey(String? value) {
    if (value == null) return TreasureDifficulty.easy;
    final normalized = value.trim().toLowerCase();
    for (final d in TreasureDifficulty.values) {
      if (d.name.toLowerCase() == normalized) return d;
    }
    return TreasureDifficulty.easy;
  }
}

/// Core domain model for a single treasure/point-of-interest.
class TreasureModel extends Equatable {
  const TreasureModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.lat,
    required this.lng,
    this.imageUrl,
    this.difficulty = TreasureDifficulty.easy,
    this.xpReward = 50,
    this.distance = 0,
    this.estimatedWalkingMinutes = 0,
    this.funFacts = const <String>[],
    this.aiStory,
    this.nearbyRecommendations = const <String>[],
    this.isRare = false,
    this.isCollected = false,
    this.collectedAt,
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String description;
  final TreasureCategory category;

  // Location -----------------------------------------------------------------
  final double lat;
  final double lng;

  final String? imageUrl;
  final TreasureDifficulty difficulty;
  final int xpReward;

  /// Distance from the user in meters (transient — computed client-side).
  final double distance;
  final int estimatedWalkingMinutes;

  // AI-generated content -----------------------------------------------------
  final List<String> funFacts;
  final String? aiStory;
  final List<String> nearbyRecommendations;

  final bool isRare;
  final bool isCollected;
  final DateTime? collectedAt;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  factory TreasureModel.fromJson(Map<String, dynamic> json) {
    return TreasureModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: TreasureCategoryX.fromKey(json['category'] as String?),
      lat: _asDouble(json['lat']),
      lng: _asDouble(json['lng']),
      imageUrl: json['imageUrl'] as String?,
      difficulty: TreasureDifficultyX.fromKey(json['difficulty'] as String?),
      xpReward: _asInt(json['xpReward'], fallback: 50),
      distance: _asDouble(json['distance']),
      estimatedWalkingMinutes: _asInt(json['estimatedWalkingMinutes']),
      funFacts: _asStringList(json['funFacts']),
      aiStory: json['aiStory'] as String?,
      nearbyRecommendations: _asStringList(json['nearbyRecommendations']),
      isRare: json['isRare'] as bool? ?? false,
      isCollected: json['isCollected'] as bool? ?? false,
      collectedAt: _asDate(json['collectedAt']),
      createdAt: _asDate(json['createdAt']),
      expiresAt: _asDate(json['expiresAt']),
    );
  }

  factory TreasureModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return TreasureModel(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: TreasureCategoryX.fromKey(data['category'] as String?),
      lat: _asDouble(data['lat']),
      lng: _asDouble(data['lng']),
      imageUrl: data['imageUrl'] as String?,
      difficulty: TreasureDifficultyX.fromKey(data['difficulty'] as String?),
      xpReward: _asInt(data['xpReward'], fallback: 50),
      distance: _asDouble(data['distance']),
      estimatedWalkingMinutes: _asInt(data['estimatedWalkingMinutes']),
      funFacts: _asStringList(data['funFacts']),
      aiStory: data['aiStory'] as String?,
      nearbyRecommendations: _asStringList(data['nearbyRecommendations']),
      isRare: data['isRare'] as bool? ?? false,
      isCollected: data['isCollected'] as bool? ?? false,
      collectedAt: _asDate(data['collectedAt']),
      createdAt: _asDate(data['createdAt']),
      expiresAt: _asDate(data['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'category': category.key,
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
      'difficulty': difficulty.key,
      'xpReward': xpReward,
      'distance': distance,
      'estimatedWalkingMinutes': estimatedWalkingMinutes,
      'funFacts': funFacts,
      'aiStory': aiStory,
      'nearbyRecommendations': nearbyRecommendations,
      'isRare': isRare,
      'isCollected': isCollected,
      'collectedAt': collectedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore({bool forCreate = false}) {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'category': category.key,
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
      'difficulty': difficulty.key,
      'xpReward': xpReward,
      'estimatedWalkingMinutes': estimatedWalkingMinutes,
      'funFacts': funFacts,
      'aiStory': aiStory,
      'nearbyRecommendations': nearbyRecommendations,
      'isRare': isRare,
      'isCollected': isCollected,
      'collectedAt':
          collectedAt != null ? Timestamp.fromDate(collectedAt!) : null,
      'createdAt': forCreate
          ? FieldValue.serverTimestamp()
          : (createdAt != null ? Timestamp.fromDate(createdAt!) : null),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  TreasureModel copyWith({
    String? id,
    String? title,
    String? description,
    TreasureCategory? category,
    double? lat,
    double? lng,
    String? imageUrl,
    bool clearImageUrl = false,
    TreasureDifficulty? difficulty,
    int? xpReward,
    double? distance,
    int? estimatedWalkingMinutes,
    List<String>? funFacts,
    String? aiStory,
    List<String>? nearbyRecommendations,
    bool? isRare,
    bool? isCollected,
    DateTime? collectedAt,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return TreasureModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      distance: distance ?? this.distance,
      estimatedWalkingMinutes:
          estimatedWalkingMinutes ?? this.estimatedWalkingMinutes,
      funFacts: funFacts ?? this.funFacts,
      aiStory: aiStory ?? this.aiStory,
      nearbyRecommendations:
          nearbyRecommendations ?? this.nearbyRecommendations,
      isRare: isRare ?? this.isRare,
      isCollected: isCollected ?? this.isCollected,
      collectedAt: collectedAt ?? this.collectedAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Effective XP reward factoring in category, difficulty and rarity.
  int get effectiveXpReward {
    final base = xpReward *
        category.xpMultiplier *
        difficulty.xpMultiplier *
        (isRare ? 1.5 : 1.0);
    return base.round();
  }

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get hasStory => aiStory != null && aiStory!.trim().isNotEmpty;

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        description,
        category,
        lat,
        lng,
        imageUrl,
        difficulty,
        xpReward,
        distance,
        estimatedWalkingMinutes,
        funFacts,
        aiStory,
        nearbyRecommendations,
        isRare,
        isCollected,
        collectedAt,
        createdAt,
        expiresAt,
      ];

  @override
  bool get stringify => true;
}
