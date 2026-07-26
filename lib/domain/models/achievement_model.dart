class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final String category;
  final int requiredValue;
  final String condition;
  final int xpReward;
  final DateTime unlockedAt;
  final bool isUnlocked;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.requiredValue,
    required this.condition,
    required this.xpReward,
    required this.unlockedAt,
    required this.isUnlocked,
  });
}
