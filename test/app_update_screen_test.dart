import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/entities/app_release.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/repositories/app_update_repository.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/app_update_screen.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';

class MockAppUpdateRepository implements AppUpdateRepository {
  AppRelease? latestRelease;
  bool isAvailable = false;
  bool shouldThrow = false;
  String? launchedUrl;
  bool launchResult = true;

  @override
  Future<AppRelease?> getLatestRelease() async {
    if (shouldThrow) throw Exception('API Rate Limit Exceeded');
    return latestRelease;
  }

  @override
  Future<String> getInstalledVersion() async => '3.3.0';

  @override
  bool isUpdateAvailable(String installedVersion, String latestVersion) => isAvailable;

  @override
  Future<bool> isVersionSkipped(String version) async => false;

  @override
  Future<void> skipVersion(String version) async {}

  @override
  Future<bool> launchDownloadUrl(String url) async {
    launchedUrl = url;
    return launchResult;
  }
}

void main() {
  late MockAppUpdateRepository repository;
  late AppUpdateCubit cubit;

  setUp(() {
    repository = MockAppUpdateRepository();
    cubit = AppUpdateCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: AppUpdateScreen(
          packageInfo: PackageInfo(
            appName: 'Bokrah Accounting',
            packageName: 'com.example.bokrah',
            version: '3.3.0',
            buildNumber: '1',
          ),
        ),
      ),
    );
  }

  group('AppUpdateScreen Tests', () {
    testWidgets('shows No Published Releases when repository has no releases', (tester) async {
      repository.latestRelease = null;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Published Releases'), findsOneWidget);
      expect(find.text('Check Again'), findsOneWidget);
    });

    testWidgets('shows Up to date when current version is latest', (tester) async {
      repository.latestRelease = const AppRelease(
        version: '3.3.0',
        tagName: 'v3.3.0',
        name: 'Release 3.3.0',
        body: 'Current build',
      );
      repository.isAvailable = false;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text("No updates available"), findsOneWidget);
      expect(find.text("You have the latest version of the app."), findsOneWidget);
    });

    testWidgets('shows Update Available with direct installer button when asset is available', (tester) async {
      repository.latestRelease = const AppRelease(
        version: '3.4.0',
        tagName: 'v3.4.0',
        name: 'Release 3.4.0',
        body: 'Exciting new features',
        downloadUrl: 'https://example.com/bokrah.exe',
        htmlUrl: 'https://example.com/release',
      );
      repository.isAvailable = true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Update Available!'), findsOneWidget);
      expect(find.text('Download Update'), findsOneWidget);
      expect(find.text('View Release Notes'), findsOneWidget);

      await tester.tap(find.text('Download Update'));
      await tester.pumpAndSettle();

      expect(repository.launchedUrl, equals('https://example.com/bokrah.exe'));
    });

    testWidgets('shows View Release Page when direct installer is missing', (tester) async {
      repository.latestRelease = const AppRelease(
        version: '3.4.0',
        tagName: 'v3.4.0',
        name: 'Release 3.4.0',
        body: 'New features',
        downloadUrl: null,
        htmlUrl: 'https://example.com/release-page',
      );
      repository.isAvailable = true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('View Release Page'), findsOneWidget);
      expect(find.textContaining('direct installer is not available'), findsOneWidget);

      await tester.tap(find.text('View Release Page'));
      await tester.pumpAndSettle();

      expect(repository.launchedUrl, equals('https://example.com/release-page'));
    });

    testWidgets('shows error state with Try Again button when request fails', (tester) async {
      repository.shouldThrow = true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Failed to check for updates'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Now fix failure and tap Try Again
      repository.shouldThrow = false;
      repository.latestRelease = null;

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('No Published Releases'), findsOneWidget);
    });
  });
}
