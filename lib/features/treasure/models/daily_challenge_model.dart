import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'treasure_category.dart';

/// The kind of goal a daily challenge tracks.
enum ChallengeType {
  discover, // discover N treasures
  walk, // walk N meters
  quiz, // answer N quiz treasures
  category, // discover treasures of a specific category
  streak, // maintain a login streak
}

extension ChallengeTypeX on ChallengeType {
  String get key => name;

  String get displayName {
    switch (this) {
      case ChallengeType.discover:
        return 'Discover';
      case ChallengeType.walk:
        return 'Walk';
      case ChallengeType.quiz:
        return 'Quiz';
      case ChallengeType.category:
        return 'Category Hunt';
      case ChallengeType.streak:
        return 'Streak';
    }
  }

  static ChallengeType fromKey(String? value) {
    if (value == null) return ChallengeType.discover;
    final normalized = value.trim().toLowerCase();
    for (final t in ChallengeType.values) {
      if (t.name.toLowerCase() == normalized) return t;
    }
    return ChallengeType.discover;
  }
}

/// A time-boxed daily challenge the player can complete for bonus XP.
class DailyChallengeModel extends Equatable {
  const DailyChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.targetCategory,
    this.goal = 1,
    this.progress = 0,
    this.xpReward = 100,
    this.isCompleted = false,
    this.completedAt,
    this.date,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String description;
  final ChallengeType type;

  /// Only relevant when [type] is [ChallengeType.category].
  final TreasureCategory? targetCategory;

  final int goal;
  final int progress;
  final int xpReward;
  final bool isCompleted;
  final DateTime? completedAt;

  /// The day this challenge belongs to (local midnight).
  final DateTime? date;
  final DateTime? expiresAt;

  factory DailyChallengeModel.fromJson(Map<String, dynamic> json) {
    return DailyChallengeModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: ChallengeTypeX.fromKey(json['type'] as String?),
      targetCategory: json['targetCategory'] != null
          ? TreasureCategoryX.fromKey(json['targetCategory'] as String?)
          : null,
      goal: _asInt(json['goal'], fallback: 1),
      progress: _asInt(json['progress']),
      xpReward: _asInt(json['xpReward'], fallback: 100),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: _asDate(json['completedAt']),
      date: _asDate(json['date']),
      expiresAt: _asDate(json['expiresAt']),
    );
  }

  factory DailyChallengeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return DailyChallengeModel(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      type: ChallengeTypeX.fromKey(data['type'] as String?),
      targetCategory: data['targetCategory'] != null
          ? TreasureCategoryX.fromKey(data['targetCategory'] as String?)
          : null,
      goal: _asInt(data['goal'], fallback: 1),
      progress: _asInt(data['progress']),
      xpReward: _asInt(data['xpReward'], fallback: 100),
      isCompleted: data['isCompleted'] as bool? ?? false,
      completedAt: _asDate(data['completedAt']),
      date: _asDate(data['date']),
      expiresAt: _asDate(data['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'type': type.key,
      'targetCategory': targetCategory?.key,
      'goal': goal,
      'progress': progress,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'date': date?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'type': type.key,
      'targetCategory': targetCategory?.key,
      'goal': goal,
      'progress': progress,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  DailyChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    TreasureCategory? targetCategory,
    int? goal,
    int? progress,
    int? xpReward,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? date,
    DateTime? expiresAt,
  }) {
    return DailyChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetCategory: targetCategory ?? this.targetCategory,
      goal: goal ?? this.goal,
      progress: progress ?? this.progress,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      date: date ?? this.date,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  double get progressRatio {
    if (goal <= 0) return isCompleted ? 1 : 0;
    return (progress / goal).clamp(0.0, 1.0);
  }

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

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
        type,
        targetCategory,
        goal,
        progress,
        xpReward,
        isCompleted,
        completedAt,
        date,
        expiresAt,
      ];

  @override
  bool get stringify => true;
}
