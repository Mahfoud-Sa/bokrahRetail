import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/services/mock_auth_service.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/auth/presentation/widgets/guest_restricted_view.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/entities/app_release.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/repositories/app_update_repository.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';
import 'package:bokrah_retail/app/features/home/home_page.dart';
import 'package:bokrah_retail/app/features/restaurant/data/services/restaurant_service.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/restaurant_cubit.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';

class _FakeAppUpdateRepo implements AppUpdateRepository {
  @override
  Future<AppRelease?> getLatestRelease() async => null;

  @override
  Future<String> getInstalledVersion() async => '3.4.0';

  @override
  bool isUpdateAvailable(String installedVersion, String latestVersion) => false;

  @override
  Future<bool> isVersionSkipped(String version) async => false;

  @override
  Future<void> skipVersion(String version) async {}

  @override
  Future<bool> launchDownloadUrl(String url) async => true;
}

Widget createTestHome({
  required AuthCubit authCubit,
  required SharedPreferences prefs,
  Locale locale = const Locale('en'),
}) {
  prefs.setString('language_code', locale.languageCode);
  return MultiBlocProvider(
    providers: [
      BlocProvider<SettingsCubit>(
        create: (_) => SettingsCubit(
          localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
        ),
      ),
      BlocProvider<AuthCubit>.value(
        value: authCubit,
      ),
      BlocProvider<AppUpdateCubit>(
        create: (_) => AppUpdateCubit(repository: _FakeAppUpdateRepo()),
      ),
      BlocProvider<SessionCubit>(
        create: (_) => SessionCubit(
          usersService: UsersService(),
          initialOperator: UserEntity(
            name: 'Admin Operator',
            email: 'admin@bokrah.com',
            role: OperatorRole.admin,
          ),
        ),
      ),
      BlocProvider<RestaurantCubit>(
        create: (_) => RestaurantCubit(service: RestaurantService()),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomePage(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService authService;
  late SharedPrefsAuthTokenStorage tokenStorage;
  late SharedPreferences prefs;
  late AuthCubit authCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
    authService = MockAuthService(
      tokenStorage: tokenStorage,
      simulatedLatency: Duration.zero,
    );
    authCubit = AuthCubit(authService: authService);
  });

  tearDown(() {
    authCubit.close();
  });

  group('HomePage Guest User & Auth User Integration Tests', () {
    testWidgets('Guest User sees Guest badge and Sign In button in header', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      authCubit.continueAsGuest();

      await tester.pumpWidget(createTestHome(
        authCubit: authCubit,
        prefs: prefs,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Guest User'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Authenticated User sees Operator name and role badge', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        authCubit.setEmail('chef@bokrah.com');
        authCubit.setPassword('password123');
        await authCubit.submitLogin();
      });

      await tester.pumpWidget(createTestHome(
        authCubit: authCubit,
        prefs: prefs,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Admin Operator'), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('Guest User attempting to access Settings/Users sees prompt and GuestRestrictedView', (tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      authCubit.continueAsGuest();

      await tester.pumpWidget(createTestHome(
        authCubit: authCubit,
        prefs: prefs,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      // Expand Settings menu
      final settingsHeader = find.text('Settings');
      expect(settingsHeader, findsOneWidget);
      await tester.tap(settingsHeader);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Users Management
      final usersItem = find.text('Users Management');
      expect(usersItem, findsOneWidget);
      await tester.tap(usersItem);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The guest auth prompt dialog should appear
      expect(find.text('Sign In Required'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Expect GuestRestrictedView to be displayed with prompt
      expect(find.byType(GuestRestrictedView), findsOneWidget);
      expect(find.text('Sign In Now'), findsOneWidget);
    });
  });
}
