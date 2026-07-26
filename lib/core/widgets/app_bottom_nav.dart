import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../extensions/context_extensions.dart';
import '../routes/app_router.dart';
import '../theme/app_colors.dart';

/// A single destination in the [AppBottomNav].
class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.routeName,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String routeName;
}

/// A floating, pill-shaped bottom navigation bar with Home, Map, Profile and
/// Settings tabs.
///
/// Pass the [currentIndex] to highlight the active tab. Tapping a tab uses
/// `go_router` to navigate to the corresponding named route. Provide
/// [onTap] to override the default navigation behavior.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  static const List<_NavDestination> _destinations = <_NavDestination>[
    _NavDestination(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      routeName: AppRoutes.home,
    ),
    _NavDestination(
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: 'Map',
      routeName: AppRoutes.map,
    ),
    _NavDestination(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      routeName: AppRoutes.profile,
    ),
    _NavDestination(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      routeName: AppRoutes.settings,
    ),
  ];

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }
    if (index == currentIndex) return;
    context.goNamed(_destinations[index].routeName);
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = context.isDarkMode;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: dark
              ? AppColors.darkSurface.withValues(alpha: 0.96)
              : AppColors.lightSurface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List<Widget>.generate(_destinations.length, (i) {
            final dest = _destinations[i];
            final bool active = i == currentIndex;
            return Expanded(
              child: _NavItem(
                destination: dest,
                active: active,
                onTap: () => _handleTap(context, i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              active ? destination.activeIcon : destination.icon,
              color: active ? AppColors.primary : context.colors.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? AppColors.primary
                    : context.colors.onSurfaceVariant,
              ),
              child: Text(destination.label),
            ),
          ],
        ),
      ),
    );
  }
}
