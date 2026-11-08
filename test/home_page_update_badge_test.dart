import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/entities/app_release.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/repositories/app_update_repository.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/app_update_screen.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/dialogs/update_prompt_dialog.dart';
import 'package:bokrah_retail/app/features/home/notification_page.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:bokrah_retail/app/features/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubAppUpdateRepository implements AppUpdateRepository {
  AppRelease? latestRelease;
  bool isAvailable = false;
  bool isSkipped = false;

  @override
  Future<AppRelease?> getLatestRelease() async => latestRelease;

  @override
  Future<String> getInstalledVersion() async => '3.3.0';

  @override
  bool isUpdateAvailable(String installedVersion, String latestVersion) => isAvailable;

  @override
  Future<bool> isVersionSkipped(String version) async => isSkipped;

  @override
  Future<void> skipVersion(String version) async {}

  @override
  Future<bool> launchDownloadUrl(String url) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StubAppUpdateRepository repository;
  late AppUpdateCubit updateCubit;
  late SettingsCubit settingsCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    repository = StubAppUpdateRepository();
    updateCubit = AppUpdateCubit(repository: repository);
    settingsCubit = SettingsCubit(
      localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
    );
  });

  tearDown(() {
    updateCubit.close();
    settingsCubit.close();
  });

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
        BlocProvider<AppUpdateCubit>.value(value: updateCubit),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomePage(),
      ),
    );
  }

  group('HomePage Update and Notification Tests', () {
    testWidgets('update button is hidden when no update is available', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final updateIconFinder = find.byIcon(Icons.system_update_alt_rounded);
      expect(updateIconFinder, findsNothing);

      // Red badge is also not found
      final redBadgeFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.color == Colors.red && decoration.shape == BoxShape.circle;
        }
        return false;
      });

      expect(redBadgeFinder, findsNothing);
    });

    testWidgets('tapping notification icon opens NotificationsPage and not AppUpdateScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final notifIconFinder = find.byIcon(Icons.notifications_outlined);
      expect(notifIconFinder, findsOneWidget);

      await tester.tap(notifIconFinder);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(AppUpdateScreen), findsNothing);
    });

    testWidgets('special update button appears on desktop topBar when an unskipped update is available and opens AppUpdateScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repository.latestRelease = const AppRelease(
        version: '3.4.0',
        tagName: 'v3.4.0',
        name: 'Release 3.4.0',
        body: 'New version',
      );
      repository.isAvailable = true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Dismiss the automatic session prompt dialog first if shown
      if (find.byType(UpdatePromptDialog).evaluate().isNotEmpty) {
        final navigator = Navigator.of(tester.element(find.byType(UpdatePromptDialog)));
        navigator.pop();
        await tester.pumpAndSettle();
      }

      final updateIconFinder = find.byIcon(Icons.system_update_alt_rounded);
      expect(updateIconFinder, findsOneWidget);

      final redBadgeFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.color == Colors.red && decoration.shape == BoxShape.circle;
        }
        return false;
      });
      expect(redBadgeFinder, findsWidgets);

      await tester.tap(updateIconFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AppUpdateScreen), findsOneWidget);
    });

    testWidgets('special update button appears on mobile AppBar when update is available and opens AppUpdateScreen', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repository.latestRelease = const AppRelease(
        version: '3.4.0',
        tagName: 'v3.4.0',
        name: 'Release 3.4.0',
        body: 'New version',
      );
      repository.isAvailable = true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Dismiss the automatic session prompt dialog first if shown
      if (find.byType(UpdatePromptDialog).evaluate().isNotEmpty) {
        final navigator = Navigator.of(tester.element(find.byType(UpdatePromptDialog)));
        navigator.pop();
        await tester.pumpAndSettle();
      }

      final updateIconFinder = find.byIcon(Icons.system_update_alt_rounded);
      expect(updateIconFinder, findsOneWidget);

      await tester.tap(updateIconFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AppUpdateScreen), findsOneWidget);
    });
  });
}
