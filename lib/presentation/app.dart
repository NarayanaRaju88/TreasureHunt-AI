import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/routes/app_router.dart';
import '../core/theme/app_theme.dart';

/// Root widget for the AI Treasure Hunt application.
///
/// The app uses:
/// - Riverpod for state management
/// - GoRouter for navigation
/// - AppTheme for centralized Material 3 styling
class AITreasureHuntApp extends ConsumerWidget {
  const AITreasureHuntApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'AI Treasure Hunt',
      debugShowCheckedModeBanner: false,

      // Centralized application theme.
      theme: AppTheme.light,

      // GoRouter configuration.
      routerConfig: router,
    );
  }
}
