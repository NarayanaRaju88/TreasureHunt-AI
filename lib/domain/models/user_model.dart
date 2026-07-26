class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final int level;
  final int totalXp;
  final int currentXp;
  final int dailyStreak;
  final int totalDiscoveries;
  final double totalWalkingDistance;
  final List<String> collectedTreasureIds;
  final List<String> achievements;
  final List<String> badges;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.level = 1,
    this.totalXp = 0,
    this.currentXp = 0,
    this.dailyStreak = 0,
    this.totalDiscoveries = 0,
    this.totalWalkingDistance = 0.0,
    this.collectedTreasureIds = const [],
    this.achievements = const [],
    this.badges = const [],
    required this.createdAt,
    required this.lastActiveAt,
    this.preferences = const {},
  });

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    int? level,
    int? totalXp,
    int? currentXp,
    int? dailyStreak,
    int? totalDiscoveries,
    double? totalWalkingDistance,
    List<String>? collectedTreasureIds,
    List<String>? achievements,
    List<String>? badges,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      currentXp: currentXp ?? this.currentXp,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      totalDiscoveries: totalDiscoveries ?? this.totalDiscoveries,
      totalWalkingDistance: totalWalkingDistance ?? this.totalWalkingDistance,
      collectedTreasureIds: collectedTreasureIds ?? this.collectedTreasureIds,
      achievements: achievements ?? this.achievements,
      badges: badges ?? this.badges,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
    );
  }
}
