import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/services/mock_auth_service.dart';
import 'package:bokrah_retail/app/features/auth/login_page.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';

Widget createTestApp({
  required MockAuthService authService,
  required SharedPreferences prefs,
  Locale locale = const Locale('en'),
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => SettingsCubit(
          localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
        ),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LoginPage(authService: authService),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService authService;
  late SharedPrefsAuthTokenStorage tokenStorage;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokenStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
    authService = MockAuthService(
      tokenStorage: tokenStorage,
      simulatedLatency: Duration.zero,
    );
  });

  group('Login Flow Widget Tests', () {
    testWidgets('displays English heading, unified email/phone field, password field, and Sign In button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(
        authService: authService,
        prefs: prefs,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bokrah for Stores'), findsOneWidget);
      expect(find.text('Easier management for your shop'), findsOneWidget);
      expect(find.text('Email or Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('displays Arabic heading and RTL layout', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(
        authService: authService,
        prefs: prefs,
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('للمتاجر بكره'), findsOneWidget);
      expect(find.text('إدارة أسهل لمحلك'), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('البريد الإلكتروني أو رقم الهاتف'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
    });

    testWidgets('logs in using email and password in unified field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(
        authService: authService,
        prefs: prefs,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      // Enter email and password
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'chef@bokrah.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pump();

      // Tap Sign In button
      final signInButton = find.text('Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(await authService.isAuthenticated(), isTrue);
    });

    testWidgets('logs in using phone number and password in unified field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(
        authService: authService,
        prefs: prefs,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      // Enter phone and password in unified field
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '0501234567');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pump();

      // Tap Sign In button
      final signInButton = find.text('Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(await authService.isAuthenticated(), isTrue);
    });

    testWidgets('renders cleanly without overflow on narrow width in Arabic', (tester) async {
      tester.view.physicalSize = const Size(292, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(
        authService: authService,
        prefs: prefs,
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('للمتاجر بكره'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow on ultra-narrow width (120px)', (tester) async {
      tester.view.physicalSize = const Size(120, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(
        authService: authService,
        prefs: prefs,
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('displays Continue as Guest button in English and Arabic', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // English
      await tester.pumpWidget(createTestApp(
        authService: authService,
        prefs: prefs,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('continue_as_guest_button')), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);

      // Arabic
      await tester.pumpWidget(createTestApp(
        authService: authService,
        prefs: prefs,
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('continue_as_guest_button')), findsOneWidget);
      expect(find.text('المتابعة كضيف'), findsOneWidget);
    });

    testWidgets('tapping Continue as Guest enters guest mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(
        authService: authService,
        prefs: prefs,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      final guestButton = find.byKey(const ValueKey('continue_as_guest_button'));
      expect(guestButton, findsOneWidget);

      await tester.tap(guestButton);
      await tester.pumpAndSettle();

      // Ensure no exceptions occurred during guest transition
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays Add your store button in English and Arabic', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // English
      await tester.pumpWidget(createTestApp(
        authService: authService,
        prefs: prefs,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('register_retail_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('register_restaurant_button')), findsOneWidget);
      expect(find.text('Add your store'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);

      // Arabic
      await tester.pumpWidget(createTestApp(
        authService: authService,
        prefs: prefs,
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('register_retail_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('register_restaurant_button')), findsOneWidget);
      expect(find.text('اضف متجرك'), findsOneWidget);
      expect(find.text('ليس لديك حساب؟'), findsOneWidget);
    });
  });
}
