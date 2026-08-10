import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/navigation/app_nav.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../domain/models/activity_log_model.dart';
import '../providers/admin_provider.dart';

/// Live feed of login / logout / session activity for admins.
class AdminLogsScreen extends ConsumerWidget {
  const AdminLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminActivityLogsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: context.backOrHomeLeading(),
        title: const Text('Activity logs'),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e.toString().contains('permission')
                  ? 'Admin permission required to read logs.'
                  : e.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text('No activity yet. New logins will appear here.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _LogTile(log: logs[index]),
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final ActivityLogModel log;

  Color get _color {
    switch (log.action) {
      case 'logout':
        return AppColors.grey500;
      case 'register':
        return AppColors.accentDark;
      case 'login_guest':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: _color.withValues(alpha: 0.15),
            child: Icon(Icons.history_rounded, color: _color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  log.actionLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _color,
                  ),
                ),
                Text(
                  '${log.displayName.isEmpty ? 'User' : log.displayName}'
                  '${log.email.isEmpty ? '' : ' · ${log.email}'}',
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppUtils.formatDate(log.createdAt)}'
                  '${log.platform == null ? '' : ' · ${log.platform}'}'
                  '${log.isGuest ? ' · guest' : ''}',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
