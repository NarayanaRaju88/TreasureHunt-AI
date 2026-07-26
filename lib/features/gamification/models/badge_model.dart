import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Rarity tiers for badges (also used for treasure/reward rarity styling).
enum BadgeRarity { bronze, silver, gold, platinum, legendary }

extension BadgeRarityX on BadgeRarity {
  String get key => name;

  String get displayName {
    switch (this) {
      case BadgeRarity.bronze:
        return 'Bronze';
      case BadgeRarity.silver:
        return 'Silver';
      case BadgeRarity.gold:
        return 'Gold';
      case BadgeRarity.platinum:
        return 'Platinum';
      case BadgeRarity.legendary:
        return 'Legendary';
    }
  }

  /// Representative color for the tier (pulled from the app palette).
  Color get color {
    switch (this) {
      case BadgeRarity.bronze:
        return AppColors.bronze;
      case BadgeRarity.silver:
        return AppColors.silver;
      case BadgeRarity.gold:
        return AppColors.gold;
      case BadgeRarity.platinum:
        return AppColors.platinum;
      case BadgeRarity.legendary:
        return AppColors.legendary;
    }
  }

  /// Relative weight used for sorting / drop probability (higher = rarer).
  int get weight {
    switch (this) {
      case BadgeRarity.bronze:
        return 1;
      case BadgeRarity.silver:
        return 2;
      case BadgeRarity.gold:
        return 3;
      case BadgeRarity.platinum:
        return 4;
      case BadgeRarity.legendary:
        return 5;
    }
  }

  static BadgeRarity fromKey(String? value) {
    if (value == null) return BadgeRarity.bronze;
    final normalized = value.trim().toLowerCase();
    for (final r in BadgeRarity.values) {
      if (r.name.toLowerCase() == normalized) return r;
    }
    return BadgeRarity.bronze;
  }
}

/// A collectible badge awarded to the player.
class BadgeModel extends Equatable {
  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    this.rarity = BadgeRarity.bronze,
    this.isUnlocked = false,
    this.unlockedAt,
    this.xpReward = 0,
  });

  final String id;
  final String title;
  final String description;
  final String iconName;
  final BadgeRarity rarity;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      iconName: (json['iconName'] ?? 'military_tech').toString(),
      rarity: BadgeRarityX.fromKey(json['rarity'] as String?),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: _asDate(json['unlockedAt']),
      xpReward: _asInt(json['xpReward']),
    );
  }

  factory BadgeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return BadgeModel.fromJson(<String, dynamic>{...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'rarity': rarity.key,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'xpReward': xpReward,
    };
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'iconName': iconName,
      'rarity': rarity.key,
      'isUnlocked': isUnlocked,
      'unlockedAt':
          unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'xpReward': xpReward,
    };
  }

  BadgeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    BadgeRarity? rarity,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      rarity: rarity ?? this.rarity,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
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
        iconName,
        rarity,
        isUnlocked,
        unlockedAt,
        xpReward,
      ];

  @override
  bool get stringify => true;
}
