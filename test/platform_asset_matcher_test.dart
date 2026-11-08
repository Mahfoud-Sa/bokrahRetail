import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/autoUpdate/data/utils/platform_asset_matcher.dart';

void main() {
  group('PlatformAssetMatcher Tests', () {
    test('returns null for empty or null assets', () {
      expect(PlatformAssetMatcher.findInstallerUrl(null), isNull);
      expect(PlatformAssetMatcher.findInstallerUrl([]), isNull);
    });

    test('selects .exe over .msi for Windows', () {
      final assets = [
        {'name': 'bokrah_setup.msi', 'browser_download_url': 'https://example.com/setup.msi'},
        {'name': 'bokrah_setup.exe', 'browser_download_url': 'https://example.com/setup.exe'},
      ];

      final url = PlatformAssetMatcher.findInstallerUrl(
        assets,
        platformOverride: TargetPlatform.windows,
      );
      expect(url, equals('https://example.com/setup.exe'));
    });

    test('selects .dmg over .zip for macOS', () {
      final assets = [
        {'name': 'source_archive.zip', 'browser_download_url': 'https://example.com/archive.zip'},
        {'name': 'bokrah.dmg', 'browser_download_url': 'https://example.com/bokrah.dmg'},
      ];

      final url = PlatformAssetMatcher.findInstallerUrl(
        assets,
        platformOverride: TargetPlatform.macOS,
      );
      expect(url, equals('https://example.com/bokrah.dmg'));
    });

    test('selects .apk for Android', () {
      final assets = [
        {'name': 'app-release.apk', 'browser_download_url': 'https://example.com/app.apk'},
        {'name': 'source.tar.gz', 'browser_download_url': 'https://example.com/source.tar.gz'},
      ];

      final url = PlatformAssetMatcher.findInstallerUrl(
        assets,
        platformOverride: TargetPlatform.android,
      );
      expect(url, equals('https://example.com/app.apk'));
    });

    test('returns null when no matching installer asset exists', () {
      final assets = [
        {'name': 'readme.txt', 'browser_download_url': 'https://example.com/readme.txt'},
      ];

      final url = PlatformAssetMatcher.findInstallerUrl(
        assets,
        platformOverride: TargetPlatform.windows,
      );
      expect(url, isNull);
    });
  });
}
