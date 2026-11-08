import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/services/mock_auth_service.dart';
import 'package:bokrah_retail/app/features/auth/login_page.dart';
import 'package:bokrah_retail/app/features/auth/register_page.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/restaurant/data/services/restaurant_service.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/pages/restaurant_info_page.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService authService;
  late SharedPrefsAuthTokenStorage tokenStorage;
  late SharedPreferences prefs;
  late RestaurantService restaurantService;
  late UsersService usersService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
    usersService = UsersService();
    restaurantService = RestaurantService();

    authService = MockAuthService(
      tokenStorage: tokenStorage,
      simulatedLatency: Duration.zero,
      usersService: usersService,
    );

    // Register singletons in GetIt for clean dependency resolution
    if (singelton.isRegistered<AuthTokenStorage>()) {
      singelton.unregister<AuthTokenStorage>();
    }
    singelton.registerSingleton<AuthTokenStorage>(tokenStorage);

    if (singelton.isRegistered<RestaurantService>()) {
      singelton.unregister<RestaurantService>();
    }
    singelton.registerSingleton<RestaurantService>(restaurantService);

    if (singelton.isRegistered<UsersService>()) {
      singelton.unregister<UsersService>();
    }
    singelton.registerSingleton<UsersService>(usersService);
  });

  tearDown(() {
    if (singelton.isRegistered<AuthTokenStorage>()) {
      singelton.unregister<AuthTokenStorage>();
    }
    if (singelton.isRegistered<RestaurantService>()) {
      singelton.unregister<RestaurantService>();
    }
    if (singelton.isRegistered<UsersService>()) {
      singelton.unregister<UsersService>();
    }
  });

  testWidgets(
      'Registering a new restaurant directly navigates to /restaurant-info with populated data',
      (tester) async {
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

    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(authService: authService),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterPage(authService: authService),
        ),
        GoRoute(
          path: '/restaurant-info',
          builder: (context, state) => const RestaurantInfoPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home Dashboard Screen')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<SessionCubit>.value(value: sessionCubit),
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
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

    // Verify initially on RegisterPage
    expect(find.text('Register New Restaurant'), findsOneWidget);
    expect(find.text('Create Account & Continue'), findsOneWidget);
    expect(find.text('Restaurant Profile'), findsNothing);
    expect(find.text('Home Dashboard Screen'), findsNothing);

    // Enter form details
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(6));

    await tester.enterText(textFields.at(0), 'Al-Bustan Restaurant'); // Name
    await tester.enterText(textFields.at(1), 'albustan@example.com'); // Email
    await tester.enterText(textFields.at(2), '501234567'); // Phone
    await tester.enterText(textFields.at(3), 'King Fahd Road, Riyadh'); // Address
    await tester.enterText(textFields.at(4), 'SecurePassword123'); // Password
    await tester.enterText(textFields.at(5), 'SecurePassword123'); // Confirm password
    await tester.pumpAndSettle();

    // Tap submit button
    final submitButton = find.text('Create Account & Continue');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify navigation landed DIRECTLY on Restaurant Profile (/restaurant-info)
    expect(find.text('Restaurant Profile'), findsOneWidget);
    expect(find.text('Home Dashboard Screen'), findsNothing);

    // Verify registered restaurant name is displayed on Identity tab
    expect(find.text('Al-Bustan Restaurant'), findsWidgets);

    // Switch to Contact & Address tab to verify pre-populated contact info
    await tester.tap(find.text('Contact & Address'));
    await tester.pumpAndSettle();
    expect(find.text('albustan@example.com'), findsWidgets);

    // Also verify persistence in RestaurantService
    final savedRest = await restaurantService.getRestaurantInfo();
    expect(savedRest.nameAr, 'Al-Bustan Restaurant');
    expect(savedRest.email, 'albustan@example.com');
    expect(savedRest.phoneNumber, '+966501234567');

    // Verify "Go to Dashboard" button exists and navigates to /home
    final toDashboardButton = find.text('Go to Dashboard');
    expect(toDashboardButton, findsOneWidget);
    await tester.ensureVisible(toDashboardButton);
    await tester.tap(toDashboardButton);
    await tester.pumpAndSettle();

    // Verify landed on /home
    expect(find.text('Home Dashboard Screen'), findsOneWidget);
  });

  testWidgets(
      'Arabic registration navigates directly to restaurant data page in Arabic',
      (tester) async {
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

    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(authService: authService),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterPage(authService: authService),
        ),
        GoRoute(
          path: '/restaurant-info',
          builder: (context, state) => const RestaurantInfoPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('لوحة التحكم الرئيسية')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<SessionCubit>.value(value: sessionCubit),
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
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

    // Verify Arabic Register Page
    expect(find.text('تسجيل مطعم جديد'), findsOneWidget);
    expect(find.text('إنشاء الحساب ومتابعة بيانات المطعم'), findsOneWidget);

    // Enter form details
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'مطعم البستان'); // Name
    await tester.enterText(textFields.at(1), 'bustan@example.com'); // Email
    await tester.enterText(textFields.at(2), '509876543'); // Phone
    await tester.enterText(textFields.at(3), 'شارع الملك فهد، الرياض'); // Address
    await tester.enterText(textFields.at(4), 'Password123'); // Password
    await tester.enterText(textFields.at(5), 'Password123'); // Confirm
    await tester.pumpAndSettle();

    final submitButton = find.text('إنشاء الحساب ومتابعة بيانات المطعم');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify direct navigation to Arabic Restaurant Profile
    expect(find.text('بيانات وإعدادات المطعم'), findsOneWidget);
    expect(find.text('لوحة التحكم الرئيسية'), findsNothing);
    expect(find.text('مطعم البستان'), findsWidgets);

    // Switch to Contact & Address tab to verify pre-populated contact info
    await tester.tap(find.text('الاتصال والعنوان'));
    await tester.pumpAndSettle();
    expect(find.text('bustan@example.com'), findsWidgets);

    // Also verify persistence in RestaurantService
    final savedRest = await restaurantService.getRestaurantInfo();
    expect(savedRest.nameAr, 'مطعم البستان');
    expect(savedRest.email, 'bustan@example.com');
    expect(savedRest.phoneNumber, '+966509876543');

    // Verify "المتابعة للرئيسية" button navigates to /home
    final toHomeButton = find.text('المتابعة للرئيسية');
    expect(toHomeButton, findsOneWidget);
    await tester.ensureVisible(toHomeButton);
    await tester.tap(toHomeButton);
    await tester.pumpAndSettle();

    expect(find.text('لوحة التحكم الرئيسية'), findsOneWidget);
  });
}
