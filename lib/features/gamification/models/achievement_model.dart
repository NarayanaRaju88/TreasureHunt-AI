import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Logical grouping used to organize achievements in the UI.
enum AchievementCategory {
  discovery,
  exploration,
  streak,
  social,
  learning,
  challenge,
  milestone,
}

extension AchievementCategoryX on AchievementCategory {
  String get key => name;

  String get displayName {
    switch (this) {
      case AchievementCategory.discovery:
        return 'Discovery';
      case AchievementCategory.exploration:
        return 'Exploration';
      case AchievementCategory.streak:
        return 'Streaks';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.learning:
        return 'Learning';
      case AchievementCategory.challenge:
        return 'Challenges';
      case AchievementCategory.milestone:
        return 'Milestones';
    }
  }

  static AchievementCategory fromKey(String? value) {
    if (value == null) return AchievementCategory.milestone;
    final normalized = value.trim().toLowerCase();
    for (final c in AchievementCategory.values) {
      if (c.name.toLowerCase() == normalized) return c;
    }
    return AchievementCategory.milestone;
  }
}

/// Represents a single achievement and the player's progress toward it.
class AchievementModel extends Equatable {
  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    this.xpReward = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.requirement = 1,
    this.progress = 0,
    this.category = AchievementCategory.milestone,
  });

  final String id;
  final String title;
  final String description;

  /// A logical icon name (mapped to an [IconData] in the UI layer).
  final String iconName;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  /// The target value that must be reached to unlock (e.g. 10 discoveries).
  final int requirement;

  /// The player's current progress toward [requirement].
  final int progress;
  final AchievementCategory category;

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      iconName: (json['iconName'] ?? 'emoji_events').toString(),
      xpReward: _asInt(json['xpReward']),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: _asDate(json['unlockedAt']),
      requirement: _asInt(json['requirement'], fallback: 1),
      progress: _asInt(json['progress']),
      category: AchievementCategoryX.fromKey(json['category'] as String?),
    );
  }

  factory AchievementModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return AchievementModel.fromJson(<String, dynamic>{
      ...data,
      'id': doc.id,
      'unlockedAt': data['unlockedAt'],
    });
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'xpReward': xpReward,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'requirement': requirement,
      'progress': progress,
      'category': category.key,
    };
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'iconName': iconName,
      'xpReward': xpReward,
      'isUnlocked': isUnlocked,
      'unlockedAt':
          unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'requirement': requirement,
      'progress': progress,
      'category': category.key,
    };
  }

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    int? xpReward,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? requirement,
    int? progress,
    AchievementCategory? category,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      xpReward: xpReward ?? this.xpReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      requirement: requirement ?? this.requirement,
      progress: progress ?? this.progress,
      category: category ?? this.category,
    );
  }

  /// Progress ratio clamped to the range [0, 1].
  double get progressRatio {
    if (requirement <= 0) return isUnlocked ? 1 : 0;
    return (progress / requirement).clamp(0.0, 1.0);
  }

  /// Whether progress has reached the requirement (may not yet be persisted).
  bool get isComplete => progress >= requirement;

  int get remaining =>
      (requirement - progress) < 0 ? 0 : requirement - progress;

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
        xpReward,
        isUnlocked,
        unlockedAt,
        requirement,
        progress,
        category,
      ];

  @override
  bool get stringify => true;
}
