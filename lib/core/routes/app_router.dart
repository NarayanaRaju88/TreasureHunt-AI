import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../providers/service_providers.dart';
import '../theme/app_colors.dart';

import '../../features/auth/providers/auth_provider.dart';
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

/// ---------------------------------------------------------------------------
/// Application Routes
/// ---------------------------------------------------------------------------
///
/// Centralized route names and paths.
///
/// Named routes should be used throughout the application instead of hardcoded
/// strings. This makes navigation safer and easier to refactor.
class AppRoutes {
  AppRoutes._();

  // -------------------------------------------------------------------------
  // Route names
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Route paths
  // -------------------------------------------------------------------------

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

/// ---------------------------------------------------------------------------
/// Router Refresh Notifier
/// ---------------------------------------------------------------------------
///
/// GoRouter needs a Listenable to know when it should re-run redirect logic.
///
/// Riverpod auth state changes asynchronously, so this notifier acts as a
/// bridge between Riverpod and GoRouter.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier();

  void refresh() {
    notifyListeners();
  }
}

/// Provider for the router refresh notifier.
final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();

  ref.onDispose(notifier.dispose);

  return notifier;
});

/// ---------------------------------------------------------------------------
/// Navigator Keys
/// ---------------------------------------------------------------------------

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// ---------------------------------------------------------------------------
/// GoRouter Provider
/// ---------------------------------------------------------------------------
///
/// Creates the application's central GoRouter.
///
/// The router handles:
///
/// 1. Splash screen
/// 2. Onboarding
/// 3. Authentication
/// 4. Protected application routes
/// 5. Persistent bottom navigation shell
/// 6. Global navigation errors
///
/// Authentication state comes from [authStateProvider].
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshProvider);

  /// Listen to authentication state changes.
  ///
  /// Whenever Firebase reports a login/logout event, the router is refreshed
  /// and redirect logic runs again.
  ref.listen<AsyncValue<dynamic>>(
    authStateProvider,
    (previous, next) {
      refreshNotifier.refresh();
    },
  );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,

    /// Always start at splash.
    initialLocation: AppRoutes.splashPath,

    debugLogDiagnostics: true,

    /// Re-run redirects whenever auth state changes.
    refreshListenable: refreshNotifier,

    /// Global route error.
    errorBuilder: (context, state) {
      return _RouteErrorScreen(
        error: state.error,
      );
    },

    /// -----------------------------------------------------------------------
    /// Redirect Logic
    /// -----------------------------------------------------------------------
    ///
    /// Authentication flow:
    ///
    /// App start
    ///     ↓
    /// Splash
    ///     ↓
    /// Check onboarding
    ///     ↓
    /// ┌──────────────────────────┐
    /// │ Onboarding completed?    │
    /// └────────────┬─────────────┘
    ///              │
    ///       No     │     Yes
    ///       ↓      │      ↓
    /// Onboarding   │    Auth check
    ///       ↓      │      ↓
    ///     Login    │  Signed in?
    ///              │   /     \
    ///             Yes       No
    ///              ↓         ↓
    ///             Home      Login
    ///
    /// Note:
    /// The splash screen is allowed to render while auth state is loading.
    redirect: (context, state) {
      final location = state.matchedLocation;

      final authState = ref.read(authStateProvider);

      /// ---------------------------------------------------------------------
      /// 1. Always allow splash while the app is starting.
      /// ---------------------------------------------------------------------
      ///
      /// The splash screen is responsible for the initial startup experience.
      if (location == AppRoutes.splashPath) {
        return null;
      }

      /// ---------------------------------------------------------------------
      /// 2. Determine authentication status.
      /// ---------------------------------------------------------------------
      ///
      /// While auth state is loading, do not redirect prematurely.
      ///
      /// This prevents:
      ///
      /// Firebase starts
      ///      ↓
      /// authState = loading
      ///      ↓
      /// router thinks user is signed out
      ///      ↓
      /// incorrectly redirects to login
      ///
      /// Instead, splash should be used to wait for initialization.
      final bool authLoading = authState.isLoading;

      if (authLoading) {
        return AppRoutes.splashPath;
      }

      final user = authState.valueOrNull;
      final bool isSignedIn = user != null;

      /// ---------------------------------------------------------------------
      /// 3. Read onboarding status.
      /// ---------------------------------------------------------------------
      ///
      /// SharedPreferences is synchronous after initialization.
      final prefs = ref.read(sharedPreferencesProvider);

      final bool onboardingComplete =
          prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;

      /// ---------------------------------------------------------------------
      /// 4. Onboarding has NOT been completed.
      /// ---------------------------------------------------------------------
      if (!onboardingComplete) {
        /// If the user is already on onboarding, stay there.
        if (location == AppRoutes.onboardingPath) {
          return null;
        }

        /// Allow splash to remain visible.
        if (location == AppRoutes.splashPath) {
          return null;
        }

        /// Send first-time users to onboarding.
        return AppRoutes.onboardingPath;
      }

      /// ---------------------------------------------------------------------
      /// 5. Onboarding is complete.
      /// ---------------------------------------------------------------------
      ///
      /// The user should never return to onboarding unless the app explicitly
      /// resets the onboarding preference.
      if (location == AppRoutes.onboardingPath) {
        if (isSignedIn) {
          return AppRoutes.homePath;
        }

        return AppRoutes.loginPath;
      }

      /// ---------------------------------------------------------------------
      /// 6. User is NOT authenticated.
      /// ---------------------------------------------------------------------
      if (!isSignedIn) {
        /// Public authentication routes.
        final bool isPublicAuthRoute =
            location == AppRoutes.loginPath ||
            location == AppRoutes.registerPath ||
            location == AppRoutes.forgotPasswordPath;

        if (isPublicAuthRoute) {
          return null;
        }

        /// Prevent unauthenticated access to application routes.
        return AppRoutes.loginPath;
      }

      /// ---------------------------------------------------------------------
      /// 7. User IS authenticated.
      /// ---------------------------------------------------------------------
      ///
      /// Authenticated users should not return to login/register pages.
      final bool isAuthRoute =
          location == AppRoutes.loginPath ||
          location == AppRoutes.registerPath ||
          location == AppRoutes.forgotPasswordPath;

      if (isAuthRoute) {
        return AppRoutes.homePath;
      }

      /// Everything else is allowed.
      return null;
    },

    routes: <RouteBase>[
      // =====================================================================
      // Splash
      // =====================================================================

      GoRoute(
        name: AppRoutes.splash,
        path: AppRoutes.splashPath,
        pageBuilder: (context, state) {
          return _fade(
            state,
            const SplashScreen(),
          );
        },
      ),

      // =====================================================================
      // Onboarding
      // =====================================================================

      GoRoute(
        name: AppRoutes.onboarding,
        path: AppRoutes.onboardingPath,
        pageBuilder: (context, state) {
          return _fade(
            state,
            const OnboardingScreen(),
          );
        },
      ),

      // =====================================================================
      // Authentication
      // =====================================================================

      GoRoute(
        name: AppRoutes.login,
        path: AppRoutes.loginPath,
        pageBuilder: (context, state) {
          return _slide(
            state,
            const LoginScreen(),
          );
        },
      ),

      GoRoute(
        name: AppRoutes.register,
        path: AppRoutes.registerPath,
        pageBuilder: (context, state) {
          return _slide(
            state,
            const RegisterScreen(),
          );
        },
      ),

      GoRoute(
        name: AppRoutes.forgotPassword,
        path: AppRoutes.forgotPasswordPath,
        pageBuilder: (context, state) {
          return _slide(
            state,
            const ForgotPasswordScreen(),
          );
        },
      ),

      // =====================================================================
      // Discovery
      // =====================================================================
      ///
      /// Discovery is intentionally outside the shell so it opens as a
      /// full-screen route.
      ///
      GoRoute(
        name: AppRoutes.discovery,
        path: AppRoutes.discoveryPath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return _slide(
            state,
            const DiscoveryScreen(),
          );
        },
      ),

      // =====================================================================
      // Authenticated Application Shell
      // =====================================================================

      ShellRoute(
        navigatorKey: _shellNavigatorKey,

        builder: (context, state, child) {
          return MainShell(
            child: child,
          );
        },

        routes: <RouteBase>[
          // -----------------------------------------------------------------
          // Home
          // -----------------------------------------------------------------

          GoRoute(
            name: AppRoutes.home,
            path: AppRoutes.homePath,
            builder: (context, state) {
              return const HomeScreen();
            },
          ),

          // -----------------------------------------------------------------
          // Map
          // -----------------------------------------------------------------

          GoRoute(
            name: AppRoutes.map,
            path: AppRoutes.mapPath,
            builder: (context, state) {
              return const MapScreen();
            },
          ),

          // -----------------------------------------------------------------
          // Profile
          // -----------------------------------------------------------------

          GoRoute(
            name: AppRoutes.profile,
            path: AppRoutes.profilePath,
            builder: (context, state) {
              return const ProfileScreen();
            },
          ),

          // -----------------------------------------------------------------
          // Settings
          // -----------------------------------------------------------------

          GoRoute(
            name: AppRoutes.settings,
            path: AppRoutes.settingsPath,
            builder: (context, state) {
              return const SettingsScreen();
            },
          ),
        ],
      ),
    ],
  );
});

// =============================================================================
// Page Transitions
// =============================================================================

/// Fade transition used for splash and onboarding.
CustomTransitionPage<void> _fade(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppConstants.mediumAnimation,
    reverseTransitionDuration: AppConstants.mediumAnimation,
    transitionsBuilder:
        (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

/// Slide transition used for auth and full-screen feature routes.
CustomTransitionPage<void> _slide(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppConstants.mediumAnimation,
    reverseTransitionDuration: AppConstants.mediumAnimation,
    transitionsBuilder:
        (context, animation, secondaryAnimation, child) {
      final tween = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(
        CurveTween(
          curve: Curves.easeOutCubic,
        ),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

// =============================================================================
// Route Error Screen
// =============================================================================

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({
    this.error,
  });

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Not Found'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                size: 72,
                color: AppColors.error,
              ),

              const SizedBox(height: 16),

              Text(
                'Page not found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                error?.toString() ??
                    'The requested page does not exist.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: () {
                  context.goNamed(AppRoutes.home);
                },
                icon: const Icon(
                  Icons.home_rounded,
                ),
                label: const Text(
                  'Go Home',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
