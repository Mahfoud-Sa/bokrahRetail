import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/services/mock_auth_service.dart';
import 'package:bokrah_retail/app/features/auth/register_page.dart';
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
      home: RegisterPage(authService: authService),
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

  group('RegisterPage Widget Tests', () {
    testWidgets('displays English heading, step 1 badge, form fields, and register button', (tester) async {
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

      expect(find.text('Register New Restaurant'), findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.text('Create Restaurant Owner Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Account & Continue'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('displays Arabic heading, step indicator, and Arabic form fields', (tester) async {
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

      expect(find.text('تسجيل مطعم جديد'), findsOneWidget);
      expect(find.text('الخطوة 1 من 2'), findsOneWidget);
      expect(find.text('إنشاء حساب مالك المنشأة'), findsOneWidget);
      expect(find.text('الاسم الكامل'), findsOneWidget);
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('رقم الهاتف'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
      expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
      expect(find.text('إنشاء الحساب ومتابعة بيانات المطعم'), findsOneWidget);
      expect(find.text('لديك حساب بالفعل؟'), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsOneWidget);
    });

    testWidgets('validates required fields on submission', (tester) async {
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

      // Tap submit with empty fields
      await tester.tap(find.text('Create Account & Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter full name'), findsOneWidget);
    });

    testWidgets('validates password mismatch on submission', (tester) async {
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

      // Enter name, email, phone, and mismatched passwords
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));

      await tester.enterText(textFields.at(0), 'Tariq Ali');
      await tester.enterText(textFields.at(1), 'tariq@restaurant.com');
      await tester.enterText(textFields.at(2), '501234567');
      await tester.enterText(textFields.at(3), 'Main Street');
      await tester.enterText(textFields.at(4), 'secret123');
      await tester.enterText(textFields.at(5), 'different123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Account & Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('submits registration successfully when valid data is entered', (tester) async {
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

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Nasser Omar');
      await tester.enterText(textFields.at(1), 'nasser@burger.com');
      await tester.enterText(textFields.at(2), '551122334');
      await tester.enterText(textFields.at(3), 'Main Street, City Center');
      await tester.enterText(textFields.at(4), 'password123');
      await tester.enterText(textFields.at(5), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Account & Continue'));
      await tester.pumpAndSettle();

      // Session should now be active
      expect(await authService.isAuthenticated(), isTrue);
      expect(await tokenStorage.getAccessToken(), isNotNull);
    });

    testWidgets('displays error feedback for duplicate email and duplicate restaurant name', (tester) async {
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

      final textFields = find.byType(TextField);

      // 1. Duplicate email test
      await tester.enterText(textFields.at(0), 'Unique Restaurant');
      await tester.enterText(textFields.at(1), 'existing@example.com');
      await tester.enterText(textFields.at(2), '501234567');
      await tester.enterText(textFields.at(4), 'password123');
      await tester.enterText(textFields.at(5), 'password123');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Create Account & Continue'));
      await tester.tap(find.text('Create Account & Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Email already exists.'), findsOneWidget);

      // 2. Duplicate restaurant name test
      await tester.enterText(textFields.at(0), 'Existing Restaurant');
      await tester.enterText(textFields.at(1), 'fresh@example.com');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Create Account & Continue'));
      await tester.tap(find.text('Create Account & Continue'));
      await tester.pumpAndSettle();

      expect(find.text('A restaurant with the same name already exists.'), findsOneWidget);
    });

    testWidgets('toggles password and confirm password visibility', (tester) async {
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

      final visibilityButtons = find.byIcon(Icons.visibility_outlined);
      expect(visibilityButtons, findsNWidgets(2));

      // Toggle first password field
      await tester.tap(visibilityButtons.first);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('opens country bottom sheet and selects Yemen', (tester) async {
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

      // Initially Saudi Arabia
      expect(find.text('🇸🇦'), findsOneWidget);
      expect(find.text('+966'), findsOneWidget);

      // Tap on country selector button to open bottom sheet
      await tester.tap(find.text('+966'));
      await tester.pumpAndSettle();

      // Find and select Yemen
      expect(find.text('اليمن'), findsOneWidget);
      await tester.tap(find.text('اليمن'));
      await tester.pumpAndSettle();

      // Now Yemen is selected in RegisterPage
      expect(find.text('🇾🇪'), findsOneWidget);
      expect(find.text('+967'), findsOneWidget);
    });
  });
}

