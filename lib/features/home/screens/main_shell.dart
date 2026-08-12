import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/widgets/app_bottom_nav.dart';

/// Persistent shell for the main authenticated tabs (Home, Map, Profile,
/// Settings). Rendered via a `go_router` [ShellRoute] so the bottom navigation
/// bar stays mounted while the active tab's content is swapped in as [child].
///
/// The selected tab index is derived from the current route location, keeping
/// the [AppBottomNav] highlight in sync regardless of how navigation occurred
/// (tab tap, deep link, or programmatic `go`).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  /// The active child route's widget, injected by the [ShellRoute] builder.
  final Widget child;

  int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.mapPath)) return 1;
    if (location.startsWith(AppRoutes.profilePath)) return 2;
    if (location.startsWith(AppRoutes.settingsPath)) return 3;
    return 0; // Home (default)
  }

  bool _isHome(String location) =>
      location == AppRoutes.homePath || location.startsWith('${AppRoutes.homePath}/');

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final canPop = GoRouter.of(context).canPop();
    final onHome = _isHome(location);

    // Tab routes often have no stack. System back should return to Home
    // instead of exiting the app (exit only from Home when nothing to pop).
    return PopScope(
      canPop: canPop || onHome,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.goNamed(AppRoutes.home);
      },
      child: Scaffold(
        extendBody: true,
        body: child,
        bottomNavigationBar: AppBottomNav(
          currentIndex: _indexForLocation(location),
        ),
      ),
    );
  }
}
