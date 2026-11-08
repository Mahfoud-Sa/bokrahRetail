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
    final title = widget.packageInfo?.appName.isNotEmpty == true
        ? widget.packageInfo!.appName
        : 'App Updates';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Check for updates',
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
                          'Current Version: ${installedVersion.isNotEmpty ? installedVersion : (widget.packageInfo?.version ?? 'Unknown')}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (buildNumber.isNotEmpty)
                          Text(
                            'Build: $buildNumber',
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
                  _buildErrorState(context, state.message)
                else if (state is AppUpdateAvailable)
                  _buildReleaseCard(context, state.release, isUpdateAvailable: true)
                else if (state is AppUpdateUpToDate)
                  _buildNoUpdatesState(state.release)
                else if (state is AppUpdateNoReleases)
                  _buildNoReleasesState()
                else
                  _buildInitialState(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context, String url) async {
    final success = await context.read<AppUpdateCubit>().launchDownload(url);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open external browser to download the installer.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _handleDownload(context, url),
          ),
        ),
      );
    }
  }

  Widget _buildReleaseCard(BuildContext context, AppRelease release, {required bool isUpdateAvailable}) {
    final hasDirectInstaller = release.downloadUrl != null && release.downloadUrl!.isNotEmpty;

    return Card(
      color: isUpdateAvailable ? Colors.blue[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUpdateAvailable ? Icons.system_update : Icons.check_circle,
                  color: isUpdateAvailable ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  isUpdateAvailable ? 'Update Available!' : "You're up to date",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUpdateAvailable ? Colors.blue : Colors.green,
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
            Text('Version: ${release.tagName}'),
            if (release.publishedAt != null)
              Text(
                'Published: ${release.publishedAt!.toIso8601String().split('T').first}',
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
                  label: const Text('Download Update'),
                  onPressed: () => _handleDownload(context, release.downloadUrl!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
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
                  color: Colors.amber.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'A direct installer is not available for this platform. You can visit the official release page to view and download release files.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              if (release.htmlUrl != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View Release Page'),
                    onPressed: () => _handleDownload(context, release.htmlUrl!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
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
                  label: const Text('View Release Notes'),
                  onPressed: () => _handleDownload(context, release.htmlUrl!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to check for updates',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUpdatesState(AppRelease? release) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No updates available',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('You have the latest version of the app.'),
            if (release != null && release.htmlUrl != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('View Latest Release Notes'),
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

  Widget _buildNoReleasesState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, color: Colors.blueGrey, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No Published Releases',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No official releases have been published for this repository yet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Check Again'),
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
