import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bokrah_retail/app/features/autoUpdate/data/datasources/github_release_datasource.dart';
import 'package:bokrah_retail/app/features/autoUpdate/data/datasources/update_preferences_datasource.dart';
import 'package:bokrah_retail/app/features/autoUpdate/data/repositories/app_update_repository_impl.dart';

class MockGithubReleaseDatasource implements GithubReleaseDatasource {
  List<Map<String, dynamic>> releases = [];
  bool shouldThrow = false;

  @override
  Future<List<Map<String, dynamic>>> fetchReleases() async {
    if (shouldThrow) {
      throw Exception('GitHub API Rate Limit Exceeded');
    }
    return releases;
  }
}

class InMemoryUpdatePreferencesDatasource implements UpdatePreferencesDatasource {
  String? _skippedVersion;

  @override
  Future<String?> getSkippedVersion() async => _skippedVersion;

  @override
  Future<void> setSkippedVersion(String version) async {
    _skippedVersion = version;
  }

  @override
  Future<void> clearSkippedVersion() async {
    _skippedVersion = null;
  }
}

void main() {
  late MockGithubReleaseDatasource releaseDatasource;
  late InMemoryUpdatePreferencesDatasource prefsDatasource;
  late AppUpdateRepositoryImpl repository;
  String? launchedUri;
  bool launchResult = true;

  setUp(() {
    releaseDatasource = MockGithubReleaseDatasource();
    prefsDatasource = InMemoryUpdatePreferencesDatasource();
    launchedUri = null;
    launchResult = true;

    repository = AppUpdateRepositoryImpl(
      releaseDatasource: releaseDatasource,
      preferencesDatasource: prefsDatasource,
      packageInfoProvider: () async => PackageInfo(
        appName: 'Bokrah',
        packageName: 'com.example.bokrah',
        version: '3.3.0',
        buildNumber: '1',
      ),
      urlLauncher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
        launchedUri = uri.toString();
        return launchResult;
      },
    );
  });

  group('AppUpdateRepositoryImpl Tests', () {
    test('returns null when release list is empty', () async {
      releaseDatasource.releases = [];
      final release = await repository.getLatestRelease();
      expect(release, isNull);
    });

    test('ignores drafts and prereleases', () async {
      releaseDatasource.releases = [
        {
          'tag_name': 'v3.5.0',
          'name': 'Draft 3.5.0',
          'draft': true,
          'prerelease': false,
        },
        {
          'tag_name': 'v3.6.0-rc1',
          'name': 'RC 3.6.0',
          'draft': false,
          'prerelease': true,
        },
      ];

      final release = await repository.getLatestRelease();
      expect(release, isNull);
    });

    test('selects the highest valid stable release regardless of list order', () async {
      releaseDatasource.releases = [
        {
          'tag_name': 'v3.2.0',
          'name': 'Release 3.2.0',
          'draft': false,
          'prerelease': false,
          'body': 'Notes for 3.2.0',
          'published_at': '2026-01-01T00:00:00Z',
        },
        {
          'tag_name': 'v3.5.0',
          'name': 'Release 3.5.0',
          'draft': false,
          'prerelease': false,
          'body': 'Notes for 3.5.0',
          'published_at': '2026-03-01T00:00:00Z',
        },
        {
          'tag_name': 'v3.3.0',
          'name': 'Release 3.3.0',
          'draft': false,
          'prerelease': false,
          'body': 'Notes for 3.3.0',
          'published_at': '2026-02-01T00:00:00Z',
        },
        {
          'tag_name': 'nightly-build', // Malformed tag
          'name': 'Nightly',
          'draft': false,
          'prerelease': false,
        },
      ];

      final release = await repository.getLatestRelease();
      expect(release, isNotNull);
      expect(release!.version, equals('3.5.0'));
      expect(release.tagName, equals('v3.5.0'));
      expect(release.name, equals('Release 3.5.0'));
    });

    test('getInstalledVersion reads version and buildNumber', () async {
      final version = await repository.getInstalledVersion();
      expect(version, equals('3.3.0+1'));
    });

    test('skipVersion and isVersionSkipped threshold suppression', () async {
      await repository.skipVersion('3.4.0');

      expect(await repository.isVersionSkipped('3.3.0'), isTrue);
      expect(await repository.isVersionSkipped('3.4.0'), isTrue);
      // Higher release is NOT skipped
      expect(await repository.isVersionSkipped('3.5.0'), isFalse);
    });

    test('launchDownloadUrl delegates to launcher and returns result', () async {
      launchResult = true;
      final success = await repository.launchDownloadUrl('https://github.com/Mahfoud-Sa/bokrah/releases');
      expect(success, isTrue);
      expect(launchedUri, equals('https://github.com/Mahfoud-Sa/bokrah/releases'));

      launchResult = false;
      final failed = await repository.launchDownloadUrl('https://example.com/fail');
      expect(failed, isFalse);
    });
  });
}
