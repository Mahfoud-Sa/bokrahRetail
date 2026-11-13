import 'package:bokrah_retail/app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../domain/entities/app_release.dart';
import 'cubits/app_update_cubit.dart';
import 'cubits/app_update_state.dart';

class AppUpdateScreen extends StatefulWidget {
  final PackageInfo? packageInfo;

  const AppUpdateScreen({super.key, this.packageInfo});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppUpdateCubit>().checkForUpdates(isManual: true);
    });
  }

  void _refresh() {
    context.read<AppUpdateCubit>().checkForUpdates(isManual: true);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final title = widget.packageInfo?.appName.isNotEmpty == true
        ? widget.packageInfo!.appName
        : (isArabic ? 'تحديثات التطبيق' : 'App Updates');

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: isArabic ? 'التحقق من وجود تحديثات' : 'Check for updates',
            ),
          ],
        ),
        body: BlocBuilder<AppUpdateCubit, AppUpdateState>(
          builder: (context, state) {
            final installedVersion = state is AppUpdateInitial
                ? state.installedVersion
                : (state is AppUpdateChecking
                    ? state.installedVersion
                    : (state is AppUpdateAvailable
                        ? state.installedVersion
                        : (state is AppUpdateUpToDate
                            ? state.installedVersion
                            : (state is AppUpdateError
                                ? state.installedVersion
                                : (widget.packageInfo?.version ?? '')))));

            final buildNumber = widget.packageInfo?.buildNumber ?? '';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Current version info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.info_outline, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'الإصدار الحالي: ${installedVersion.isNotEmpty ? installedVersion : (widget.packageInfo?.version ?? 'غير معروف')}'
                                : 'Current Version: ${installedVersion.isNotEmpty ? installedVersion : (widget.packageInfo?.version ?? 'Unknown')}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (buildNumber.isNotEmpty)
                            Text(
                              isArabic ? 'رقم البناء: $buildNumber' : 'Build: $buildNumber',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Update status dynamic view
                  if (state is AppUpdateChecking)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is AppUpdateError)
                    _buildErrorState(context, state.message, isArabic: isArabic)
                  else if (state is AppUpdateAvailable)
                    _buildReleaseCard(context, state.release, isUpdateAvailable: true, isArabic: isArabic)
                  else if (state is AppUpdateUpToDate)
                    _buildNoUpdatesState(state.release, isArabic: isArabic)
                  else if (state is AppUpdateNoReleases)
                    _buildNoReleasesState(isArabic: isArabic)
                  else
                    _buildInitialState(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context, String url, {bool isArabic = false}) async {
    final success = await context.read<AppUpdateCubit>().launchDownload(url);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تعذر فتح المتصفح الخارجي لتنزيل برنامج التثبيت.'
                : 'Could not open external browser to download the installer.',
          ),
          backgroundColor: AppTheme.error,
          action: SnackBarAction(
            label: isArabic ? 'إعادة المحاولة' : 'Retry',
            textColor: Colors.white,
            onPressed: () => _handleDownload(context, url, isArabic: isArabic),
          ),
        ),
      );
    }
  }

  Widget _buildReleaseCard(
    BuildContext context,
    AppRelease release, {
    required bool isUpdateAvailable,
    bool isArabic = false,
  }) {
    final hasDirectInstaller = release.downloadUrl != null && release.downloadUrl!.isNotEmpty;

    final headerText = isUpdateAvailable
        ? (isArabic ? 'تحديث متاح للتطبيق!' : 'Update Available!')
        : (isArabic ? 'أنت تستخدم أحدث إصدار' : "You're up to date");

    return Card(
      color: isUpdateAvailable ? AppTheme.subtleSurface : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUpdateAvailable ? Icons.system_update : Icons.check_circle,
                  color: isUpdateAvailable ? AppTheme.actionBlue : AppTheme.success,
                ),
                const SizedBox(width: 8),
                Text(
                  headerText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUpdateAvailable ? AppTheme.actionBlue : AppTheme.success,
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
            Text(isArabic ? 'الإصدار: ${release.tagName}' : 'Version: ${release.tagName}'),
            if (release.publishedAt != null)
              Text(
                isArabic
                    ? 'تاريخ النشر: ${release.publishedAt!.toIso8601String().split('T').first}'
                    : 'Published: ${release.publishedAt!.toIso8601String().split('T').first}',
              ),
            if (release.body.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(release.body),
            ],
            const SizedBox(height: 16),
            if (hasDirectInstaller)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: Text(isArabic ? 'تحميل التحديث' : 'Download Update'),
                  onPressed: () => _handleDownload(context, release.downloadUrl!, isArabic: isArabic),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.actionBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningSurface,
                  borderRadius: BorderRadius.circular(6),
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
                    label: Text(isArabic ? 'عرض صفحة الإصدار' : 'View Release Page'),
                    onPressed: () => _handleDownload(context, release.htmlUrl!, isArabic: isArabic),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.actionBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                  label: Text(isArabic ? 'عرض ملاحظات الإصدار' : 'View Release Notes'),
                  onPressed: () => _handleDownload(context, release.htmlUrl!, isArabic: isArabic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, {bool isArabic = false}) {
    return Card(
      color: AppTheme.errorSurface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'فشل التحقق من التحديثات' : 'Failed to check for updates',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: Text(isArabic ? 'إعادة المحاولة' : 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUpdatesState(AppRelease? release, {bool isArabic = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد تحديثات متاحة' : 'No updates available',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'أنت تستخدم أحدث إصدار من التطبيق.'
                  : 'You have the latest version of the app.',
            ),
            if (release != null && release.htmlUrl != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: Text(isArabic ? 'عرض ملاحظات أحدث إصدار' : 'View Latest Release Notes'),
                onPressed: () {
                  context.read<AppUpdateCubit>().launchDownload(release.htmlUrl!);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoReleasesState({bool isArabic = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, color: AppTheme.mutedText, size: 48),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد إصدارات منشورة' : 'No Published Releases',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'لم يتم نشر أي إصدارات رسمية لهذا المستودع حتى الآن.'
                  : 'No official releases have been published for this repository yet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: Text(isArabic ? 'إعادة التحقق' : 'Check Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return const SizedBox.shrink();
  }
}
