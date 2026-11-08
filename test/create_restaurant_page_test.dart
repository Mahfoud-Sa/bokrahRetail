import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/models/auth_session_model.dart';
import 'package:bokrah_retail/app/features/restaurant/data/services/restaurant_api_service.dart';
import 'package:bokrah_retail/app/features/restaurant/data/services/restaurant_service.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/restaurant_cubit.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/pages/create_restaurant_page.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SharedPrefsAuthTokenStorage tokenStorage;
  late RestaurantService localRestaurantService;
  late MockRestaurantApiService mockApiService;
  late RestaurantCubit restaurantCubit;
  late SettingsCubit settingsCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
    localRestaurantService = RestaurantService();
    mockApiService = MockRestaurantApiService(
      tokenStorage: tokenStorage,
      localRestaurantService: localRestaurantService,
      simulatedLatency: Duration.zero,
    );
    restaurantCubit = RestaurantCubit(service: localRestaurantService);
    settingsCubit = SettingsCubit(
      localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
    );
  });

  Widget buildTestWidget({
    required Widget child,
    Locale locale = const Locale('ar'),
    GoRouter? router,
  }) {
    if (router != null) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<RestaurantCubit>.value(value: restaurantCubit),
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

    return MultiBlocProvider(
      providers: [
        BlocProvider<RestaurantCubit>.value(value: restaurantCubit),
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('CreateRestaurantPage Widget & Flow Tests', () {
    testWidgets('renders all 4 form sections and adds dynamic phone number', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(
        child: CreateRestaurantPage(apiService: mockApiService),
      ));
      await tester.pumpAndSettle();

      // Check section headers
      expect(find.text('البيانات الأساسية'), findsOneWidget);
      expect(find.text('بيانات الاتصال والتواجد الإلكتروني'), findsOneWidget);
      expect(find.text('بيانات الموقع والعنوان'), findsOneWidget);

      // Check submit button
      expect(find.byKey(const ValueKey('create_restaurant_submit_button')), findsOneWidget);

      // Add a dynamic phone number
      final addPhoneBtn = find.byKey(const ValueKey('add_phone_number_button'));
      expect(addPhoneBtn, findsOneWidget);
      await tester.tap(addPhoneBtn);
      await tester.pumpAndSettle();

      // Should now have 2 phone entries
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });

    testWidgets('validates required name field before submitting', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(
        child: CreateRestaurantPage(apiService: mockApiService),
      ));
      await tester.pumpAndSettle();

      // Submit without entering names
      final submitBtn = find.byKey(const ValueKey('create_restaurant_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('اسم المطعم (بالعربية أو الإنجليزية) مطلوب.'), findsWidgets);
    });

    testWidgets('successfully creates restaurant and redirects to dashboard', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Save active session for restaurant owner
      await tokenStorage.saveSession(AuthSessionModel(
        userId: '45',
        name: 'Ahmed Ali',
        email: 'owner@bokrah.com',
        phoneNumber: '+966501234567',
        accessToken: 'valid_jwt_token',
        refreshToken: 'refresh_jwt_token',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        roles: const ['restaurant'],
      ));

      final router = GoRouter(
        initialLocation: '/create-restaurant',
        routes: [
          GoRoute(
            path: '/create-restaurant',
            builder: (context, state) => CreateRestaurantPage(apiService: mockApiService),
          ),
          GoRoute(
            path: '/restaurant/dashboard',
            builder: (context, state) => const Scaffold(body: Text('Restaurant Dashboard View')),
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(
        child: const SizedBox.shrink(),
        router: router,
      ));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
        find.byKey(const ValueKey('name_ar_field')),
        'مطعم السعادة الجديد',
      );
      await tester.enterText(
        find.byKey(const ValueKey('name_en_field')),
        'Al-Saada New Restaurant',
      );

      final submitBtn = find.byKey(const ValueKey('create_restaurant_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify redirected to Restaurant Dashboard
      expect(find.text('Restaurant Dashboard View'), findsOneWidget);

      // Verify local storage updated
      final updated = await localRestaurantService.getRestaurantInfo();
      expect(updated.nameAr, equals('مطعم السعادة الجديد'));
    });

    testWidgets('handles 409 Conflict: owner already has a restaurant and navigates via dialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tokenStorage.saveSession(AuthSessionModel(
        userId: '99',
        name: 'Existing Owner',
        email: 'existing_owner@bokrah.com',
        phoneNumber: '+966501234567',
        accessToken: 'valid_jwt_token',
        refreshToken: 'refresh_jwt_token',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        roles: const ['restaurant'],
      ));

      // Seed owner as already having a restaurant
      mockApiService.seedOwnerWithRestaurant('existing_owner@bokrah.com');

      final router = GoRouter(
        initialLocation: '/create-restaurant',
        routes: [
          GoRoute(
            path: '/create-restaurant',
            builder: (context, state) => CreateRestaurantPage(apiService: mockApiService),
          ),
          GoRoute(
            path: '/restaurant/dashboard',
            builder: (context, state) => const Scaffold(body: Text('Navigated To Dashboard')),
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(
        child: const SizedBox.shrink(),
        router: router,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('name_ar_field')),
        'مطعم تجريبي إضافي',
      );

      final submitBtn = find.byKey(const ValueKey('create_restaurant_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Expect dialog
      expect(find.text('مطعم مسجل بالفعل'), findsOneWidget);

      // Tap Go to Dashboard
      final dialogBtn = find.byKey(const ValueKey('dialog_navigate_dashboard_button'));
      expect(dialogBtn, findsOneWidget);
      await tester.tap(dialogBtn);
      await tester.pumpAndSettle();

      expect(find.text('Navigated To Dashboard'), findsOneWidget);
    });

    testWidgets('handles 409 Conflict: duplicate restaurant name', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tokenStorage.saveSession(AuthSessionModel(
        userId: '50',
        name: 'Admin User',
        email: 'admin@bokrah.com',
        phoneNumber: '+966501234567',
        accessToken: 'valid_jwt_token',
        refreshToken: 'refresh_jwt_token',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        roles: const ['admin'],
      ));

      mockApiService.seedExistingRestaurantName('مطعم القدس');

      await tester.pumpWidget(buildTestWidget(
        child: CreateRestaurantPage(apiService: mockApiService),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('name_ar_field')),
        'مطعم القدس',
      );

      final submitBtn = find.byKey(const ValueKey('create_restaurant_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final duplicateBanner = find.text('اسم مكرر');
      await tester.ensureVisible(duplicateBanner);
      expect(duplicateBanner, findsOneWidget);
      expect(
        find.text('يوجد مطعم مسجل بهذا الاسم بالفعل. يُرجى اختيار اسم آخر.'),
        findsOneWidget,
      );
    });
  });
}
