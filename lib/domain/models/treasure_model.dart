class TreasureModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final double distance;
  final int difficulty;
  final int rewardPoints;
  final String imageUrl;
  final String story;
  final List<String> funFacts;
  final DateTime createdAt;
  final bool isCollected;
  final int estimatedWalkingTimeMinutes;
  final String weather;

  TreasureModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.difficulty,
    required this.rewardPoints,
    required this.imageUrl,
    required this.story,
    required this.funFacts,
    required this.createdAt,
    required this.isCollected,
    required this.estimatedWalkingTimeMinutes,
    required this.weather,
  });

  TreasureModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? latitude,
    double? longitude,
    double? distance,
    int? difficulty,
    int? rewardPoints,
    String? imageUrl,
    String? story,
    List<String>? funFacts,
    DateTime? createdAt,
    bool? isCollected,
    int? estimatedWalkingTimeMinutes,
    String? weather,
  }) {
    return TreasureModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      difficulty: difficulty ?? this.difficulty,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      imageUrl: imageUrl ?? this.imageUrl,
      story: story ?? this.story,
      funFacts: funFacts ?? this.funFacts,
      createdAt: createdAt ?? this.createdAt,
      isCollected: isCollected ?? this.isCollected,
      estimatedWalkingTimeMinutes:
          estimatedWalkingTimeMinutes ?? this.estimatedWalkingTimeMinutes,
      weather: weather ?? this.weather,
    );
  }
}
