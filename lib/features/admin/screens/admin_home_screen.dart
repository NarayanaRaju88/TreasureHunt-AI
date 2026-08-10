import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/navigation/app_nav.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_provider.dart';

/// Admin console hub: overview stats + links to users and activity logs.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(isAdminProvider);
    final statsAsync = ref.watch(adminStatsProvider);

    return PopScope(
      canPop: context.routerCanPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.goBackOr();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: context.backOrHomeLeading(),
          title: const Text('Admin Console'),
        ),
        body: adminAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _Denied(),
          data: (isAdmin) {
            if (!isAdmin) return const _Denied();
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminStatsProvider);
                ref.invalidate(adminUsersProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: <Widget>[
                  Text(
                    'Operations overview',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Monitor who signs in, review activity, and manage explorers.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  statsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                    data: (stats) => Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _StatTile(
                          label: 'Users',
                          value: '${stats.userCount}',
                          icon: Icons.people_alt_rounded,
                          color: AppColors.primary,
                        ),
                        _StatTile(
                          label: 'Active today',
                          value: '${stats.activeToday}',
                          icon: Icons.bolt_rounded,
                          color: AppColors.accentDark,
                        ),
                        _StatTile(
                          label: 'Logins today',
                          value: '${stats.loginsToday}',
                          icon: Icons.login_rounded,
                          color: AppColors.secondary,
                        ),
                        _StatTile(
                          label: 'Guests',
                          value: '${stats.guestCount}',
                          icon: Icons.person_outline_rounded,
                          color: AppColors.tertiary,
                        ),
                        _StatTile(
                          label: 'Treasures',
                          value: '${stats.treasureCount}',
                          icon: Icons.travel_explore_rounded,
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AdminNavTile(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Users',
                    subtitle: 'See who registered and when they were last active',
                    onTap: () => context.pushNamed(AppRoutes.adminUsers),
                  ),
                  const SizedBox(height: 12),
                  _AdminNavTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'Activity logs',
                    subtitle: 'Login, logout, and session events in real time',
                    onTap: () => context.pushNamed(AppRoutes.adminLogs),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Denied extends StatelessWidget {
  const _Denied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.lock_outline_rounded,
                size: 56, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Admin access required',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an admins/{yourUid} document in Firebase Console '
              'or set the admin custom claim. See docs/ADMIN_SETUP.md.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.goBackOr(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (context.screenWidth - 44) / 2,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message.replaceFirst(RegExp(r'^[^:]+:\s*'), '')),
    );
  }
}
