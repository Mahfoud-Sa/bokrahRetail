import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import '../../domain/entities/app_release.dart';

/// A card widget representing an available release with its notes and action buttons.
class AppReleaseCard extends StatelessWidget {
  final AppRelease release;
  final bool isUpdateAvailable;
  final bool isArabic;
  final ValueChanged<String> onLaunchUrl;

  const AppReleaseCard({
    super.key,
    required this.release,
    required this.isUpdateAvailable,
    this.isArabic = true,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasDirectInstaller =
        release.downloadUrl != null && release.downloadUrl!.isNotEmpty;

    final headerText = isUpdateAvailable
        ? (isArabic ? 'تحديث متاح للتطبيق!' : 'Update Available!')
        : (isArabic ? 'أنت تستخدم أحدث إصدار' : "You're up to date");

    return Card(
      elevation: 0.5,
      color: isUpdateAvailable ? AppTheme.subtleSurface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUpdateAvailable ? AppTheme.actionBlue.withValues(alpha: 0.3) : AppTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUpdateAvailable ? Icons.system_update : Icons.check_circle,
                  color:
                      isUpdateAvailable ? AppTheme.actionBlue : AppTheme.success,
                ),
                const SizedBox(width: 8),
                Text(
                  headerText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUpdateAvailable
                        ? AppTheme.actionBlue
                        : AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              release.name.isNotEmpty ? release.name : release.tagName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(isArabic
                ? 'الإصدار: ${release.tagName}'
                : 'Version: ${release.tagName}'),
            if (release.publishedAt != null)
              Text(
                isArabic
                    ? 'تاريخ النشر: ${release.publishedAt!.toIso8601String().split('T').first}'
                    : 'Published: ${release.publishedAt!.toIso8601String().split('T').first}',
              ),
            if (release.body.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  release.body,
                  style: const TextStyle(height: 1.4, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (hasDirectInstaller)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: Text(
                    isArabic ? 'تحميل التحديث' : 'Download Update',
                  ),
                  onPressed: () => onLaunchUrl(release.downloadUrl!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.actionBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isArabic
                      ? 'لا يتوفر برنامج تثبيت مباشر لهذه المنصة. يمكنك زيارة صفحة الإصدار الرسمية لتنزيل الملفات المتاحة.'
                      : 'A direct installer is not available for this platform. You can visit the official release page to view and download release files.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              if (release.htmlUrl != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: Text(
                      isArabic ? 'عرض صفحة الإصدار' : 'View Release Page',
                    ),
                    onPressed: () => onLaunchUrl(release.htmlUrl!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.actionBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
            if (hasDirectInstaller && release.htmlUrl != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: Text(
                    isArabic ? 'عرض ملاحظات الإصدار' : 'View Release Notes',
                  ),
                  onPressed: () => onLaunchUrl(release.htmlUrl!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

