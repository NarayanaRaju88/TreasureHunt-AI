/// Global, immutable constants used throughout the AI Treasure Hunt app.
///
/// Keep everything that is "configuration-like" here so it is easy to audit and
/// change in one place. Secret API keys should ultimately be supplied through
/// `--dart-define` or a secure backend; the placeholders below are read from
/// the environment when available and otherwise fall back to an empty string.
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------------
  // App metadata
  // ---------------------------------------------------------------------------
  static const String appName = 'AI Treasure Hunt';
  static const String appTagline = 'Discover. Explore. Conquer.';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@aitreasurehunt.app';
  static const String privacyPolicyUrl = 'https://aitreasurehunt.app/privacy';
  static const String termsUrl = 'https://aitreasurehunt.app/terms';

  // ---------------------------------------------------------------------------
  // API keys / secrets (supplied via --dart-define at build time)
  // ---------------------------------------------------------------------------
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
  static const String weatherApiKey =
      String.fromEnvironment('WEATHER_API_KEY', defaultValue: '');

  static const String geminiModel = 'gemini-1.5-flash';
  static const String geminiProModel = 'gemini-1.5-pro';

  // ---------------------------------------------------------------------------
  // Firestore collection names
  // ---------------------------------------------------------------------------
  static const String usersCollection = 'users';
  static const String huntsCollection = 'hunts';
  static const String treasuresCollection = 'treasures';
  static const String cluesCollection = 'clues';
  static const String discoveriesCollection = 'discoveries';
  static const String leaderboardCollection = 'leaderboard';
  static const String achievementsCollection = 'achievements';
  static const String badgesCollection = 'badges';
  static const String notificationsCollection = 'notifications';
  static const String friendsCollection = 'friends';
  static const String feedbackCollection = 'feedback';
  static const String sessionsCollection = 'sessions';

  // ---------------------------------------------------------------------------
  // Firebase Storage paths
  // ---------------------------------------------------------------------------
  static const String storageAvatars = 'avatars';
  static const String storageTreasureImages = 'treasure_images';
  static const String storageDiscoveryPhotos = 'discovery_photos';

  // ---------------------------------------------------------------------------
  // Hive box names
  // ---------------------------------------------------------------------------
  static const String hiveSettingsBox = 'settings_box';
  static const String hiveUserBox = 'user_box';
  static const String hiveCacheBox = 'cache_box';
  static const String hiveHuntsBox = 'hunts_box';

  // ---------------------------------------------------------------------------
  // SharedPreferences / persisted keys
  // ---------------------------------------------------------------------------
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyHapticsEnabled = 'haptics_enabled';
  static const String keyLastKnownLat = 'last_known_lat';
  static const String keyLastKnownLng = 'last_known_lng';

  // ---------------------------------------------------------------------------
  // Gamification tuning
  // ---------------------------------------------------------------------------
  /// Base XP required to move from level 1 to level 2.
  static const int baseXpPerLevel = 100;

  /// Growth multiplier applied per level for the XP curve.
  static const double xpGrowthFactor = 1.5;

  /// Highest attainable level.
  static const int maxLevel = 100;

  // XP rewards for actions.
  static const int xpTreasureFound = 50;
  static const int xpClueSolved = 20;
  static const int xpDailyLogin = 10;
  static const int xpHuntCompleted = 150;
  static const int xpFirstDiscoveryBonus = 100;
  static const int xpPhotoShared = 15;
  static const int xpFriendAdded = 5;

  // Discovery / proximity rules.
  static const double treasureUnlockRadiusMeters = 30;
  static const double clueHintRadiusMeters = 150;
  static const double maxSearchRadiusMeters = 5000;

  // Streaks.
  static const int streakBonusThresholdDays = 7;
  static const int streakBonusXp = 75;

  // ---------------------------------------------------------------------------
  // Rarity tiers
  // ---------------------------------------------------------------------------
  static const String rarityCommon = 'common';
  static const String rarityRare = 'rare';
  static const String rarityEpic = 'epic';
  static const String rarityLegendary = 'legendary';

  // ---------------------------------------------------------------------------
  // Networking / timeouts
  // ---------------------------------------------------------------------------
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration locationUpdateInterval = Duration(seconds: 5);
  static const int locationDistanceFilterMeters = 10;

  // ---------------------------------------------------------------------------
  // UI durations
  // ---------------------------------------------------------------------------
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 700);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // ---------------------------------------------------------------------------
  // Validation limits
  // ---------------------------------------------------------------------------
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;
  static const int minNameLength = 2;
  static const int maxNameLength = 40;
  static const int maxBioLength = 160;

  // ---------------------------------------------------------------------------
  // Asset paths
  // ---------------------------------------------------------------------------
  static const String logoImage = 'assets/images/logo.png';
  static const String placeholderAvatar = 'assets/images/avatar_placeholder.png';
  static const String onboarding1 = 'assets/images/onboarding_1.png';
  static const String onboarding2 = 'assets/images/onboarding_2.png';
  static const String onboarding3 = 'assets/images/onboarding_3.png';
  static const String emptyStateImage = 'assets/images/empty_state.png';

  static const String splashAnimation = 'assets/animations/splash.json';
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String successAnimation = 'assets/animations/success.json';
  static const String treasureAnimation = 'assets/animations/treasure.json';
  static const String emptyAnimation = 'assets/animations/empty.json';
  static const String errorAnimation = 'assets/animations/error.json';

  // ---------------------------------------------------------------------------
  // FCM
  // ---------------------------------------------------------------------------
  static const String fcmDefaultTopic = 'all_users';
  static const String fcmDefaultChannelId = 'ath_default_channel';
  static const String fcmDefaultChannelName = 'General Notifications';
  static const String fcmDefaultChannelDesc =
      'General notifications from AI Treasure Hunt';
}
