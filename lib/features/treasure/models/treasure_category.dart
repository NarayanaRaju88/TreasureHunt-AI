import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// All treasure categories supported by the AI Treasure Hunt experience.
///
/// Each category carries presentation metadata (icon, color, display name)
/// and gameplay tuning (an XP multiplier applied on discovery).
enum TreasureCategory {
  hiddenCafe,
  hiddenPark,
  historicalPlace,
  streetFood,
  bookStore,
  temple,
  museum,
  lake,
  sunsetPoint,
  photoSpot,
  quizTreasure,
  learningTreasure,
  aiChallenge,
  walkingChallenge,
}

/// Rich metadata & helpers for [TreasureCategory].
extension TreasureCategoryX on TreasureCategory {
  /// Stable string key used for persistence (Firestore / Hive / JSON).
  String get key {
    switch (this) {
      case TreasureCategory.hiddenCafe:
        return 'hidden_cafe';
      case TreasureCategory.hiddenPark:
        return 'hidden_park';
      case TreasureCategory.historicalPlace:
        return 'historical_place';
      case TreasureCategory.streetFood:
        return 'street_food';
      case TreasureCategory.bookStore:
        return 'book_store';
      case TreasureCategory.temple:
        return 'temple';
      case TreasureCategory.museum:
        return 'museum';
      case TreasureCategory.lake:
        return 'lake';
      case TreasureCategory.sunsetPoint:
        return 'sunset_point';
      case TreasureCategory.photoSpot:
        return 'photo_spot';
      case TreasureCategory.quizTreasure:
        return 'quiz_treasure';
      case TreasureCategory.learningTreasure:
        return 'learning_treasure';
      case TreasureCategory.aiChallenge:
        return 'ai_challenge';
      case TreasureCategory.walkingChallenge:
        return 'walking_challenge';
    }
  }

  /// Human-friendly label shown in the UI.
  String get displayName {
    switch (this) {
      case TreasureCategory.hiddenCafe:
        return 'Hidden Café';
      case TreasureCategory.hiddenPark:
        return 'Hidden Park';
      case TreasureCategory.historicalPlace:
        return 'Historical Place';
      case TreasureCategory.streetFood:
        return 'Street Food';
      case TreasureCategory.bookStore:
        return 'Book Store';
      case TreasureCategory.temple:
        return 'Temple';
      case TreasureCategory.museum:
        return 'Museum';
      case TreasureCategory.lake:
        return 'Lake';
      case TreasureCategory.sunsetPoint:
        return 'Sunset Point';
      case TreasureCategory.photoSpot:
        return 'Photo Spot';
      case TreasureCategory.quizTreasure:
        return 'Quiz Treasure';
      case TreasureCategory.learningTreasure:
        return 'Learning Treasure';
      case TreasureCategory.aiChallenge:
        return 'AI Challenge';
      case TreasureCategory.walkingChallenge:
        return 'Walking Challenge';
    }
  }

  /// Short one-line description used on cards & detail sheets.
  String get description {
    switch (this) {
      case TreasureCategory.hiddenCafe:
        return 'A cozy, off-the-radar café worth discovering.';
      case TreasureCategory.hiddenPark:
        return 'A tranquil green escape hidden in plain sight.';
      case TreasureCategory.historicalPlace:
        return 'A place where history quietly lingers.';
      case TreasureCategory.streetFood:
        return 'A local street-food gem for your taste buds.';
      case TreasureCategory.bookStore:
        return 'A charming bookstore for curious minds.';
      case TreasureCategory.temple:
        return 'A serene temple full of culture and calm.';
      case TreasureCategory.museum:
        return 'A museum brimming with stories and art.';
      case TreasureCategory.lake:
        return 'A peaceful lake perfect for reflection.';
      case TreasureCategory.sunsetPoint:
        return 'A vantage point for breathtaking sunsets.';
      case TreasureCategory.photoSpot:
        return 'A picture-perfect spot for your feed.';
      case TreasureCategory.quizTreasure:
        return 'Answer a quiz to unlock this treasure.';
      case TreasureCategory.learningTreasure:
        return 'Learn something new and earn rewards.';
      case TreasureCategory.aiChallenge:
        return 'An AI-crafted challenge just for you.';
      case TreasureCategory.walkingChallenge:
        return 'Walk the distance to claim your prize.';
    }
  }

