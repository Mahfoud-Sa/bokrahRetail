import 'package:bokrah_retail/app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app_release.dart';
import '../cubits/app_update_cubit.dart';

class UpdatePromptDialog extends StatelessWidget {
  final AppRelease release;
  final String installedVersion;

  const UpdatePromptDialog({
    super.key,
    required this.release,
    required this.installedVersion,
  });

  static Future<void> show(
    BuildContext context, {
    required AppRelease release,
    required String installedVersion,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AppUpdateCubit>(),
        child: UpdatePromptDialog(
          release: release,
          installedVersion: installedVersion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: AppTheme.actionBlue),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isArabic ? 'يتوفر إصدار جديد' : 'New Version Available',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actionsOverflowDirection: VerticalDirection.down,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic
                    ? 'يتوفر تحديث جديد: ${release.name.isNotEmpty ? release.name : release.tagName}'
                    : 'A new update is available: ${release.name.isNotEmpty ? release.name : release.tagName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'الإصدار الحالي: $installedVersion'
                    : 'Current version: $installedVersion',
              ),
              Text(
                isArabic
                    ? 'أحدث إصدار: ${release.tagName}'
                    : 'Latest version: ${release.tagName}',
              ),
              if (release.body.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  isArabic ? 'ما الجديد في هذا الإصدار:' : "What's New:",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.subtleSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      release.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.4,
                          ),
                    ),
                  ),
                ),
              ],
              if (release.downloadUrl == null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isArabic
                        ? 'لم يتم العثور على مثبت مباشر لهذا النظام. يمكنك الانتقال إلى صفحة الإصدار لتنزيل الملفات المتاحة.'
                        : 'A direct installer was not found for this platform. You can visit the release page to view available files.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AppUpdateCubit>().skipVersion(release.version);
              Navigator.of(context).pop();
            },
            child: Text(isArabic ? 'تخطي هذا الإصدار' : 'Skip This Version'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(isArabic ? 'لاحقاً' : 'Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              final targetUrl = release.downloadUrl ?? release.htmlUrl;
              if (targetUrl != null && targetUrl.isNotEmpty) {
                final success = await context.read<AppUpdateCubit>().launchDownload(targetUrl);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'تعذر فتح المتصفح الخارجي لتنزيل برنامج التثبيت.'
                            : 'Could not open external browser to download the installer.',
                      ),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.actionBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              release.downloadUrl != null
                  ? (isArabic ? 'تحميل التحديث' : 'Download Update')
                  : (isArabic ? 'عرض صفحة الإصدار' : 'View Release Page'),
            ),
          ),
        ],
      ),
    );
  }
}
