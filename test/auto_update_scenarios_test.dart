import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/services/mock_auth_service.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/autoUpdate/data/utils/platform_asset_matcher.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/entities/app_release.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/repositories/app_update_repository.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/app_update_screen.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/dialogs/update_prompt_dialog.dart';
import 'package:bokrah_retail/app/features/home/home_page.dart';
import 'package:bokrah_retail/app/features/restaurant/data/services/restaurant_service.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/restaurant_cubit.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';

class ScenarioUpdateRepository implements AppUpdateRepository {
  String installedVersion = '3.4.0';
  AppRelease? latestRelease;
  String? skippedVersion;
  bool shouldThrow = false;
  String? launchedDownloadUrl;

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
    final v1 = installed.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2 = latest.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
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
    if (skippedVersion == null) return false;
    final v1 = version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2 = skippedVersion!.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < v1.length && i < v2.length; i++) {
      if (v1[i] < v2[i]) return true;
      if (v1[i] > v2[i]) return false;
    }
    return v1.length <= v2.length;
  }

  @override
  Future<bool> launchDownloadUrl(String url) async {
    launchedDownloadUrl = url;
    return true;
  }
}

void main() {
  late SharedPreferences prefs;
  late SharedPrefsAuthTokenStorage tokenStorage;
  late MockAuthService authService;
  late AuthCubit authCubit;
  late SettingsCubit settingsCubit;
  late ScenarioUpdateRepository repository;
  late AppUpdateCubit updateCubit;
  late SessionCubit sessionCubit;
  late RestaurantCubit restaurantCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
    authService = MockAuthService(
      tokenStorage: tokenStorage,
      simulatedLatency: Duration.zero,
    );
    authCubit = AuthCubit(authService: authService);
    authCubit.continueAsGuest();

    settingsCubit = SettingsCubit(
      localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
    );
    repository = ScenarioUpdateRepository();
    updateCubit = AppUpdateCubit(repository: repository);
    sessionCubit = SessionCubit(
      usersService: UsersService(),
      initialOperator: UserEntity(
        name: 'Guest User',
        email: 'guest@bokrah.com',
        role: OperatorRole.cashier,
      ),
    );
    restaurantCubit = RestaurantCubit(service: RestaurantService());
  });

  tearDown(() {
    updateCubit.close();
    settingsCubit.close();
    authCubit.close();
    sessionCubit.close();
    restaurantCubit.close();
  });

  Widget buildScenarioApp({required GoRouter router}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<AppUpdateCubit>.value(value: updateCubit),
        BlocProvider<SessionCubit>.value(value: sessionCubit),
        BlocProvider<RestaurantCubit>.value(value: restaurantCubit),
      ],
      child: BlocBuilder<SettingsCubit, dynamic>(
        builder: (context, _) {
          return MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('Auto-Update Scenario Tests', () {
    testWidgets('Scenario 1: Startup check displays UpdatePromptDialog and topBar badge when new version is available',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const installerUrl =
          'https://github.com/Mahfoud-Sa/bokrah/releases/download/v3.5.0/bokrah-retailer-setup-v3.5.0.exe';

      repository.installedVersion = '3.4.0';
      repository.latestRelease = const AppRelease(
        version: '3.5.0',
        tagName: 'v3.5.0',
        name: 'Release 3.5.0',
        body: 'New cashier features and optimizations',
        downloadUrl: installerUrl,
      );

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(buildScenarioApp(router: router));
      await tester.pumpAndSettle();

      // Update prompt dialog is presented
      expect(find.byType(UpdatePromptDialog), findsOneWidget);
      expect(find.text('New Version Available'), findsOneWidget);
      expect(find.text('Download Update'), findsOneWidget);

      // TopBar update action button is also present
      expect(find.byIcon(Icons.system_update_alt_rounded), findsOneWidget);
    });

    testWidgets('Scenario 2: User clicks Later - dialog closes, topBar action button remains accessible',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repository.installedVersion = '3.4.0';
      repository.latestRelease = const AppRelease(
        version: '3.5.0',
        tagName: 'v3.5.0',
        name: 'Release 3.5.0',
        body: 'Bug fixes',
        downloadUrl: 'https://example.com/bokrah-retailer-setup-v3.5.0.exe',
      );

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(buildScenarioApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(UpdatePromptDialog), findsOneWidget);

      // User chooses Later
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.byType(UpdatePromptDialog), findsNothing);

      // TopBar action button remains visible so user can upgrade when ready
      expect(find.byIcon(Icons.system_update_alt_rounded), findsOneWidget);
      expect(repository.skippedVersion, isNull);
    });

    testWidgets('Scenario 3: User skips version - preference is saved and topBar button disappears', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repository.installedVersion = '3.4.0';
      repository.latestRelease = const AppRelease(
        version: '3.5.0',
        tagName: 'v3.5.0',
        name: 'Release 3.5.0',
        body: 'Improvements',
        downloadUrl: 'https://example.com/bokrah-retailer-setup-v3.5.0.exe',
      );

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(buildScenarioApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(UpdatePromptDialog), findsOneWidget);

      // User skips version
      await tester.tap(find.text('Skip This Version'));
      await tester.pumpAndSettle();

      // Dialog is gone
      expect(find.byType(UpdatePromptDialog), findsNothing);

      // Version is saved as skipped
      expect(repository.skippedVersion, equals('3.5.0'));

      // TopBar badge is now hidden because there is no unskipped update
      expect(find.byIcon(Icons.system_update_alt_rounded), findsNothing);
    });

    testWidgets('Scenario 4: User clicks Download Update - triggers browser launcher with bokrah-retailer-setup',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const setupUrl =
          'https://github.com/Mahfoud-Sa/bokrah/releases/download/v3.5.0/bokrah-retailer-setup-v3.5.0.exe';

      repository.installedVersion = '3.4.0';
      repository.latestRelease = const AppRelease(
        version: '3.5.0',
        tagName: 'v3.5.0',
        name: 'Release 3.5.0',
        body: 'New build',
        downloadUrl: setupUrl,
      );

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(buildScenarioApp(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Download Update'));
      await tester.pumpAndSettle();

      // Verifies browser launch was delegated with the exact installer binary URL
      expect(repository.launchedDownloadUrl, equals(setupUrl));
    });

    testWidgets('Scenario 5: Startup check with network timeout fails silently without alerts', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repository.shouldThrow = true;

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(buildScenarioApp(router: router));
      await tester.pumpAndSettle();

      // No intrusive error dialogs or badges appear
      expect(find.byType(UpdatePromptDialog), findsNothing);
      expect(find.byIcon(Icons.system_update_alt_rounded), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Scenario 6: Missing direct installer asset shows View Release Page fallback', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const releasePageUrl = 'https://github.com/Mahfoud-Sa/bokrah/releases/tag/v3.5.0';

      repository.installedVersion = '3.4.0';
      repository.latestRelease = const AppRelease(
        version: '3.5.0',
        tagName: 'v3.5.0',
        name: 'Release 3.5.0',
        body: 'Notes without direct installer binary',
        downloadUrl: null,
        htmlUrl: releasePageUrl,
      );

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(buildScenarioApp(router: router));
      await tester.pumpAndSettle();

      // Displays View Release Page instead of claiming direct installer is ready
      expect(find.text('View Release Page'), findsOneWidget);

      await tester.tap(find.text('View Release Page'));
      await tester.pumpAndSettle();

      expect(repository.launchedDownloadUrl, equals(releasePageUrl));
    });

    test('Scenario 7: PlatformAssetMatcher prioritizes bokrah-retailer-setup assets', () {
      final assets = [
        {'name': 'notes.txt', 'browser_download_url': 'https://example.com/notes.txt'},
        {'name': 'source-code.zip', 'browser_download_url': 'https://example.com/source.zip'},
        {'name': 'generic-tool.exe', 'browser_download_url': 'https://example.com/generic.exe'},
        {
          'name': 'bokrah-retailer-setup-v3.5.0.exe',
          'browser_download_url': 'https://example.com/bokrah-retailer-setup-v3.5.0.exe'
        },
      ];

      final url = PlatformAssetMatcher.findInstallerUrl(assets, platformOverride: TargetPlatform.windows);
      expect(url, equals('https://example.com/bokrah-retailer-setup-v3.5.0.exe'));
    });
  });
}
