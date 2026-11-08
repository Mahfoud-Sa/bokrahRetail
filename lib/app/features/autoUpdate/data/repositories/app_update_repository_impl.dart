import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/app_release.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../datasources/github_release_datasource.dart';
import '../datasources/update_preferences_datasource.dart';
import '../utils/platform_asset_matcher.dart';
import '../utils/version_comparator.dart';

typedef UrlLauncherFunction = Future<bool> Function(Uri uri, {LaunchMode mode});

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final GithubReleaseDatasource _releaseDatasource;
  final UpdatePreferencesDatasource _preferencesDatasource;
  final Future<PackageInfo> Function() _packageInfoProvider;
  final UrlLauncherFunction _urlLauncher;

  AppUpdateRepositoryImpl({
    required GithubReleaseDatasource releaseDatasource,
    required UpdatePreferencesDatasource preferencesDatasource,
    Future<PackageInfo> Function()? packageInfoProvider,
    UrlLauncherFunction? urlLauncher,
  })  : _releaseDatasource = releaseDatasource,
        _preferencesDatasource = preferencesDatasource,
        _packageInfoProvider = packageInfoProvider ?? PackageInfo.fromPlatform,
        _urlLauncher = urlLauncher ?? launchUrl;

  @override
  Future<AppRelease?> getLatestRelease() async {
    final releases = await _releaseDatasource.fetchReleases();
    if (releases.isEmpty) return null;

    Map<String, dynamic>? highestRelease;
    String? highestVersion;

    for (final release in releases) {
      final isDraft = release['draft'] == true;
      final isPrerelease = release['prerelease'] == true;
      if (isDraft || isPrerelease) continue;

      final tagName = release['tag_name']?.toString() ?? '';
      if (!VersionComparator.isValid(tagName)) continue;

      final cleanVersion = tagName.startsWith('v') || tagName.startsWith('V')
          ? tagName.substring(1)
          : tagName;

      if (highestRelease == null || highestVersion == null) {
        highestRelease = release;
        highestVersion = cleanVersion;
      } else {
        if (VersionComparator.compare(cleanVersion, highestVersion) > 0) {
          highestRelease = release;
          highestVersion = cleanVersion;
        }
      }
    }

    if (highestRelease == null || highestVersion == null) {
      return null;
    }

    final tagName = highestRelease['tag_name']?.toString() ?? '';
    DateTime? publishedDate;
    if (highestRelease['published_at'] != null) {
      publishedDate = DateTime.tryParse(highestRelease['published_at'].toString());
    }

    final assets = highestRelease['assets'] as List<dynamic>?;
    final downloadUrl = PlatformAssetMatcher.findInstallerUrl(assets);

    return AppRelease(
      version: highestVersion,
      tagName: tagName,
      name: highestRelease['name']?.toString() ?? tagName,
      body: highestRelease['body']?.toString() ?? '',
      publishedAt: publishedDate,
      downloadUrl: downloadUrl,
      htmlUrl: highestRelease['html_url']?.toString(),
    );
  }

  @override
  Future<String> getInstalledVersion() async {
    final info = await _packageInfoProvider();
    final version = info.version;
    final buildNumber = info.buildNumber;
    if (buildNumber.isNotEmpty && buildNumber != '0') {
      return '$version+$buildNumber';
    }
    return version;
  }

  @override
  bool isUpdateAvailable(String installedVersion, String latestVersion) {
    return VersionComparator.isNewer(installedVersion, latestVersion);
  }

  @override
  Future<void> skipVersion(String version) async {
    await _preferencesDatasource.setSkippedVersion(version);
  }

  @override
  Future<bool> isVersionSkipped(String version) async {
    final skipped = await _preferencesDatasource.getSkippedVersion();
    if (skipped == null) return false;
    // Skipped if the current release version is <= the skipped version tag
    return VersionComparator.compare(version, skipped) <= 0;
  }

  @override
  Future<bool> launchDownloadUrl(String url) async {
    final uri = Uri.parse(url);
    return await _urlLauncher(uri, mode: LaunchMode.externalApplication);
  }
}
