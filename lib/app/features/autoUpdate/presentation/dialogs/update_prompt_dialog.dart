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
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.blueAccent),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'New Version Available',
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
              'A new update is available: ${release.name.isNotEmpty ? release.name : release.tagName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Current version: $installedVersion'),
            Text('Latest version: ${release.tagName}'),
            if (release.body.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                "What's New:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    release.body,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
            if (release.downloadUrl == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'A direct installer was not found for this platform. You can visit the release page to view available files.',
                  style: TextStyle(fontSize: 12),
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
          child: const Text('Skip This Version'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () async {
            final targetUrl = release.downloadUrl ?? release.htmlUrl;
            if (targetUrl != null && targetUrl.isNotEmpty) {
              final success = await context.read<AppUpdateCubit>().launchDownload(targetUrl);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open external browser to download the installer.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          child: Text(release.downloadUrl != null ? 'Download Update' : 'View Release Page'),
        ),
      ],
    );
  }
}
