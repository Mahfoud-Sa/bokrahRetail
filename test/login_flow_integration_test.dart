import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/services/mock_auth_service.dart';
import 'package:bokrah_retail/app/features/auth/login_page.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';
import 'package:bokrah_retail/app/features/home/home_page.dart';
import 'package:bokrah_retail/app/features/auth/data/services/auth_service.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/entities/app_release.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/repositories/app_update_repository.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';

import 'package:bokrah_retail/app/initialzation_dependencies.dart';

class StubAppUpdateRepository implements AppUpdateRepository {
  @override
  Future<AppRelease?> getLatestRelease() async => null;

  @override
  Future<String> getInstalledVersion() async => '3.3.0';

  @override
  bool isUpdateAvailable(String installedVersion, String latestVersion) => false;

  @override
  Future<bool> isVersionSkipped(String version) async => false;

  @override
  Future<void> skipVersion(String version) async {}

  @override
  Future<bool> launchDownloadUrl(String url) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService authService;
  late SharedPrefsAuthTokenStorage tokenStorage;
  late SharedPreferences prefs;
  late UsersService usersService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
    usersService = UsersService();

    authService = MockAuthService(
      tokenStorage: tokenStorage,
      simulatedLatency: Duration.zero,
      usersService: usersService,
    );

    if (singelton.isRegistered<AuthTokenStorage>()) {
      singelton.unregister<AuthTokenStorage>();
    }
    singelton.registerSingleton<AuthTokenStorage>(tokenStorage);

