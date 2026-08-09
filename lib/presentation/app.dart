import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/routes/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/providers/settings_provider.dart';

/// Root widget for the AI Treasure Hunt application.
///
/// The application uses:
/// - Riverpod for state management
/// - GoRouter for navigation
/// - AppTheme for centralized Material 3 styling
class AITreasureHuntApp extends ConsumerWidget {
  const AITreasureHuntApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final languageCode = ref.watch(languageProvider);
    // Drive our AppStrings from settings; Material widgets use a safe locale.
    const materialSafe = <String>{
      'en',
      'hi',
      'es',
      'fr',
      'ar',
      'bn',
      'ta',
    };
    final materialLocale = Locale(
      materialSafe.contains(languageCode) ? languageCode : 'en',
    );

    return MaterialApp.router(
      title: 'AI Treasure Hunt',
      debugShowCheckedModeBanner: false,

      // Centralized Material 3 themes — driven by Settings.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      locale: materialLocale,
      supportedLocales: const <Locale>[
        Locale('en'),
        Locale('hi'),
        Locale('es'),
        Locale('fr'),
        Locale('ar'),
        Locale('bn'),
        Locale('ta'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // GoRouter configuration.
      routerConfig: router,
    );
  }
}
