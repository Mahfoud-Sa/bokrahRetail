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
