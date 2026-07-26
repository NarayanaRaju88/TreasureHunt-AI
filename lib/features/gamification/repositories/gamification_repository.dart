import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/utils/app_utils.dart';
import '../../auth/models/user_model.dart';
import '../models/achievement_model.dart';
import '../models/badge_model.dart';

/// Result of awarding XP — captures whether a level-up happened.
class XpResult {
  const XpResult({
    required this.user,
    required this.xpGained,
    required this.leveledUp,
    required this.previousLevel,
    required this.newLevel,
  });

  final UserModel user;
  final int xpGained;
  final bool leveledUp;
  final int previousLevel;
  final int newLevel;

  int get levelsGained => (newLevel - previousLevel).clamp(0, AppConstants.maxLevel);
}

/// Reward returned when opening a mystery box.
class MysteryBoxReward {
  const MysteryBoxReward({
    required this.xp,
    required this.rarity,
    this.badge,
    this.label,
  });

  final int xp;
  final BadgeRarity rarity;
  final BadgeModel? badge;
  final String? label;
}

/// Contract for gamification operations (XP, levels, streaks, achievements).
abstract class GamificationRepository {
  Future<XpResult> addXP(UserModel user, int amount);
  bool checkLevelUp(int previousXp, int newXp);
  Future<AchievementModel> unlockAchievement(
    String uid,
    AchievementModel achievement,
  );
  Future<UserModel> updateStreak(UserModel user);
  MysteryBoxReward getMysteryBoxReward({int level = 1});
  Future<List<AchievementModel>> getAchievements(String uid);
}

/// Default implementation persisting to Firestore with a Hive cache.
class GamificationRepositoryImpl implements GamificationRepository {
  GamificationRepositoryImpl({
    required FirestoreService firestoreService,
    required HiveService hiveService,
    math.Random? random,
  })  : _firestore = firestoreService,
        _hive = hiveService,
        _random = random ?? math.Random();

  final FirestoreService _firestore;
  final HiveService _hive;
  final math.Random _random;

  @override
  Future<XpResult> addXP(UserModel user, int amount) async {
    final safeAmount = amount < 0 ? 0 : amount;
    final previousXp = user.xp;
    final previousLevel = user.level;
    final newXp = previousXp + safeAmount;
    final newLevel = AppUtils.calculateLevel(newXp);
    final leveledUp = newLevel > previousLevel;

    final updated = user.copyWith(xp: newXp, level: newLevel);

    await _persistUser(updated, <String, dynamic>{
      'xp': newXp,
      'level': newLevel,
    });

    return XpResult(
      user: updated,
      xpGained: safeAmount,
      leveledUp: leveledUp,
      previousLevel: previousLevel,
      newLevel: newLevel,
    );
  }

  @override
  bool checkLevelUp(int previousXp, int newXp) {
    return AppUtils.calculateLevel(newXp) > AppUtils.calculateLevel(previousXp);
  }

  @override
  Future<AchievementModel> unlockAchievement(
    String uid,
    AchievementModel achievement,
  ) async {
    if (achievement.isUnlocked) return achievement;
    final unlocked = achievement.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
      progress: math.max(achievement.progress, achievement.requirement),
    );
    await _firestore.updateAchievement(uid, unlocked);
    return unlocked;
  }

  @override
  Future<UserModel> updateStreak(UserModel user) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = user.lastActiveDate;

    int newStreak;
    if (last == null) {
      newStreak = 1;
    } else {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        // Already counted today — no change.
        return user;
      } else if (diff == 1) {
        newStreak = user.dailyStreak + 1;
      } else {
        // Missed one or more days — reset.
        newStreak = 1;
      }
    }

    var updated = user.copyWith(
      dailyStreak: newStreak,
      lastActiveDate: today,
    );

    // Award a bonus at streak milestones (multiples of the threshold).
    int bonusXp = AppConstants.xpDailyLogin;
    if (newStreak > 0 &&
        newStreak % AppConstants.streakBonusThresholdDays == 0) {
      bonusXp += AppConstants.streakBonusXp;
    }
    final newXp = updated.xp + bonusXp;
    updated = updated.copyWith(
      xp: newXp,
      level: AppUtils.calculateLevel(newXp),
    );

    await _persistUser(updated, <String, dynamic>{
      'dailyStreak': updated.dailyStreak,
      'lastActiveDate': updated.lastActiveDate?.toIso8601String(),
      'xp': updated.xp,
      'level': updated.level,
    });
    return updated;
  }

  @override
  MysteryBoxReward getMysteryBoxReward({int level = 1}) {
    // Weighted rarity roll — higher levels slightly improve odds.
    final roll = _random.nextDouble();
    final levelBoost = (level / AppConstants.maxLevel).clamp(0.0, 1.0) * 0.1;

    BadgeRarity rarity;
    if (roll < 0.02 + levelBoost * 0.5) {
      rarity = BadgeRarity.legendary;
    } else if (roll < 0.10 + levelBoost) {
      rarity = BadgeRarity.platinum;
    } else if (roll < 0.28 + levelBoost) {
      rarity = BadgeRarity.gold;
    } else if (roll < 0.60) {
      rarity = BadgeRarity.silver;
    } else {
      rarity = BadgeRarity.bronze;
    }

    final baseXp = AppConstants.xpTreasureFound;
    final xp = (baseXp * rarity.weight * (0.8 + _random.nextDouble() * 0.6))
        .round();

    return MysteryBoxReward(
      xp: xp,
      rarity: rarity,
      label: '${rarity.displayName} reward',
    );
  }

  @override
  Future<List<AchievementModel>> getAchievements(String uid) {
    return _firestore.getAchievements(uid);
  }

  // ===========================================================================
  // Internals
  // ===========================================================================
  Future<void> _persistUser(UserModel user, Map<String, dynamic> delta) async {
    // Cache immediately; best-effort remote write.
    await _hive.saveUser(user);
    if (user.isGuest) return;
    try {
      await _firestore.updateUser(user.id, delta);
    } catch (_) {
      // Non-fatal; local cache is authoritative until next sync.
    }
  }
}
