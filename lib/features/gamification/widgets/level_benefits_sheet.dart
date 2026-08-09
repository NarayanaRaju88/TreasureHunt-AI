import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../models/level_benefit.dart';

Future<void> showLevelBenefitsSheet(
  BuildContext context, {
  required int currentLevel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
    final unlocked = unlockedBenefits(currentLevel);
    final upcoming = nextBenefit(currentLevel);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Level benefits',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You are Level $currentLevel · ${unlocked.length} milestone'
                '${unlocked.length == 1 ? '' : 's'} unlocked.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              if (upcoming != null) ...<Widget>[
                _BenefitBanner(
                  title: 'Next unlock · Level ${upcoming.level}',
                  subtitle: '${upcoming.title}: ${upcoming.description}',
                  color: AppColors.accentDark,
                ),
                const SizedBox(height: 14),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: kLevelBenefits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final benefit = kLevelBenefits[index];
                    final isUnlocked = benefit.level <= currentLevel;
                    return _BenefitTile(
                      benefit: benefit,
                      unlocked: isUnlocked,
                      isCurrent: benefit.level == currentLevel ||
                          (upcoming != null &&
                              benefit.level == upcoming.level &&
                              !isUnlocked),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _BenefitBanner extends StatelessWidget {
  const _BenefitBanner({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: context.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.benefit,
    required this.unlocked,
    required this.isCurrent,
  });

  final LevelBenefit benefit;
  final bool unlocked;
  final bool isCurrent;

  IconData get _icon {
    switch (benefit.iconName) {
      case 'bolt':
        return Icons.bolt_rounded;
      case 'schedule':
        return Icons.schedule_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'map':
        return Icons.map_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'explore':
      default:
        return Icons.explore_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? AppColors.primary : AppColors.grey500;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isCurrent ? AppColors.accentDark : color)
            .withValues(alpha: unlocked || isCurrent ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isCurrent ? AppColors.accentDark : color)
              .withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(_icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      'Level ${benefit.level}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (unlocked)
                      const Text(
                        'Unlocked',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      )
                    else
                      Text(
                        'Locked',
                        style: TextStyle(
                          color: AppColors.grey500,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.description,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withValues(alpha: 0.75),
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
