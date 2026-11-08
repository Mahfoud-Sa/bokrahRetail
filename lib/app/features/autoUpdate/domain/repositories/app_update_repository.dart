import '../entities/app_release.dart';

abstract class AppUpdateRepository {
  Future<AppRelease?> getLatestRelease();
  Future<String> getInstalledVersion();
  bool isUpdateAvailable(String installedVersion, String latestVersion);
  Future<void> skipVersion(String version);
  Future<bool> isVersionSkipped(String version);
  Future<bool> launchDownloadUrl(String url);
}
