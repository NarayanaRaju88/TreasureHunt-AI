/// Clear per-level unlocks so explorers know what they gain by leveling up.
class LevelBenefit {
  const LevelBenefit({
    required this.level,
    required this.title,
    required this.description,
    required this.iconName,
  });

  final int level;
  final String title;
  final String description;

  /// Material icon semantic name used by the UI mapper.
  final String iconName;
}

/// Milestone benefits unlocked as the explorer levels up.
const List<LevelBenefit> kLevelBenefits = <LevelBenefit>[
  LevelBenefit(
    level: 1,
    title: 'Explorer start',
    description:
        'Daily treasure + nearby offers unlocked. Collect within 30 m of each pin for XP.',
    iconName: 'explore',
  ),
  LevelBenefit(
    level: 2,
    title: 'Starter boost',
    description:
        '+10% XP on your next collected treasure and a clearer route hint on Discovery.',
    iconName: 'bolt',
  ),
  LevelBenefit(
    level: 3,
    title: 'Longer hunt window',
    description:
        'Daily treasure stays active longer in your session and mystery box odds improve slightly.',
    iconName: 'schedule',
  ),
  LevelBenefit(
    level: 5,
    title: 'Bronze hunter',
    description:
        'Unlock the Bronze Hunter badge track and better common→rare mystery box odds.',
    iconName: 'military_tech',
  ),
  LevelBenefit(
    level: 7,
    title: 'Streak shield',
    description:
        'One free streak protect per week if you miss a day of exploring.',
    iconName: 'shield',
  ),
  LevelBenefit(
    level: 10,
    title: 'Silver scout',
    description:
        '+15% XP on hard treasures and access to rare nearby offer categories more often.',
    iconName: 'star',
  ),
  LevelBenefit(
    level: 15,
    title: 'Navigator perk',
    description:
        'Faster map route refresh and priority weather tips for outdoor hunts.',
    iconName: 'map',
  ),
  LevelBenefit(
    level: 20,
    title: 'Gold pathfinder',
    description:
        'Weekly bonus chest + epic mystery-box chance unlocked.',
    iconName: 'workspace_premium',
  ),
  LevelBenefit(
    level: 30,
    title: 'Legend track',
    description:
        'Legendary offer chance opens and profile shows a Legend frame.',
    iconName: 'auto_awesome',
  ),
  LevelBenefit(
    level: 50,
    title: 'Master explorer',
    description:
        'Permanent +20% XP on all collects and exclusive Master badge.',
    iconName: 'emoji_events',
  ),
];

LevelBenefit? benefitForLevel(int level) {
  for (final b in kLevelBenefits) {
    if (b.level == level) return b;
  }
  return null;
}

/// Benefits already unlocked at or below [level], newest last.
List<LevelBenefit> unlockedBenefits(int level) {
  return kLevelBenefits.where((b) => b.level <= level).toList();
}

/// Next upcoming benefit after [level], if any.
LevelBenefit? nextBenefit(int level) {
  for (final b in kLevelBenefits) {
    if (b.level > level) return b;
  }
  return null;
}
