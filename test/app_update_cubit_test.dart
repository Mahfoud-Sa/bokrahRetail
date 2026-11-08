import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/entities/app_release.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/repositories/app_update_repository.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_state.dart';

class FakeAppUpdateRepository implements AppUpdateRepository {
  String installedVersion = '3.3.0';
  AppRelease? latestRelease;
  String? skippedVersion;
  bool shouldThrow = false;
  String? launchedUrl;

  @override
  Future<String> getInstalledVersion() async => installedVersion;

  @override
  Future<AppRelease?> getLatestRelease() async {
    if (shouldThrow) {
      throw Exception('Network connection timed out');
    }
    return latestRelease;
  }

  @override
  bool isUpdateAvailable(String installed, String latest) {
    final v1 = installed.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2 = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < v1.length && i < v2.length; i++) {
      if (v1[i] < v2[i]) return true;
      if (v1[i] > v2[i]) return false;
    }
    return v2.length > v1.length;
  }

  @override
  Future<void> skipVersion(String version) async {
    skippedVersion = version;
  }

  @override
  Future<bool> isVersionSkipped(String version) async {
    return skippedVersion == version;
  }

  @override
  Future<bool> launchDownloadUrl(String url) async {
    launchedUrl = url;
    return true;
  }
}

void main() {
  late FakeAppUpdateRepository repository;
  late AppUpdateCubit cubit;

  setUp(() {
    repository = FakeAppUpdateRepository();
    cubit = AppUpdateCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('AppUpdateCubit Tests', () {
    test('initial state defaults to AppUpdateInitial', () {
      expect(cubit.state, isA<AppUpdateInitial>());
      expect(cubit.state.hasUnskippedUpdate, isFalse);
    });

    test('manual check emits checking then available when new version exists', () async {
      repository.installedVersion = '3.3.0';
      repository.latestRelease = const AppRelease(
        version: '3.4.0',
        tagName: 'v3.4.0',
        name: 'Release 3.4.0',
        body: 'New features',
        downloadUrl: 'https://example.com/app.exe',
      );

      final future = cubit.checkForUpdates(isManual: true);

      expect(cubit.state, isA<AppUpdateChecking>());
      expect((cubit.state as AppUpdateChecking).isManual, isTrue);

      await future;

      expect(cubit.state, isA<AppUpdateAvailable>());
      final state = cubit.state as AppUpdateAvailable;
      expect(state.release.version, equals('3.4.0'));
      expect(state.hasUnskippedUpdate, isTrue);
      expect(state.isSkipped, isFalse);
    });

    test('manual check emits up to date when current version is latest', () async {
      repository.installedVersion = '3.4.0';
      repository.latestRelease = const AppRelease(
        version: '3.4.0',
        tagName: 'v3.4.0',
        name: 'Release 3.4.0',
        body: 'Up to date',
      );

      await cubit.checkForUpdates(isManual: true);

      expect(cubit.state, isA<AppUpdateUpToDate>());
      expect(cubit.state.hasUnskippedUpdate, isFalse);
    });

    test('manual check surfaces error state when request fails', () async {
      repository.shouldThrow = true;

      await cubit.checkForUpdates(isManual: true);

      expect(cubit.state, isA<AppUpdateError>());
      final state = cubit.state as AppUpdateError;
      expect(state.isManual, isTrue);
      expect(state.message, contains('Network connection timed out'));
    });

    test('background check suppresses error and falls back silently', () async {
      repository.shouldThrow = true;

      await cubit.checkForUpdates(isManual: false);

      expect(cubit.state, isA<AppUpdateInitial>());
      expect(cubit.state.hasUnskippedUpdate, isFalse);
    });

    test('skipping a version persists and marks isSkipped true', () async {
      repository.installedVersion = '3.3.0';
      repository.latestRelease = const AppRelease(
        version: '3.4.0',
        tagName: 'v3.4.0',
        name: 'Release 3.4.0',
        body: 'New features',
      );

      await cubit.checkForUpdates(isManual: true);
      expect((cubit.state as AppUpdateAvailable).hasUnskippedUpdate, isTrue);

      await cubit.skipVersion('3.4.0');

      expect(repository.skippedVersion, equals('3.4.0'));
      expect(cubit.state, isA<AppUpdateAvailable>());
      final state = cubit.state as AppUpdateAvailable;
      expect(state.isSkipped, isTrue);
      expect(state.hasUnskippedUpdate, isFalse);
    });

    test('manual check emits AppUpdateNoReleases when no release is available', () async {
      repository.installedVersion = '3.3.0';
      repository.latestRelease = null;

      await cubit.checkForUpdates(isManual: true);

      expect(cubit.state, isA<AppUpdateNoReleases>());
      expect((cubit.state as AppUpdateNoReleases).installedVersion, equals('3.3.0'));
      expect(cubit.state.hasUnskippedUpdate, isFalse);
    });

    test('manual check emits error without faking 0.0.0 if installed version lookup fails', () async {
      repository.installedVersion = '';
      repository.latestRelease = const AppRelease(
        version: '3.4.0',
        tagName: 'v3.4.0',
        name: '3.4.0',
        body: '',
      );

      await cubit.checkForUpdates(isManual: true);

      expect(cubit.state, isA<AppUpdateError>());
      final errorState = cubit.state as AppUpdateError;
      expect(errorState.installedVersion, isNot(equals('0.0.0')));
      expect(errorState.message, contains('installed'));
    });

    test('launchDownload delegates to repository launcher', () async {
      final success = await cubit.launchDownload('https://example.com/download.exe');
      expect(success, isTrue);
      expect(repository.launchedUrl, equals('https://example.com/download.exe'));
    });
  });
}
