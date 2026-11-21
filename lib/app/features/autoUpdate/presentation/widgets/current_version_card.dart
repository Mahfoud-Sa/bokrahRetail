import 'package:flutter/material.dart';

/// A card widget displaying the currently installed version and build number of the app.
class CurrentVersionCard extends StatelessWidget {
  final String installedVersion;
  final String buildNumber;
  final bool isArabic;

  const CurrentVersionCard({
    super.key,
    required this.installedVersion,
    required this.buildNumber,
    this.isArabic = true,
  });

  @override
  Widget build(BuildContext context) {
    final versionText = installedVersion.isNotEmpty
        ? installedVersion
        : (isArabic ? 'غير معروف' : 'Unknown');

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 44),
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? 'الإصدار الحالي: $versionText'
                  : 'Current Version: $versionText',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (buildNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                isArabic ? 'رقم البناء: $buildNumber' : 'Build: $buildNumber',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

