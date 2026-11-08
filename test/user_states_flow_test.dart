import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/accounting_playground/playground_controller.dart';
import 'package:bokrah_retail/app/features/accounting_playground/templates/journal_entry_preview.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/services/mock_auth_service.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/entities/app_release.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/repositories/app_update_repository.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';
import 'package:bokrah_retail/app/features/home/home_page.dart';
import 'package:bokrah_retail/app/features/restaurant/data/models/restaurant_dto.dart';
import 'package:bokrah_retail/app/features/restaurant/data/services/restaurant_api_service.dart';
import 'package:bokrah_retail/app/features/restaurant/data/services/restaurant_service.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/create_restaurant_cubit.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/restaurant_cubit.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/restaurant_state.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

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

Widget createTestApp({
  required AuthCubit authCubit,
  required RestaurantCubit restaurantCubit,
  required SharedPreferences prefs,
  Locale locale = const Locale('en'),
  Widget? homeWidget,
}) {
  prefs.setString('language_code', locale.languageCode);

  return MultiBlocProvider(
    providers: [
      BlocProvider<SettingsCubit>(
        create: (_) => SettingsCubit(
          localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
        ),
      ),
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<RestaurantCubit>.value(value: restaurantCubit),
      BlocProvider<AppUpdateCubit>(
        create: (_) => AppUpdateCubit(repository: _FakeAppUpdateRepo()),
      ),
      BlocProvider<SessionCubit>(
        create: (_) => SessionCubit(
          usersService: UsersService(),
          initialOperator: UserEntity(
            name: 'Owner Operator',
            email: 'owner@bokrah.com',
            role: OperatorRole.admin,
          ),
        ),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: homeWidget ?? const HomePage(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService authService;
  late SharedPrefsAuthTokenStorage tokenStorage;
  late SharedPreferences prefs;
  late RestaurantService restaurantService;
  late AuthCubit authCubit;
  late RestaurantCubit restaurantCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
    restaurantService = RestaurantService();
    authService = MockAuthService(
      tokenStorage: tokenStorage,
      simulatedLatency: Duration.zero,
    );
    authCubit = AuthCubit(authService: authService);
    restaurantCubit = RestaurantCubit(service: restaurantService);

    if (singelton.isRegistered<RestaurantService>()) {
      singelton.unregister<RestaurantService>();
    }
    singelton.registerSingleton<RestaurantService>(restaurantService);

    if (singelton.isRegistered<RestaurantCubit>()) {
      singelton.unregister<RestaurantCubit>();
    }
    singelton.registerSingleton<RestaurantCubit>(restaurantCubit);
  });

  tearDown(() {
    authCubit.close();
    restaurantCubit.close();
    if (singelton.isRegistered<RestaurantService>()) {
      singelton.unregister<RestaurantService>();
    }
    if (singelton.isRegistered<RestaurantCubit>()) {
      singelton.unregister<RestaurantCubit>();
    }
  });

  group('User States Integration Tests', () {
    testWidgets(
      'State 1 (Guest): Can browse, sees Sign In & Create Account, restricted on operations',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. Enter as Guest
        authCubit.continueAsGuest();
        await restaurantCubit.loadRestaurant();

        await tester.pumpWidget(createTestApp(
          authCubit: authCubit,
          restaurantCubit: restaurantCubit,
          prefs: prefs,
          locale: const Locale('en'),
        ));
        await tester.pumpAndSettle();

        // Guest user badges and header actions
        expect(find.text('Guest User'), findsOneWidget);
        expect(find.text('Guest'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);

        // Guest can browse dashboard freely
        expect(find.text('Accounting Dashboard'), findsWidgets);

        // Persistent restaurant banner is NOT shown for guest
        expect(find.byKey(const ValueKey('restaurant_setup_notice_banner')), findsNothing);

        // 2. Attempt operation requiring a restaurant: Save draft or Post journal
        final playgroundCtrl = PlaygroundController();
        addTearDown(playgroundCtrl.dispose);

        await tester.pumpWidget(createTestApp(
          authCubit: authCubit,
          restaurantCubit: restaurantCubit,
          prefs: prefs,
          locale: const Locale('en'),
          homeWidget: Scaffold(
            body: JournalEntryPreview(controller: playgroundCtrl),
          ),
        ));
        await tester.pumpAndSettle();

        final postEntryButton = find.text('Post entry');
        expect(postEntryButton, findsOneWidget);
        await tester.tap(postEntryButton);
        await tester.pumpAndSettle();

        // Dialog should appear with exact required guest restriction message
        expect(
          find.text('Please log in or create an account to use this feature.'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('guest_dialog_login_button')), findsOneWidget);
        expect(find.byKey(const ValueKey('guest_dialog_register_button')), findsOneWidget);
        expect(find.byKey(const ValueKey('guest_dialog_cancel_button')), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.byKey(const ValueKey('guest_dialog_cancel_button')));
        await tester.pumpAndSettle();

        // Journal should not have posted
        expect(playgroundCtrl.journalPosted, isFalse);
      },
    );

    testWidgets(
      'State 2 (Authenticated without restaurant): shows persistent banner, prevents restaurant operations and preserves input',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. Authenticate user
        await tester.runAsync(() async {
          authCubit.setEmail('owner@bokrah.com');
          authCubit.setPassword('password123');
          await authCubit.submitLogin();
        });

        // Explicitly ensure restaurant is NOT registered yet
        await restaurantService.setHasRegisteredRestaurant(false);
        await restaurantCubit.loadRestaurant();
        restaurantCubit.setHasRestaurant(false);

        await tester.pumpWidget(createTestApp(
          authCubit: authCubit,
          restaurantCubit: restaurantCubit,
          prefs: prefs,
          locale: const Locale('en'),
        ));
        await tester.pumpAndSettle();

        // Sign In button replaced with operator controls
        expect(find.text('Sign In'), findsNothing);
        expect(find.text('Owner Operator'), findsOneWidget);

        // Persistent setup notice banner is clearly visible
        final banner = find.byKey(const ValueKey('restaurant_setup_notice_banner'));
        expect(banner, findsOneWidget);
        expect(
          find.text(
            'Complete your account setup by adding your restaurant details to enter all your business data and use restaurant-related features.',
          ),
          findsOneWidget,
        );
        expect(find.text('Add restaurant details'), findsOneWidget);

        // 2. User attempts an operation requiring a restaurant: Journal Post
        final playgroundCtrl = PlaygroundController();
        addTearDown(playgroundCtrl.dispose);
        playgroundCtrl.journal.description = 'Draft catering revenue';

        await tester.pumpWidget(createTestApp(
          authCubit: authCubit,
          restaurantCubit: restaurantCubit,
          prefs: prefs,
          locale: const Locale('en'),
          homeWidget: Scaffold(
            body: JournalEntryPreview(controller: playgroundCtrl),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Post entry'));
        await tester.pumpAndSettle();

        // Restriction dialog for restaurant requirement appears
        expect(
          find.text('Please add your restaurant details before continuing with this operation.'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('restaurant_required_add_button')), findsOneWidget);
        expect(find.byKey(const ValueKey('restaurant_required_cancel_button')), findsOneWidget);

        // Cancel dialog
        await tester.tap(find.byKey(const ValueKey('restaurant_required_cancel_button')));
        await tester.pumpAndSettle();

        // Unsaved user input is preserved!
        expect(playgroundCtrl.journal.description, equals('Draft catering revenue'));
        expect(playgroundCtrl.journalPosted, isFalse);
      },
    );

    testWidgets(
      'State 3 (Transition to registered restaurant): banner removed, success message displayed, operations unlocked and persisted',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. Authenticate user without restaurant
        await tester.runAsync(() async {
          authCubit.setEmail('owner@bokrah.com');
          authCubit.setPassword('password123');
          await authCubit.submitLogin();
        });
        await restaurantService.setHasRegisteredRestaurant(false);
        await restaurantCubit.loadRestaurant();
        restaurantCubit.setHasRestaurant(false);

        await tester.pumpWidget(createTestApp(
          authCubit: authCubit,
          restaurantCubit: restaurantCubit,
          prefs: prefs,
          locale: const Locale('en'),
        ));
        await tester.pumpAndSettle();

        // Setup banner exists
        expect(find.byKey(const ValueKey('restaurant_setup_notice_banner')), findsOneWidget);

        // 2. Simulate successful restaurant creation
        final mockApi = MockRestaurantApiService(
          tokenStorage: tokenStorage,
          localRestaurantService: restaurantService,
          simulatedLatency: Duration.zero,
        );

        final createCubit = CreateRestaurantCubit(
          apiService: mockApi,
          restaurantCubit: restaurantCubit,
        );

        await tester.runAsync(() async {
          final res = await createCubit.submit(
            const CreateRestaurantRequest(
              name: 'Sultan Palace',
              nameAr: 'قصر السلطان',
              nameEn: 'Sultan Palace',
              phone: '+966501234567',
            ),
          );
          expect(res, isTrue);
        });

        // State is updated immediately
        expect(restaurantCubit.state, isA<RestaurantLoaded>());
        final loaded = restaurantCubit.state as RestaurantLoaded;
        expect(loaded.hasRestaurant, isTrue);

        // Re-pump HomePage
        await tester.pumpWidget(createTestApp(
          authCubit: authCubit,
          restaurantCubit: restaurantCubit,
          prefs: prefs,
          locale: const Locale('en'),
        ));
        await tester.pumpAndSettle();

        // Setup banner is removed
        expect(find.byKey(const ValueKey('restaurant_setup_notice_banner')), findsNothing);

        // 3. Operations requiring restaurant now succeed!
        final playgroundCtrl = PlaygroundController();
        addTearDown(playgroundCtrl.dispose);
        playgroundCtrl.journal.description = 'Lunch buffet';
        playgroundCtrl.journal.lines[0].debit = '100.00';
        playgroundCtrl.journal.lines[1].credit = '100.00';

        await tester.pumpWidget(createTestApp(
          authCubit: authCubit,
          restaurantCubit: restaurantCubit,
          prefs: prefs,
          locale: const Locale('en'),
          homeWidget: Scaffold(
            body: JournalEntryPreview(controller: playgroundCtrl),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Post entry'));
        await tester.pumpAndSettle();

        // No restriction dialog, entry posted successfully
        expect(
          find.text('Please add your restaurant details before continuing with this operation.'),
          findsNothing,
        );
        expect(playgroundCtrl.journalPosted, isTrue);

        // 4. Persistence across page refresh
        final isRegisteredInStorage = await restaurantService.hasRegisteredRestaurant();
        expect(isRegisteredInStorage, isTrue);

        final newCubit = RestaurantCubit(service: restaurantService);
        await newCubit.loadRestaurant();
        expect((newCubit.state as RestaurantLoaded).hasRestaurant, isTrue);
        newCubit.close();
      },
    );

    testWidgets(
      'Arabic localization: verifies all state messages in Arabic',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. Guest in Arabic
        authCubit.continueAsGuest();
        await restaurantCubit.loadRestaurant();

        final playgroundCtrl = PlaygroundController();
        addTearDown(playgroundCtrl.dispose);
        playgroundCtrl.configuration.arabic = true;

        await tester.pumpWidget(createTestApp(
          authCubit: authCubit,
          restaurantCubit: restaurantCubit,
          prefs: prefs,
          locale: const Locale('ar'),
          homeWidget: Scaffold(
            body: JournalEntryPreview(controller: playgroundCtrl),
          ),
        ));
        await tester.pumpAndSettle();

        // Tap post entry in Arabic
        await tester.tap(find.text('ترحيل القيد'));
        await tester.pumpAndSettle();

        // Guest restriction in Arabic
        expect(
          find.text('يُرجى تسجيل الدخول أو إنشاء حساب لاستخدام هذه الميزة.'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('guest_dialog_cancel_button')));
        await tester.pumpAndSettle();

        // 2. Authenticated without restaurant in Arabic
        await tester.runAsync(() async {
          authCubit.setEmail('owner@bokrah.com');
          authCubit.setPassword('password123');
          await authCubit.submitLogin();
        });
        await restaurantService.setHasRegisteredRestaurant(false);
        await restaurantCubit.loadRestaurant();
        restaurantCubit.setHasRestaurant(false);

        await tester.pumpWidget(createTestApp(
          authCubit: authCubit,
          restaurantCubit: restaurantCubit,
          prefs: prefs,
          locale: const Locale('ar'),
        ));
        await tester.pumpAndSettle();

        // Persistent banner in Arabic
        expect(
          find.text(
            'أكمل إعداد حسابك بإضافة بيانات مطعمك لإدخال جميع بيانات أعمالك واستخدام الميزات المتعلقة بالمطعم.',
          ),
          findsOneWidget,
        );
        expect(find.text('إضافة بيانات المطعم'), findsWidgets);

        // Attempt operation in Arabic
        await tester.pumpWidget(createTestApp(
          authCubit: authCubit,
          restaurantCubit: restaurantCubit,
          prefs: prefs,
          locale: const Locale('ar'),
          homeWidget: Scaffold(
            body: JournalEntryPreview(controller: playgroundCtrl),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('ترحيل القيد'));
        await tester.pumpAndSettle();

        // Restaurant required dialog in Arabic
        expect(
          find.text('يُرجى إضافة بيانات مطعمك قبل متابعة هذه العملية.'),
          findsOneWidget,
        );
      },
    );
  });
}

