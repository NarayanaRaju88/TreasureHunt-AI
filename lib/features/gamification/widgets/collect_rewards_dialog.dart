import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../models/badge_model.dart';
import '../models/level_benefit.dart';
import '../repositories/gamification_repository.dart';
import 'level_benefits_sheet.dart';

/// Celebration after collecting a treasure: XP, optional level-up, mystery box.
Future<void> showCollectRewardsDialog(
  BuildContext context, {
  required int treasureXp,
  required int streak,
  XpResult? xpResult,
  MysteryBoxReward? mystery,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final leveledUp = xpResult?.leveledUp == true;
      final next = xpResult == null ? null : nextBenefit(xpResult.newLevel);

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: <Widget>[
            Icon(
              leveledUp ? Icons.emoji_events_rounded : Icons.celebration_rounded,
              color: leveledUp ? AppColors.gold : AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                leveledUp ? 'Level up!' : 'Treasure collected!',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _RewardLine(
                icon: Icons.stars_rounded,
                color: AppColors.accentDark,
                title: '+$treasureXp XP from this treasure',
              ),
              if (streak > 0) ...<Widget>[
                const SizedBox(height: 10),
                _RewardLine(
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFFF5722),
                  title: '$streak-day streak — keep exploring daily!',
                ),
              ],
              if (leveledUp && xpResult != null) ...<Widget>[
                const SizedBox(height: 10),
                _RewardLine(
                  icon: Icons.workspace_premium_rounded,
                  color: AppColors.gold,
                  title:
                      'You reached Level ${xpResult.newLevel} (was ${xpResult.previousLevel})',
                ),
                if (next != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    'Next unlock at Level ${next.level}: ${next.title}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
              if (mystery != null) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: mystery.rarity.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: mystery.rarity.color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Mystery box · ${mystery.rarity.displayName}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: mystery.rarity.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${mystery.xp} bonus XP'
                        '${mystery.label == null ? '' : ' · ${mystery.label}'}',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Come back tomorrow to grow your streak and open another box!',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          if (leveledUp)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                showLevelBenefitsSheet(
                  context,
                  currentLevel: xpResult!.newLevel,
                );
              },
              child: const Text('View level benefits'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome'),
          ),
        ],
      );
    },
  );
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({
    required this.icon,
    required this.color,
    required this.title,
  });

  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
          ),
        ),
      ],
    );
  }
}
