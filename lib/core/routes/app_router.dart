import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/discovery/screens/discovery_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/main_shell.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

/// Centralized route names and paths.
///
/// Using named routes everywhere avoids magic strings scattered across the
/// codebase and makes refactors safe.
class AppRoutes {
  AppRoutes._();

  // Names
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String home = 'home';
  static const String map = 'map';
  static const String discovery = 'discovery';
  static const String profile = 'profile';
  static const String settings = 'settings';

  // Paths
  static const String splashPath = '/';
  static const String onboardingPath = '/onboarding';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String forgotPasswordPath = '/forgot-password';
  static const String homePath = '/home';
  static const String mapPath = '/map';
  static const String discoveryPath = '/discovery';
  static const String profilePath = '/profile';
  static const String settingsPath = '/settings';
}

/// A [ChangeNotifier] used to trigger GoRouter refreshes from a Riverpod
/// stream (e.g. auth state changes). Kept generic so any future auth provider
/// can drive redirects.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier();

  void notify() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Global navigator keys. The root key owns the top-level navigator while the
/// shell key owns the persistent-nav navigator used by the main tabs.
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Provides the app's [GoRouter] instance.
///
/// Auth-gated feature screens (Home, Map, Profile, Settings) live inside a
/// [ShellRoute] so the bottom navigation bar persists across tab switches.
/// The Discovery screen is intentionally a top-level route so it is pushed
/// over the shell (full-screen, with its own back navigation) rather than
/// rendered as a tab.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splashPath,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.splash,
        path: AppRoutes.splashPath,
        pageBuilder: (context, state) => _fade(state, const SplashScreen()),
      ),
      GoRoute(
        name: AppRoutes.onboarding,
        path: AppRoutes.onboardingPath,
        pageBuilder: (context, state) => _fade(state, const OnboardingScreen()),
      ),
      GoRoute(
        name: AppRoutes.login,
        path: AppRoutes.loginPath,
        pageBuilder: (context, state) => _slide(state, const LoginScreen()),
      ),
      GoRoute(
        name: AppRoutes.register,
        path: AppRoutes.registerPath,
        pageBuilder: (context, state) => _slide(state, const RegisterScreen()),
      ),
      GoRoute(
        name: AppRoutes.forgotPassword,
        path: AppRoutes.forgotPasswordPath,
        pageBuilder: (context, state) =>
            _slide(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        name: AppRoutes.discovery,
        path: AppRoutes.discoveryPath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slide(state, const DiscoveryScreen()),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.home,
            path: AppRoutes.homePath,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            name: AppRoutes.map,
            path: AppRoutes.mapPath,
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            name: AppRoutes.profile,
            path: AppRoutes.profilePath,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            name: AppRoutes.settings,
            path: AppRoutes.settingsPath,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

// -----------------------------------------------------------------------------
// Transition helpers
// -----------------------------------------------------------------------------
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppConstants.mediumAnimation,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppConstants.mediumAnimation,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

// -----------------------------------------------------------------------------
// Error screen
// -----------------------------------------------------------------------------
class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 72, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'The requested page does not exist.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.goNamed(AppRoutes.home),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
