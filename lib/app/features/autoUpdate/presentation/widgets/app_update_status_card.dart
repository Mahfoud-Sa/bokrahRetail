import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import '../../domain/entities/app_release.dart';

/// Card widget displayed when an error occurs while checking for updates.
class AppUpdateErrorCard extends StatelessWidget {
  final String message;
  final bool isArabic;
  final VoidCallback onRetry;

  const AppUpdateErrorCard({
    super.key,
    required this.message,
    this.isArabic = true,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      color: AppTheme.errorSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'فشل التحقق من التحديثات' : 'Failed to check for updates',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget displayed when the app is already up to date.
class AppUpdateUpToDateCard extends StatelessWidget {
  final AppRelease? release;
  final bool isArabic;
  final ValueChanged<String>? onOpenReleaseNotes;

  const AppUpdateUpToDateCard({
    super.key,
    this.release,
    this.isArabic = true,
    this.onOpenReleaseNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'أنت تستخدم أحدث إصدار' : "You're up to date",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'لا توجد تحديثات جديدة متاحة حالياً.'
                  : 'You have the latest version of the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (release != null &&
                release!.htmlUrl != null &&
                onOpenReleaseNotes != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(
                  isArabic
                      ? 'عرض ملاحظات أحدث إصدار'
                      : 'View Latest Release Notes',
                ),
                onPressed: () => onOpenReleaseNotes!(release!.htmlUrl!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card widget displayed when no releases have been published yet for the repo.
class AppUpdateNoReleasesCard extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onRefresh;

  const AppUpdateNoReleasesCard({
    super.key,
    this.isArabic = true,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, color: AppTheme.mutedText, size: 48),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'لا توجد إصدارات منشورة' : 'No Published Releases',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'لم يتم نشر أي إصدارات رسمية لهذا المستودع حتى الآن.'
                  : 'No official releases have been published for this repository yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(isArabic ? 'إعادة التحقق' : 'Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}

