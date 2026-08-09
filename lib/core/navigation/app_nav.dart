import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_router.dart';

/// Shared navigation helpers so system back / Back buttons never strand users
/// on a screen with nowhere to go.
extension AppNavX on BuildContext {
  /// True when GoRouter can pop the current page.
  bool get routerCanPop => GoRouter.of(this).canPop();

  /// Pop if possible; otherwise jump to [fallbackRoute] (default: Home).
  void goBackOr({String fallbackRoute = AppRoutes.home}) {
    final router = GoRouter.of(this);
    if (router.canPop()) {
      router.pop();
    } else {
      goNamed(fallbackRoute);
    }
  }

  /// Leading control: Back when stacked, Home when this is the root page.
  Widget backOrHomeLeading({
    Color? color,
    String homeTooltip = 'Home',
    String backTooltip = 'Back',
  }) {
    if (routerCanPop) {
      return IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: color),
        tooltip: backTooltip,
        onPressed: () => goBackOr(),
      );
    }
    return IconButton(
      icon: Icon(Icons.home_rounded, color: color),
      tooltip: homeTooltip,
      onPressed: () => goNamed(AppRoutes.home),
    );
  }
}