  /// Material icon representing the category.
  IconData get icon {
    switch (this) {
      case TreasureCategory.hiddenCafe:
        return Icons.local_cafe_rounded;
      case TreasureCategory.hiddenPark:
        return Icons.park_rounded;
      case TreasureCategory.historicalPlace:
        return Icons.account_balance_rounded;
      case TreasureCategory.streetFood:
        return Icons.fastfood_rounded;
      case TreasureCategory.bookStore:
        return Icons.menu_book_rounded;
      case TreasureCategory.temple:
        return Icons.temple_buddhist_rounded;
      case TreasureCategory.museum:
        return Icons.museum_rounded;
      case TreasureCategory.lake:
        return Icons.water_rounded;
      case TreasureCategory.sunsetPoint:
        return Icons.wb_twilight_rounded;
      case TreasureCategory.photoSpot:
        return Icons.photo_camera_rounded;
      case TreasureCategory.quizTreasure:
        return Icons.quiz_rounded;
      case TreasureCategory.learningTreasure:
        return Icons.school_rounded;
      case TreasureCategory.aiChallenge:
        return Icons.auto_awesome_rounded;
      case TreasureCategory.walkingChallenge:
        return Icons.directions_walk_rounded;
    }
  }

  /// Primary color used for markers, chips and accents.
  Color get color {
    switch (this) {
      case TreasureCategory.hiddenCafe:
        return const Color(0xFF8D6E63);
      case TreasureCategory.hiddenPark:
        return const Color(0xFF4CAF50);
      case TreasureCategory.historicalPlace:
        return const Color(0xFF795548);
      case TreasureCategory.streetFood:
        return const Color(0xFFFF7043);
      case TreasureCategory.bookStore:
        return const Color(0xFF5C6BC0);
      case TreasureCategory.temple:
        return const Color(0xFFFFB300);
      case TreasureCategory.museum:
        return const Color(0xFF8E24AA);
      case TreasureCategory.lake:
        return const Color(0xFF29B6F6);
      case TreasureCategory.sunsetPoint:
        return const Color(0xFFFF8A65);
      case TreasureCategory.photoSpot:
        return const Color(0xFFEC407A);
      case TreasureCategory.quizTreasure:
        return const Color(0xFF26A69A);
      case TreasureCategory.learningTreasure:
        return const Color(0xFF42A5F5);
      case TreasureCategory.aiChallenge:
        return AppColors.tertiary;
      case TreasureCategory.walkingChallenge:
        return AppColors.secondary;
    }
  }

  /// XP multiplier applied to the base reward for this category.
  double get xpMultiplier {
    switch (this) {
      case TreasureCategory.hiddenCafe:
      case TreasureCategory.streetFood:
      case TreasureCategory.photoSpot:
        return 1.0;
      case TreasureCategory.hiddenPark:
      case TreasureCategory.bookStore:
      case TreasureCategory.lake:
        return 1.1;
      case TreasureCategory.historicalPlace:
      case TreasureCategory.temple:
      case TreasureCategory.museum:
      case TreasureCategory.sunsetPoint:
        return 1.25;
      case TreasureCategory.quizTreasure:
      case TreasureCategory.learningTreasure:
        return 1.5;
      case TreasureCategory.walkingChallenge:
        return 1.75;
      case TreasureCategory.aiChallenge:
        return 2.0;
    }
  }

  /// Whether this category represents an interactive challenge (vs. a place).
  bool get isChallenge {
    switch (this) {
      case TreasureCategory.quizTreasure:
      case TreasureCategory.learningTreasure:
      case TreasureCategory.aiChallenge:
      case TreasureCategory.walkingChallenge:
        return true;
      default:
        return false;
    }
  }

  /// Parses a persisted [key] (or enum name) back into a [TreasureCategory].
  ///
  /// Falls back to [TreasureCategory.photoSpot] for unknown values so the app
  /// never crashes on unexpected/legacy data.
  static TreasureCategory fromKey(String? value) {
    if (value == null || value.isEmpty) return TreasureCategory.photoSpot;
    final normalized = value.trim();
    for (final category in TreasureCategory.values) {
      if (category.key == normalized || category.name == normalized) {
        return category;
      }
    }
    // Tolerate camelCase / snake_case mismatches.
    final collapsed = normalized.replaceAll('_', '').toLowerCase();
    for (final category in TreasureCategory.values) {
      if (category.name.toLowerCase() == collapsed) return category;
    }
    return TreasureCategory.photoSpot;
  }

  /// All category keys — handy for Gemini prompt construction & filters.
  static List<String> get allKeys =>
      TreasureCategory.values.map((c) => c.key).toList(growable: false);
}
