import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/utils/app_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../domain/models/user_model.dart';
import '../models/achievement_model.dart';
import '../models/badge_model.dart';
import '../repositories/gamification_repository.dart';

/// Transient gamification UI state (recent rewards, level-up flags).
class GamificationState {
  const GamificationState({
    this.lastXpGained = 0,
    this.leveledUp = false,
    this.lastReward,
    this.streakIncreased = false,
    this.isBusy = false,
    this.error,
  });

  final int lastXpGained;
  final bool leveledUp;
  final MysteryBoxReward? lastReward;
  final bool streakIncreased;
  final bool isBusy;
  final String? error;

  GamificationState copyWith({
    int? lastXpGained,
    bool? leveledUp,
    MysteryBoxReward? lastReward,
    bool clearReward = false,
    bool? streakIncreased,
    bool? isBusy,
    String? error,
    bool clearError = false,
  }) {
    return GamificationState(
      lastXpGained: lastXpGained ?? this.lastXpGained,
      leveledUp: leveledUp ?? this.leveledUp,
      lastReward: clearReward ? null : (lastReward ?? this.lastReward),
      streakIncreased: streakIncreased ?? this.streakIncreased,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Handles awarding XP, streaks, achievements and mystery-box rewards.
///
/// Mutations flow through the [AuthNotifier] so the authoritative [UserModel]
/// (level, xp, streak) stays consistent across the app.
class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier(this._repo, this._ref)
      : super(const GamificationState());

  final GamificationRepository _repo;
  final Ref _ref;

  UserModel? get _user => _ref.read(currentUserProvider).user;

  /// Awards [amount] XP to the current user. Returns the [XpResult] or `null`.
  Future<XpResult?> awardXp(int amount) async {
    final user = _user;
    if (user == null) return null;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final result = await _repo.addXP(user, amount);
      _ref.read(currentUserProvider.notifier).setUser(result.user);
      state = state.copyWith(
        isBusy: false,
        lastXpGained: result.xpGained,
        leveledUp: result.leveledUp,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return null;
    }
  }

  /// Registers a daily login/activity, updating the streak and awarding XP.
  Future<void> registerDailyActivity() async {
    final user = _user;
    if (user == null) return;
    final previousStreak = user.dailyStreak;
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      streakIncreased: false,
    );
    try {
      final updated = await _repo.updateStreak(user);
      _ref.read(currentUserProvider.notifier).setUser(updated);
      final increased = updated.dailyStreak > previousStreak ||
          (previousStreak == 0 && updated.dailyStreak >= 1);
      state = state.copyWith(isBusy: false, streakIncreased: increased);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  /// Unlocks an achievement and awards its XP reward.
  Future<AchievementModel?> unlockAchievement(
    AchievementModel achievement,
  ) async {
    final user = _user;
    if (user == null) return null;
    try {
      final unlocked = await _repo.unlockAchievement(user.id, achievement);
      if (unlocked.xpReward > 0) {
        await awardXp(unlocked.xpReward);
      }
      _ref.invalidate(achievementsProvider);
      return unlocked;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Opens a mystery box, awarding the rolled XP (and a badge for gold+).
  Future<MysteryBoxReward?> openMysteryBox() async {
    final user = _user;
    if (user == null) return null;
    final reward = _repo.getMysteryBoxReward(level: user.level);
    final result = await awardXp(reward.xp);
    if (result != null && reward.rarity.weight >= BadgeRarity.gold.weight) {
      final badgeId = '${reward.rarity.key}_hunter';
      if (!result.user.badges.contains(badgeId)) {
        final withBadge = result.user.copyWith(
          badges: <String>[...result.user.badges, badgeId],
        );
        _ref.read(currentUserProvider.notifier).setUser(withBadge);
        try {
          await _ref.read(hiveServiceProvider).saveUser(withBadge);
          if (!withBadge.isGuest) {
            await _ref.read(firestoreServiceProvider).updateUser(
              withBadge.uid,
              <String, dynamic>{'badges': withBadge.badges},
            );
          }
        } catch (_) {
          // Keep badge in-session even if remote write fails.
        }
      }
    }
    state = state.copyWith(lastReward: reward);
    return reward;
  }

  void acknowledgeLevelUp() => state = state.copyWith(leveledUp: false);

  void acknowledgeStreak() => state = state.copyWith(streakIncreased: false);

  void clearReward() => state = state.copyWith(clearReward: true);

  void clearError() => state = state.copyWith(clearError: true);
}

/// Primary gamification state provider.
final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier(ref.watch(gamificationRepositoryProvider), ref);
});

/// Current total XP for the signed-in user.
final xpProvider = Provider<int>((ref) {
  return ref.watch(currentUserProvider).user?.xp ?? 0;
});

/// Current level for the signed-in user.
final levelProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider).user;
  if (user == null) return 1;
  return user.level;
});

/// Progress [0, 1] toward the next level.
final levelProgressProvider = Provider<double>((ref) {
  final xp = ref.watch(xpProvider);
  return AppUtils.levelProgress(xp);
});

/// XP still required to reach the next level.
final xpToNextLevelProvider = Provider<int>((ref) {
  final level = ref.watch(levelProvider);
  final xp = ref.watch(xpProvider);
  final needed = AppUtils.calculateXPForNextLevel(level);
  final inLevel = AppUtils.xpInCurrentLevel(xp);
  final remaining = needed - inLevel;
  return remaining < 0 ? 0 : remaining;
});

/// Current daily streak.
final streakProvider = Provider<int>((ref) {
  return ref.watch(currentUserProvider).user?.dailyStreak ?? 0;
});

/// The signed-in user's achievements (fetched from the repository).
final achievementsProvider =
    FutureProvider.autoDispose<List<AchievementModel>>((ref) async {
  final uid = ref.watch(currentUserProvider).user?.id;
  if (uid == null) return const <AchievementModel>[];
  final repo = ref.watch(gamificationRepositoryProvider);
  return repo.getAchievements(uid);
});
