import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:bokrah_retail/app/config/theme.dart';
import 'cubits/app_update_cubit.dart';
import 'cubits/app_update_state.dart';
import 'widgets/app_release_card.dart';
import 'widgets/app_update_status_card.dart';
import 'widgets/current_version_card.dart';

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
      if (mounted) {
        context.read<AppUpdateCubit>().checkForUpdates(isManual: true);
      }
    });
  }

  void _refresh() {
    context.read<AppUpdateCubit>().checkForUpdates(isManual: true);
  }

  Future<void> _handleLaunchUrl(String url, {bool isArabic = false}) async {
    final success = await context.read<AppUpdateCubit>().launchDownload(url);
    if (!success && mounted) {
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
            onPressed: () => _handleLaunchUrl(url, isArabic: isArabic),
          ),
        ),
      );
    }
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
              tooltip: isArabic
                  ? 'التحقق من وجود تحديثات'
                  : 'Check for updates',
            ),
          ],
        ),
        body: BlocBuilder<AppUpdateCubit, AppUpdateState>(
          builder: (context, state) {
            final installedVersion = state.installedVersion.isNotEmpty
                ? state.installedVersion
                : (widget.packageInfo?.version ?? '');
            final buildNumber = widget.packageInfo?.buildNumber ?? '';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // 1. Current version info card
                  CurrentVersionCard(
                    installedVersion: installedVersion,
                    buildNumber: buildNumber,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 24),

                  // 2. Dynamic Update Status View
                  _buildStatusContent(state, isArabic),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusContent(AppUpdateState state, bool isArabic) {
    if (state is AppUpdateChecking) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is AppUpdateError) {
      return AppUpdateErrorCard(
        message: state.message,
        isArabic: isArabic,
        onRetry: _refresh,
      );
    }

    if (state is AppUpdateAvailable) {
      return AppReleaseCard(
        release: state.release,
        isUpdateAvailable: true,
        isArabic: isArabic,
        onLaunchUrl: (url) => _handleLaunchUrl(url, isArabic: isArabic),
      );
    }

    if (state is AppUpdateUpToDate) {
      return AppUpdateUpToDateCard(
        release: state.release,
        isArabic: isArabic,
        onOpenReleaseNotes: (url) =>
            _handleLaunchUrl(url, isArabic: isArabic),
      );
    }

    if (state is AppUpdateNoReleases) {
      return AppUpdateNoReleasesCard(
        isArabic: isArabic,
        onRefresh: _refresh,
      );
    }

    return const SizedBox.shrink();
  }
}

