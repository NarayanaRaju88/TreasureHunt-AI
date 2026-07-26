import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/xp_progress_bar.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../gamification/models/achievement_model.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../treasure/models/treasure_history_model.dart';
import '../../treasure/providers/treasure_provider.dart';

/// Hero tag shared with other screens that display the user avatar.
const String kProfileAvatarHeroTag = 'profile-avatar';

/// The user's profile: avatar, identity, level, stats, achievements and recent
/// discoveries, plus a logout action.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingPhoto = false;

  Future<void> _changePhoto() async {
    final user = ref.read(currentUserProvider).user;
    if (user == null || user.isGuest) {
      context.showSnackBar('Sign in to set a profile photo', isError: true);
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _uploadingPhoto = true);
      final storage = ref.read(storageServiceProvider);
      final url = await storage.uploadProfileImage(user.id, File(picked.path));
      await ref
          .read(currentUserProvider.notifier)
          .updateProfile(photoUrl: url);
      if (mounted) context.showSnackBar('Profile photo updated');
    } catch (_) {
      if (mounted) {
        context.showSnackBar('Could not update photo', isError: true);
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can always sign back in later.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(currentUserProvider.notifier).logout();
    if (mounted) context.goNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).user;

    return Scaffold(
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text('Profile'),
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(
                user: user,
                uploadingPhoto: _uploadingPhoto,
                onChangePhoto: _changePhoto,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _LevelCard(user: user)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _StatsGrid(user: user)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(
            child: _SectionTitle(title: 'Achievements', icon: Icons.emoji_events_rounded),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: _AchievementsRow()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(
            child: _SectionTitle(title: 'Recent Discoveries', icon: Icons.history_rounded),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const _RecentDiscoveries(),
          SliverToBoxAdapter(child: _LogoutButton(onLogout: _logout)),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// =============================================================================
// Header (avatar + identity)
// =============================================================================
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.uploadingPhoto,
    required this.onChangePhoto,
  });

  final UserModel? user;
  final bool uploadingPhoto;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final memberSince = user?.createdAt != null
        ? 'Member since ${AppUtils.formatDate(user!.createdAt!)}'
        : 'Welcome, explorer!';
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 40),
            Hero(
              tag: kProfileAvatarHeroTag,
              child: Stack(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      backgroundImage: (user?.hasPhoto ?? false)
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                      child: (user?.hasPhoto ?? false)
                          ? null
                          : Text(
                              user?.initials ?? 'E',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 34,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: uploadingPhoto ? null : onChangePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: uploadingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.onAccent,
                                  ),
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded,
                                size: 16, color: AppColors.onAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              (user?.displayName.trim().isNotEmpty ?? false)
                  ? user!.displayName
                  : 'Explorer',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            if ((user?.email ?? '').isNotEmpty)
              Text(
                user!.email,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              memberSince,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Level card
// =============================================================================
class _LevelCard extends ConsumerWidget {
  const _LevelCard({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(levelProvider);
    final progress = ref.watch(levelProgressProvider);
    final toNext = ref.watch(xpToNextLevelProvider);
    final xp = ref.watch(xpProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.onAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Level $level Explorer',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${AppUtils.formatNumber(xp)} XP total',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            XpProgressBar(
              progress: progress,
              level: level,
              nextLevel: level + 1,
              label: '$toNext XP to Level ${level + 1}',
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Stats grid
// =============================================================================
class _StatsGrid extends ConsumerWidget {
  const _StatsGrid({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final km = (user?.totalWalkingDistance ?? 0) / 1000;
    final items = <Widget>[
      _StatCard(
        icon: Icons.explore_rounded,
        value: '${user?.totalDiscoveries ?? 0}',
        label: 'Discoveries',
        color: AppColors.primary,
      ),
      _StatCard(
        icon: Icons.emoji_events_rounded,
        value: '${user?.badges.length ?? 0}',
        label: 'Badges',
        color: AppColors.accentDark,
      ),
      _StatCard(
        icon: Icons.directions_walk_rounded,
        value: km >= 10 ? km.round().toString() : km.toStringAsFixed(1),
        label: 'Walking KM',
        color: AppColors.secondary,
      ),
      _StatCard(
        icon: Icons.local_fire_department_rounded,
        value: '$streak',
        label: 'Day Streak',
        color: const Color(0xFFFF5722),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: items,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  value,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Section title
// =============================================================================
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Achievements row
// =============================================================================
class _AchievementsRow extends ConsumerWidget {
  const _AchievementsRow();

  IconData _iconFor(String name) {
    switch (name.toLowerCase()) {
      case 'explorer':
      case 'explore':
        return Icons.explore_rounded;
      case 'streak':
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'walk':
        return Icons.directions_walk_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'social':
        return Icons.group_rounded;
      case 'trophy':
      case 'milestone':
        return Icons.emoji_events_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return SizedBox(
      height: 120,
      child: achievementsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ListTileSkeleton(),
        ),
        error: (_, __) => _emptyAchievements(context, 'Achievements unavailable'),
        data: (achievements) {
          if (achievements.isEmpty) {
            return _emptyAchievements(
              context,
              'Start exploring to unlock achievements!',
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final a = achievements[i];
              return _AchievementChip(
                achievement: a,
                icon: _iconFor(a.iconName),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyAchievements(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({required this.achievement, required this.icon});

  final AchievementModel achievement;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = achievement.isUnlocked;
    final Color color = unlocked ? AppColors.accentDark : AppColors.grey500;
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: unlocked ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: unlocked ? AppColors.accentGradient : null,
                  color: unlocked ? null : AppColors.grey400.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: unlocked ? AppColors.onAccent : AppColors.grey600,
                  size: 24,
                ),
              ),
              if (!unlocked)
                const Icon(Icons.lock_rounded,
                    size: 16, color: AppColors.grey700),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface
                  .withValues(alpha: unlocked ? 1 : 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Recent discoveries
// =============================================================================
class _RecentDiscoveries extends ConsumerWidget {
  const _RecentDiscoveries();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(treasureHistoryProvider);

    return historyAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ListSkeleton(itemCount: 3),
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: _emptyState(context, "Couldn't load discoveries"),
      ),
      data: (history) {
        if (history.isEmpty) {
          return SliverToBoxAdapter(
            child: _emptyState(
              context,
              'No discoveries yet — head out and find your first treasure!',
            ),
          );
        }
        final recent = history.take(5).toList();
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _DiscoveryTile(item: recent[i]),
            childCount: recent.length,
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.travel_explore_rounded,
                color: AppColors.grey500, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryTile extends StatelessWidget {
  const _DiscoveryTile({required this.item});

  final TreasureHistoryModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.category.color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: <Widget>[
            CategoryIcon(category: item.category, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppUtils.timeAgo(item.collectedAt),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+${item.xpEarned} XP',
                style: const TextStyle(
                  color: AppColors.accentDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Logout
// =============================================================================
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          label: const Text(
            'Log Out',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
