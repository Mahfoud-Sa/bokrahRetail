import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/entities/app_release.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/repositories/app_update_repository.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/dialogs/update_prompt_dialog.dart';

class MockAppUpdateRepository implements AppUpdateRepository {
  String? skippedVersion;
  String? launchedUrl;
  bool launchResult = true;

  @override
  Future<AppRelease?> getLatestRelease() async => null;

  @override
  Future<String> getInstalledVersion() async => '3.3.0';

  @override
  bool isUpdateAvailable(String installedVersion, String latestVersion) => true;

  @override
  Future<bool> isVersionSkipped(String version) async => false;

  @override
  Future<void> skipVersion(String version) async {
    skippedVersion = version;
  }

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

  Widget buildTestWidget(AppRelease release) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: UpdatePromptDialog(
            release: release,
            installedVersion: '3.3.0',
          ),
        ),
      ),
    );
  }

  group('UpdatePromptDialog Tests', () {
    testWidgets('shows direct installer action when downloadUrl is present', (tester) async {
      const release = AppRelease(
        version: '3.4.0',
        tagName: 'v3.4.0',
        name: 'Release 3.4.0',
        body: 'Bug fixes',
        downloadUrl: 'https://example.com/app.exe',
        htmlUrl: 'https://example.com/release',
      );

      await tester.pumpWidget(buildTestWidget(release));

      expect(find.text('Download Update'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('Skip This Version'), findsOneWidget);

      await tester.tap(find.text('Download Update'));
      await tester.pumpAndSettle();

      expect(repository.launchedUrl, equals('https://example.com/app.exe'));
    });

    testWidgets('shows View Release Page when direct installer is absent', (tester) async {
      const release = AppRelease(
        version: '3.4.0',
        tagName: 'v3.4.0',
        name: 'Release 3.4.0',
        body: 'Bug fixes',
        downloadUrl: null,
        htmlUrl: 'https://example.com/release-page',
      );

      await tester.pumpWidget(buildTestWidget(release));

      expect(find.text('View Release Page'), findsOneWidget);
      expect(find.textContaining('direct installer was not found'), findsOneWidget);

      await tester.tap(find.text('View Release Page'));
      await tester.pumpAndSettle();

      expect(repository.launchedUrl, equals('https://example.com/release-page'));
    });

    testWidgets('Skip this version calls cubit.skipVersion', (tester) async {
      const release = AppRelease(
        version: '3.4.0',
        tagName: 'v3.4.0',
        name: 'Release 3.4.0',
        body: '',
        downloadUrl: 'https://example.com/app.exe',
      );

      await tester.pumpWidget(buildTestWidget(release));

      await tester.tap(find.text('Skip This Version'));
      await tester.pumpAndSettle();

      expect(repository.skippedVersion, equals('3.4.0'));
    });
  });
}