    if (singelton.isRegistered<UsersService>()) {
      singelton.unregister<UsersService>();
    }
    singelton.registerSingleton<UsersService>(usersService);
  });

  tearDown(() {
    if (singelton.isRegistered<AuthTokenStorage>()) {
      singelton.unregister<AuthTokenStorage>();
    }
    if (singelton.isRegistered<UsersService>()) {
      singelton.unregister<UsersService>();
    }
  });

  Widget buildTestHarness({
    required GoRouter router,
    required AuthCubit authCubit,
    required SessionCubit sessionCubit,
    required SettingsCubit settingsCubit,
    Locale locale = const Locale('en'),
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<SessionCubit>.value(value: sessionCubit),
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
      ],
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  GoRouter createTestRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(authService: authService),
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Admin Dashboard View')),
          ),
        ),
        GoRoute(
          path: '/restaurant/dashboard',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Restaurant Dashboard View')),
          ),
        ),
        GoRoute(
          path: '/delivery/orders',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Delivery Orders View')),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home Dashboard View')),
          ),
        ),
      ],
    );
  }

  group('User Login & Error Handling Tests', () {
    testWidgets('Validates empty email and password submission', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authCubit = AuthCubit(authService: authService);
      final sessionCubit = SessionCubit(usersService: usersService);
      final settingsCubit = SettingsCubit(
        localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
      );
      final router = createTestRouter(authService);

      await tester.pumpWidget(buildTestHarness(
        router: router,
        authCubit: authCubit,
        sessionCubit: sessionCubit,
        settingsCubit: settingsCubit,
      ));
      await tester.pumpAndSettle();

      // Tap Sign In without filling in any credentials
      final signInButton = find.byKey(const ValueKey('login_submit_button'));
      expect(signInButton, findsOneWidget);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter both email and password.'), findsOneWidget);
    });

    testWidgets('Displays specific error for deactivated user account', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authCubit = AuthCubit(authService: authService);
      final sessionCubit = SessionCubit(usersService: usersService);
      final settingsCubit = SettingsCubit(
        localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
      );
      final router = createTestRouter(authService);

      await tester.pumpWidget(buildTestHarness(
        router: router,
        authCubit: authCubit,
        sessionCubit: sessionCubit,
        settingsCubit: settingsCubit,
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'deactivated@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      final signInButton = find.byKey(const ValueKey('login_submit_button'));
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Your account has been deactivated. Please contact support.'), findsOneWidget);
    });

    testWidgets('Displays specific error for non-existent user account (404)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authCubit = AuthCubit(authService: authService);
      final sessionCubit = SessionCubit(usersService: usersService);
      final settingsCubit = SettingsCubit(
        localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
      );
      final router = createTestRouter(authService);

      await tester.pumpWidget(buildTestHarness(
        router: router,
        authCubit: authCubit,
        sessionCubit: sessionCubit,
        settingsCubit: settingsCubit,
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'notfound@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      final signInButton = find.byKey(const ValueKey('login_submit_button'));
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('No account found with this email address.'), findsOneWidget);
    });

    testWidgets('Displays specific error for server error (500)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authCubit = AuthCubit(authService: authService);
      final sessionCubit = SessionCubit(usersService: usersService);
      final settingsCubit = SettingsCubit(
        localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
      );
      final router = createTestRouter(authService);

      await tester.pumpWidget(buildTestHarness(
        router: router,
        authCubit: authCubit,
        sessionCubit: sessionCubit,
        settingsCubit: settingsCubit,
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'servererror@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      final signInButton = find.byKey(const ValueKey('login_submit_button'));
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong. Please try again later.'), findsOneWidget);
    });
  });

  group('Role-Based Redirection Tests', () {
    testWidgets('Restaurant user redirects to /restaurant/dashboard and persists token', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authCubit = AuthCubit(authService: authService);
      final sessionCubit = SessionCubit(usersService: usersService);
      final settingsCubit = SettingsCubit(
        localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
      );
      final router = createTestRouter(authService);

      await tester.pumpWidget(buildTestHarness(
        router: router,
        authCubit: authCubit,
        sessionCubit: sessionCubit,
        settingsCubit: settingsCubit,
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'restaurant@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      final signInButton = find.byKey(const ValueKey('login_submit_button'));
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Redirected to /restaurant/dashboard
      expect(find.text('Restaurant Dashboard View'), findsOneWidget);

      // Token persisted in secure storage
      expect(await tokenStorage.getAccessToken(), isNotNull);
      expect(await authService.isAuthenticated(), isTrue);
    });

    testWidgets('Admin user redirects to /admin/dashboard', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authCubit = AuthCubit(authService: authService);
      final sessionCubit = SessionCubit(usersService: usersService);
      final settingsCubit = SettingsCubit(
        localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
      );
      final router = createTestRouter(authService);

      await tester.pumpWidget(buildTestHarness(
        router: router,
        authCubit: authCubit,
        sessionCubit: sessionCubit,
        settingsCubit: settingsCubit,
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'admin@bokrah.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      final signInButton = find.byKey(const ValueKey('login_submit_button'));
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Admin Dashboard View'), findsOneWidget);
    });

    testWidgets('Delivery user redirects to /delivery/orders', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authCubit = AuthCubit(authService: authService);
      final sessionCubit = SessionCubit(usersService: usersService);
      final settingsCubit = SettingsCubit(
        localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
      );
      final router = createTestRouter(authService);

      await tester.pumpWidget(buildTestHarness(
        router: router,
        authCubit: authCubit,
        sessionCubit: sessionCubit,
        settingsCubit: settingsCubit,
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'delivery@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      final signInButton = find.byKey(const ValueKey('login_submit_button'));
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Delivery Orders View'), findsOneWidget);
    });

    testWidgets('Customer user redirects to /home', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authCubit = AuthCubit(authService: authService);
      final sessionCubit = SessionCubit(usersService: usersService);
      final settingsCubit = SettingsCubit(
        localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
      );
      final router = createTestRouter(authService);

      await tester.pumpWidget(buildTestHarness(
        router: router,
        authCubit: authCubit,
        sessionCubit: sessionCubit,
        settingsCubit: settingsCubit,
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'customer@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      final signInButton = find.byKey(const ValueKey('login_submit_button'));
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Home Dashboard View'), findsOneWidget);
    });
  });

  group('Account Verification Banner Tests', () {
    testWidgets('Displays verification banner on HomePage when unverified (English)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authCubit = AuthCubit(authService: authService);
      final sessionCubit = SessionCubit(usersService: usersService);
      final settingsCubit = SettingsCubit(
        localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
      );
      await settingsCubit.updateLanguageCode('en');
      final updateRepo = StubAppUpdateRepository();
      final updateCubit = AppUpdateCubit(repository: updateRepo);

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => LoginPage(authService: authService),
          ),
          GoRoute(
            path: '/restaurant/dashboard',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<SessionCubit>.value(value: sessionCubit),
            BlocProvider<SettingsCubit>.value(value: settingsCubit),
            BlocProvider<AppUpdateCubit>.value(value: updateCubit),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Log in with unverified account
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'unverified@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      final signInButton = find.byKey(const ValueKey('login_submit_button'));
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Check banner is displayed
      expect(find.byKey(const ValueKey('verification_notice_banner')), findsOneWidget);
      expect(find.textContaining('Please verify your email and complete account verification'), findsOneWidget);
    });

    testWidgets('Displays verification banner on HomePage when unverified (Arabic)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authCubit = AuthCubit(authService: authService);
      final sessionCubit = SessionCubit(usersService: usersService);
      final settingsCubit = SettingsCubit(
        localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
      );
      await settingsCubit.updateLanguageCode('ar');
      final updateRepo = StubAppUpdateRepository();
      final updateCubit = AppUpdateCubit(repository: updateRepo);

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => LoginPage(authService: authService),
          ),
          GoRoute(
            path: '/restaurant/dashboard',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<SessionCubit>.value(value: sessionCubit),
            BlocProvider<SettingsCubit>.value(value: settingsCubit),
            BlocProvider<AppUpdateCubit>.value(value: updateCubit),
          ],
          child: MaterialApp.router(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Log in with unverified account
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'unverified@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      final signInButton = find.byKey(const ValueKey('login_submit_button'));
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Check banner is displayed
      expect(find.byKey(const ValueKey('verification_notice_banner')), findsOneWidget);
      expect(find.textContaining('تأكيد البريد الإلكتروني وتوثيق الحساب'), findsOneWidget);
    });
  });
}
