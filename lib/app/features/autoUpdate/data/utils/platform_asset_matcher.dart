import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class PlatformAssetMatcher {
  PlatformAssetMatcher._();

  /// Finds the first matching installer asset URL for the active platform.
  /// [platformOverride] allows injecting platform type during testing.
  static String? findInstallerUrl(List<dynamic>? assets, {TargetPlatform? platformOverride}) {
    if (assets == null || assets.isEmpty) return null;

    final targetPlatform = platformOverride ?? _detectPlatform();

    final extensions = _extensionsForPlatform(targetPlatform);

    // First pass: Prioritize exact named installer 'bokrah-retailer-setup'
    for (final ext in extensions) {
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = asset['name']?.toString().toLowerCase() ?? '';
        if (name.endsWith(ext) &&
            (name.contains('bokrah-retailer-setup') ||
                name.contains('retailer-setup') ||
                name.contains('retail-setup'))) {
          final url = asset['browser_download_url']?.toString();
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
      }
    }

    // Second pass: Prioritize assets containing installer/setup/app keywords
    for (final ext in extensions) {
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = asset['name']?.toString().toLowerCase() ?? '';
        if (name.endsWith(ext) &&
            (name.contains('setup') ||
                name.contains('install') ||
                name.contains('retail') ||
                name.contains('bokrah'))) {
          final url = asset['browser_download_url']?.toString();
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
      }
    }

    // Second pass: Any asset ending with the matching platform extension
    for (final ext in extensions) {
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = asset['name']?.toString().toLowerCase() ?? '';
        if (name.endsWith(ext)) {
          final url = asset['browser_download_url']?.toString();
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
      }
    }

    return null;
  }

  static TargetPlatform _detectPlatform() {
    if (kIsWeb) return TargetPlatform.windows;
    if (Platform.isWindows) return TargetPlatform.windows;
    if (Platform.isAndroid) return TargetPlatform.android;
    if (Platform.isMacOS) return TargetPlatform.macOS;
    if (Platform.isLinux) return TargetPlatform.linux;
    if (Platform.isIOS) return TargetPlatform.iOS;
    return TargetPlatform.windows;
  }

  static List<String> _extensionsForPlatform(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.windows:
        return ['.exe', '.msi'];
      case TargetPlatform.android:
        return ['.apk'];
      case TargetPlatform.macOS:
        return ['.dmg', '.pkg', '.zip'];
      case TargetPlatform.linux:
        return ['.appimage', '.deb', '.tar.gz'];
      default:
        return ['.zip'];
    }
  }
}
