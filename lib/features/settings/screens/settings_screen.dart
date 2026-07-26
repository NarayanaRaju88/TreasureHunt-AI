import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';

/// Full settings screen: appearance, notifications, language, location,
/// legal links, an about section and account actions (logout / delete).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  LocationPermission? _permission;
  bool _checkingPermission = false;

  // Evening reminder is a lightweight local toggle (defaults on).
  bool _eveningReminder = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPermission());
  }

  Future<void> _refreshPermission() async {
    setState(() => _checkingPermission = true);
    try {
      final perm =
          await ref.read(locationServiceProvider).checkPermissionStatus();
      if (!mounted) return;
      setState(() => _permission = perm);
      await ref
          .read(settingsProvider.notifier)
          .setLocationPermission(_mapPermission(perm));
    } catch (_) {
      // ignore — display "unknown".
    } finally {
      if (mounted) setState(() => _checkingPermission = false);
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _checkingPermission = true);
    try {
      final perm = await ref.read(locationServiceProvider).requestPermissions();
      if (!mounted) return;
      setState(() => _permission = perm);
      await ref
          .read(settingsProvider.notifier)
          .setLocationPermission(_mapPermission(perm));
      if (mounted) context.showSnackBar('Location permission updated');
    } catch (_) {
      if (mounted) {
        context.showSnackBar(
          'Enable location from system settings to continue',
          isError: true,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => ref.read(locationServiceProvider).openAppSettings(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingPermission = false);
    }
  }

  LocationPermissionStatus _mapPermission(LocationPermission perm) {
    switch (perm) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.always:
        return LocationPermissionStatus.always;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unknown;
    }
  }

  Future<void> _pickMorningTime() async {
    final settings = ref.read(settingsProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: settings.morningNotifTime.toTimeOfDay(),
      helpText: 'Morning treasure reminder',
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setMorningNotifTime(picked);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      context.showSnackBar('Could not open link', isError: true);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can always sign back in later.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(currentUserProvider.notifier).logout();
    if (mounted) context.goNamed(AppRoutes.login);
  }

  Future<void> _deleteAccount() async {
    // First confirmation.
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently remove your profile, progress and '
          'discoveries. This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true) return;

    // Second (final) confirmation — requires typing to enable.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _ConfirmDeleteDialog(),
    );
    if (confirmed != true) return;

    try {
      await fb.FirebaseAuth.instance.currentUser?.delete();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          context.showSnackBar(
            'Please log in again before deleting your account.',
            isError: true,
          );
        }
        await ref.read(currentUserProvider.notifier).logout();
        if (mounted) context.goNamed(AppRoutes.login);
        return;
      }
    } catch (_) {
      // Fall through to sign-out regardless.
    }
    await ref.read(currentUserProvider.notifier).logout();
    if (mounted) {
      context.showSnackBar('Your account has been deleted.');
      context.goNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 120 + context.padding.bottom),
        children: <Widget>[
          // ---- Appearance -------------------------------------------------
          const _SectionHeader(
            icon: Icons.palette_rounded,
            title: 'Appearance',
          ),
          _Card(
            child: _ThemeSelector(
              value: settings.themeMode,
              onChanged: (mode) =>
                  ref.read(settingsProvider.notifier).setThemeMode(mode),
            ),
          ),

          // ---- Notifications ---------------------------------------------
          const _SectionHeader(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
          ),
          _Card(
            child: Column(
              children: <Widget>[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable notifications'),
                  subtitle:
                      const Text('Daily treasures, streaks and reminders'),
                  value: settings.notificationsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setNotificationsEnabled(v),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: settings.notificationsEnabled,
                  leading: const Icon(Icons.wb_sunny_rounded,
                      color: AppColors.accentDark),
                  title: const Text('Morning treasure time'),
                  subtitle: Text(
                    'Your daily treasure drops at '
                    '${settings.morningNotifTime.toTimeOfDay().format(context)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap:
                      settings.notificationsEnabled ? _pickMorningTime : null,
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.nightlight_round,
                      color: AppColors.tertiary),
                  title: const Text('Evening reminder'),
                  subtitle:
                      const Text('A nudge if you haven\'t explored today'),
                  value: settings.notificationsEnabled && _eveningReminder,
                  activeColor: AppColors.primary,
                  onChanged: settings.notificationsEnabled
                      ? (v) => setState(() => _eveningReminder = v)
                      : null,
                ),
              ],
            ),
          ),

          // ---- Language ---------------------------------------------------
          const _SectionHeader(
            icon: Icons.language_rounded,
            title: 'Language',
          ),
          _Card(
            child: Column(
              children: <Widget>[
                _LanguageTile(
                  label: 'English',
                  code: 'en',
                  selected: settings.language == 'en',
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setLanguage('en'),
                ),
                const Divider(height: 1),
                _LanguageTile(
                  label: 'हिन्दी (Hindi)',
                  code: 'hi',
                  selected: settings.language == 'hi',
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setLanguage('hi'),
                ),
                const Divider(height: 1),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: false,
                  leading: Icon(Icons.more_horiz_rounded),
                  title: Text('More languages'),
                  subtitle: Text('Coming soon'),
                ),
              ],
            ),
          ),

          // ---- Location ---------------------------------------------------
          const _SectionHeader(
            icon: Icons.location_on_rounded,
            title: 'Location',
          ),
          _Card(
            child: _LocationTile(
              permission: _permission,
              busy: _checkingPermission,
              onRequest: _requestPermission,
            ),
          ),

          // ---- Legal ------------------------------------------------------
          const _SectionHeader(
            icon: Icons.gavel_rounded,
            title: 'Legal',
          ),
          _Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_rounded,
                      color: AppColors.primary),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_rounded,
                      color: AppColors.primary),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openUrl(AppConstants.termsUrl),
                ),
              ],
            ),
          ),

          // ---- About ------------------------------------------------------
          const _SectionHeader(
            icon: Icons.info_rounded,
            title: 'About',
          ),
          _Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.travel_explore_rounded,
                      color: AppColors.primary),
                  title: const Text(AppConstants.appName),
                  subtitle: const Text(AppConstants.appTagline),
                  trailing: Text(
                    'v${AppConstants.appVersion}',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.favorite_rounded, color: AppColors.error),
                  title: Text('Made with Flutter & AI'),
                  subtitle: Text('Developed by the AI Treasure Hunt team'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mail_rounded,
                      color: AppColors.secondary),
                  title: const Text('Contact support'),
                  subtitle: const Text(AppConstants.supportEmail),
                  onTap: () => _openUrl('mailto:${AppConstants.supportEmail}'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ---- Account actions -------------------------------------------
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ---- Danger zone ------------------------------------------------
          _DangerZone(
            isGuest: user?.isGuest ?? false,
            onDelete: _deleteAccount,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Theme selector (System / Light / Dark)
// =============================================================================
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = <(ThemeMode, IconData, String)>[
      (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
      (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
    ];
    return Row(
      children: <Widget>[
        for (final opt in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ThemeOption(
                icon: opt.$2,
                label: opt.$3,
                selected: value == opt.$1,
                onTap: () => onChanged(opt.$1),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              color: selected
                  ? AppColors.primary
                  : context.colors.onSurfaceVariant,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : context.colors.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Language tile
// =============================================================================
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: selected
            ? AppColors.primary
            : context.colors.surfaceContainerHighest,
        child: Text(
          code.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : context.colors.onSurfaceVariant,
          ),
        ),
      ),
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : const Icon(Icons.radio_button_unchecked_rounded),
    );
  }
}

// =============================================================================
// Location tile
// =============================================================================
class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.permission,
    required this.busy,
    required this.onRequest,
  });

  final LocationPermission? permission;
  final bool busy;
  final VoidCallback onRequest;

  ({String label, Color color, IconData icon}) get _status {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return (label: 'Granted', color: AppColors.success, icon: Icons.check_circle_rounded);
      case LocationPermission.denied:
        return (label: 'Denied', color: AppColors.warning, icon: Icons.error_rounded);
      case LocationPermission.deniedForever:
        return (label: 'Blocked', color: AppColors.error, icon: Icons.block_rounded);
      default:
        return (label: 'Unknown', color: AppColors.grey500, icon: Icons.help_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(s.icon, color: s.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Location permission',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    s.label,
                    style: context.textTheme.bodySmall?.copyWith(color: s.color),
                  ),
                ],
              ),
            ),
            if (!granted)
              FilledButton(
                onPressed: busy ? null : onRequest,
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Grant'),
              ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Danger zone
// =============================================================================
class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.isGuest, required this.onDelete});

  final bool isGuest;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Deleting your account is permanent and removes all your progress, '
            'badges and discoveries.',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Delete Account'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Final delete confirmation (type-to-confirm)
// =============================================================================
class _ConfirmDeleteDialog extends StatefulWidget {
  const _ConfirmDeleteDialog();

  @override
  State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _enabled = false;

  static const String _phrase = 'DELETE';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm deletion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Type "$_phrase" to permanently delete your account.'),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: _phrase,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(
              () => _enabled = v.trim().toUpperCase() == _phrase,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              _enabled ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Delete forever'),
        ),
      ],
    );
  }
}

// =============================================================================
// Shared layout helpers
// =============================================================================
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }
}
