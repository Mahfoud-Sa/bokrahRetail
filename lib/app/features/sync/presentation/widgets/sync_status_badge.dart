import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/sync/presentation/cubits/sync_state.dart';
import 'package:flutter/material.dart';

/// Compact, testable status pill displaying the current store sync state.
class SyncStatusBadge extends StatelessWidget {
  final SyncState syncState;
  final VoidCallback? onTap;

  const SyncStatusBadge({
    super.key,
    required this.syncState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon, String label) = switch (syncState.phase) {
      SyncPhase.syncing => (
          AppTheme.actionBlue.withValues(alpha: 0.12),
          AppTheme.actionBlue,
          Icons.sync,
          'جاري المزامنة...',
        ),
      SyncPhase.conflict => (
          AppTheme.warmOrange.withValues(alpha: 0.14),
          AppTheme.warmOrange,
          Icons.warning_amber_rounded,
          'تعارض (${syncState.conflictCount})',
        ),
      SyncPhase.offlineOrError => (
          AppTheme.errorSurface,
          AppTheme.error,
          Icons.cloud_off_outlined,
          syncState.pendingCount > 0
              ? 'معلق (${syncState.pendingCount})'
              : 'تعذر المزامنة',
        ),
      SyncPhase.guestReadOnly => (
          AppTheme.subtleSurface,
          AppTheme.secondaryText,
          Icons.visibility_outlined,
          'وضع الضيف',
        ),
      SyncPhase.synced || SyncPhase.idle => syncState.pendingCount > 0
          ? (
              AppTheme.paleOrange,
              AppTheme.warmOrange,
              Icons.cloud_upload_outlined,
              'قيد الانتظار (${syncState.pendingCount})',
            )
          : (
              AppTheme.success.withValues(alpha: 0.12),
              AppTheme.success,
              Icons.cloud_done_outlined,
              'متزامن',
            ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
