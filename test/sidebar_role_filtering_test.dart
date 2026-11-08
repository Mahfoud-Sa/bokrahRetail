import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/home/home_page.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/repositories/app_update_repository.dart';
import 'package:bokrah_retail/app/features/autoUpdate/domain/entities/app_release.dart';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';

class FakeAppUpdateRepository implements AppUpdateRepository {
  @override
  Future<AppRelease?> getLatestRelease() async => null;
  @override
  Future<String> getInstalledVersion() async => '1.0.0';
  @override
  bool isUpdateAvailable(String installedVersion, String latestVersion) =>
      false;
  @override
  Future<bool> isVersionSkipped(String version) async => false;
  @override
  Future<void> skipVersion(String version) async {}
  @override
  Future<bool> launchDownloadUrl(String url) async => true;
}

Widget createTestApp({
  required SharedPreferences prefs,
  required UserEntity operator,
  Locale locale = const Locale('ar'),
}) {
  final sessionCubit = SessionCubit(
    usersService: UsersService(),
    initialOperator: operator,
  );

  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => SettingsCubit(
          localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
        ),
      ),
      BlocProvider(
        create: (_) => AppUpdateCubit(repository: FakeAppUpdateRepository()),
      ),
      BlocProvider<SessionCubit>.value(
        value: sessionCubit,
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

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Sidebar Role-Based Navigation Filtering', () {
    testWidgets('Admin operator sees all navigation items including Users and Financial Reports', (tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final admin = UserEntity(
        id: 1,
        name: 'Admin User',
        email: 'admin@bokrah.com',
        role: OperatorRole.admin,
      );

      await tester.pumpWidget(createTestApp(prefs: prefs, operator: admin));
      await tester.pumpAndSettle();

      // Admin sees Accounting & Financial Reports
      expect(find.text('التقارير المالية'), findsOneWidget);

      // Expand settings section
      final settingsHeader = find.text('الإعدادات والمستخدمين');
      expect(settingsHeader, findsOneWidget);
      await tester.tap(settingsHeader);
      await tester.pumpAndSettle();

      // Admin sees Users Management
      expect(find.text('إدارة المستخدمين'), findsOneWidget);
    });

    testWidgets('Cashier operator does NOT see Users Management or Financial Reports', (tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cashier = UserEntity(
        id: 2,
        name: 'Cashier User',
        email: 'cashier@bokrah.com',
        role: OperatorRole.cashier,
      );

      await tester.pumpWidget(createTestApp(prefs: prefs, operator: cashier));
      await tester.pumpAndSettle();

      // Cashier sees Invoices and Items
      expect(find.text('إدارة الفواتير'), findsOneWidget);

      // Cashier does not see Financial Reports
      expect(find.text('التقارير المالية'), findsNothing);

      // Expand settings section
      final settingsHeader = find.text('الإعدادات والمستخدمين');
      expect(settingsHeader, findsOneWidget);
      await tester.tap(settingsHeader);
      await tester.pumpAndSettle();

      // Cashier MUST NOT see Users Management
      expect(find.text('إدارة المستخدمين'), findsNothing);
      // But Cashier can still see Profile
      expect(find.text('ملفي الشخصي'), findsOneWidget);
    });

    testWidgets('Accountant operator sees Financial Reports and Invoices, but NOT Users Management', (tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final accountant = UserEntity(
        id: 3,
        name: 'Accountant User',
        email: 'accountant@bokrah.com',
        role: OperatorRole.accountant,
      );

      await tester.pumpWidget(createTestApp(prefs: prefs, operator: accountant));
      await tester.pumpAndSettle();

      // Accountant sees Financial Reports and Invoices
      expect(find.text('التقارير المالية'), findsOneWidget);
      expect(find.text('إدارة الفواتير'), findsOneWidget);

      // Expand settings section
      final settingsHeader = find.text('الإعدادات والمستخدمين');
      expect(settingsHeader, findsOneWidget);
      await tester.tap(settingsHeader);
      await tester.pumpAndSettle();

      // Accountant MUST NOT see Users Management
      expect(find.text('إدارة المستخدمين'), findsNothing);
    });
  });
}
