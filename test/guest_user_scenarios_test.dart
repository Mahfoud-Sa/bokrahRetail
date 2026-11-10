import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/services/mock_auth_service.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/auth/presentation/widgets/guest_restricted_view.dart';
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

class MockAppUpdateRepository implements AppUpdateRepository {
  AppRelease? latestRelease;
  bool isAvailable = false;
  String? downloadedUrl;
  bool launchResult = true;

  @override
  Future<AppRelease?> getLatestRelease() async => latestRelease;

  @override
  Future<String> getInstalledVersion() async => '3.4.0';

  @override
  bool isUpdateAvailable(String installedVersion, String latestVersion) =>
      isAvailable;

  @override
  Future<bool> isVersionSkipped(String version) async => false;

  @override
  Future<void> skipVersion(String version) async {}

  @override
  Future<bool> launchDownloadUrl(String url) async {
    downloadedUrl = url;
    return launchResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService authService;
  late SharedPrefsAuthTokenStorage tokenStorage;
  late SharedPreferences prefs;
  late AuthCubit authCubit;
  late SettingsCubit settingsCubit;
  late MockAppUpdateRepository updateRepo;
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
    // Explicitly set as guest
    authCubit.continueAsGuest();

    settingsCubit = SettingsCubit(
      localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
    );
    updateRepo = MockAppUpdateRepository();
    updateCubit = AppUpdateCubit(repository: updateRepo);
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
    authCubit.close();
    settingsCubit.close();
    updateCubit.close();
    sessionCubit.close();
    restaurantCubit.close();
  });

  Widget buildGuestApp({
    required GoRouter router,
  }) {
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
            locale: settingsCubit.state.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('Guest User Capabilities & Verification Tests', () {
    testWidgets(
        'Scenario 1: Guest user can change language between Arabic and English',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Start in English
      await settingsCubit.updateLanguageCode('en');

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(buildGuestApp(router: router));
      await tester.pumpAndSettle();

      // Confirm guest status and English UI
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('العربية'), findsOneWidget);
      expect(settingsCubit.state.locale.languageCode, equals('en'));

      // 1. Guest taps 'العربية' button to toggle language
      final arPill = find.text('العربية');
      await tester.ensureVisible(arPill);
      await tester.tap(arPill);
      await tester.pumpAndSettle();

      // Confirm language switched to Arabic
      expect(settingsCubit.state.locale.languageCode, equals('ar'));
      expect(find.text('تسجيل الدخول'), findsWidgets);
      expect(find.text('EN'), findsOneWidget);

      // 2. Guest taps 'EN' to switch back to English
      final enPill = find.text('EN');
      await tester.ensureVisible(enPill);
      await tester.tap(enPill);
      await tester.pumpAndSettle();

      // Confirm language switched back to English
      expect(settingsCubit.state.locale.languageCode, equals('en'));
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('العربية'), findsOneWidget);
    });

    testWidgets(
        'Scenario 2: Guest user can freely cycle and change theme modes',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await settingsCubit.updateLanguageCode('en');

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(buildGuestApp(router: router));
      await tester.pumpAndSettle();

      // Initial theme mode
      final initialMode = settingsCubit.state.bkThemeMode;

      // Find the theme toggle icon button
      final themeButton = find.byWidgetPredicate((widget) =>
          widget is IconButton &&
          (widget.tooltip?.contains('Theme:') == true ||
              widget.tooltip?.contains('المظهر:') == true));

      expect(themeButton, findsOneWidget);
      await tester.ensureVisible(themeButton);

      // 1. Cycle to next theme mode
      await tester.tap(themeButton);
      await tester.pumpAndSettle();
      expect(settingsCubit.state.bkThemeMode, isNot(equals(initialMode)));

      // 2. Cycle again
      final secondMode = settingsCubit.state.bkThemeMode;
      await tester.tap(themeButton);
      await tester.pumpAndSettle();
      expect(settingsCubit.state.bkThemeMode, isNot(equals(secondMode)));

      // 3. Cycle again
      final thirdMode = settingsCubit.state.bkThemeMode;
      await tester.tap(themeButton);
      await tester.pumpAndSettle();
      expect(settingsCubit.state.bkThemeMode, isNot(equals(thirdMode)));
    });

    testWidgets(
        'Scenario 3: Guest user can navigate to Login page from header button',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await settingsCubit.updateLanguageCode('en');

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Login Page Destination')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildGuestApp(router: router));
      await tester.pumpAndSettle();

      // Find the header login button
      final loginButton = find.byKey(const ValueKey('header_login_button'));
      expect(loginButton, findsOneWidget);

      await tester.ensureVisible(loginButton);
      // Tap Sign In button
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Confirmed navigated to Login page
      expect(find.text('Login Page Destination'), findsOneWidget);
    });

    testWidgets(
        'Scenario 4: Guest user can navigate to Register page from header button',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await settingsCubit.updateLanguageCode('en');

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Register Page Destination')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildGuestApp(router: router));
      await tester.pumpAndSettle();

      // Find the header register button
      final registerButton =
          find.byKey(const ValueKey('header_register_button'));
      expect(registerButton, findsOneWidget);

      await tester.ensureVisible(registerButton);
      // Tap Create Account button
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Confirmed navigated to Register page
      expect(find.text('Register Page Destination'), findsOneWidget);
    });

    testWidgets(
        'Scenario 5: Guest user can download the new version via UpdatePromptDialog',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const testDownloadUrl =
          'https://github.com/org/repo/releases/download/v3.5.0/BokraRetail-Setup.exe';

      updateRepo.latestRelease = const AppRelease(
        version: '3.5.0',
        tagName: 'v3.5.0',
        name: 'Release 3.5.0',
        body: 'Exciting new features and improvements.',
        downloadUrl: testDownloadUrl,
      );
      updateRepo.isAvailable = true;

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(buildGuestApp(router: router));
      await tester.pumpAndSettle();

      // The UpdatePromptDialog appears automatically when an update is available
      expect(find.byType(UpdatePromptDialog), findsOneWidget);
      expect(find.text('New Version Available'), findsOneWidget);
      expect(find.text('Download Update'), findsOneWidget);

      // Guest user clicks Download Update
      await tester.tap(find.text('Download Update'));
      await tester.pumpAndSettle();

      // Confirm that the download URL was triggered successfully
      expect(updateRepo.downloadedUrl, equals(testDownloadUrl));
    });

    testWidgets(
        'Scenario 6: Guest user can open AppUpdateScreen and trigger new version download',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await settingsCubit.updateLanguageCode('en');

      const testDownloadUrl = 'https://example.com/installer-v3.5.0.exe';

      updateRepo.latestRelease = const AppRelease(
        version: '3.5.0',
        tagName: 'v3.5.0',
        name: 'Release 3.5.0',
        body: 'Release notes',
        downloadUrl: testDownloadUrl,
      );
      updateRepo.isAvailable = true;

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(buildGuestApp(router: router));
      await tester.pumpAndSettle();

      // Dismiss dialog if shown to test manual icon tap
      if (find.byType(UpdatePromptDialog).evaluate().isNotEmpty) {
        final navigator =
            Navigator.of(tester.element(find.byType(UpdatePromptDialog)));
        navigator.pop();
        await tester.pumpAndSettle();
      }

      // Guest user sees the desktop topBar update icon
      final updateIconFinder = find.byIcon(Icons.system_update_alt_rounded);
      expect(updateIconFinder, findsOneWidget);

      await tester.ensureVisible(updateIconFinder);
      // Tap update icon to open AppUpdateScreen
      await tester.tap(updateIconFinder);
      await tester.pumpAndSettle();

      // Confirm AppUpdateScreen is opened
      expect(find.byType(AppUpdateScreen), findsOneWidget);

      // Tap Download Update button inside AppUpdateScreen
      final downloadBtn = find.text('Download Update');
      expect(downloadBtn, findsOneWidget);
      await tester.tap(downloadBtn);
      await tester.pumpAndSettle();

      // Confirm download URL is launched for the guest user
      expect(updateRepo.downloadedUrl, equals(testDownloadUrl));
    });

    testWidgets(
        'Scenario 7: Boundary check - Guest user cannot access restricted administration areas',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await settingsCubit.updateLanguageCode('en');

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Login Destination')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildGuestApp(router: router));
      await tester.pumpAndSettle();

      // 1. Expand Settings section in sidebar
      final settingsHeader = find.text('Settings');
      expect(settingsHeader, findsOneWidget);
      await tester.ensureVisible(settingsHeader);
      await tester.tap(settingsHeader);
      await tester.pumpAndSettle();

      // 2. Tap Users Management
      final usersItem = find.text('Users Management');
      expect(usersItem, findsOneWidget);
      await tester.ensureVisible(usersItem);
      await tester.tap(usersItem);
      await tester.pumpAndSettle();

      // Sign In Required prompt dialog appears
      expect(find.text('Sign In Required'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // GuestRestrictedView is displayed instead of the admin users table
      expect(find.byType(GuestRestrictedView), findsOneWidget);
      expect(find.text('Sign In Now'), findsOneWidget);
    });
  });
}
