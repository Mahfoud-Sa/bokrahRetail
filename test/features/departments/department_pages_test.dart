import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/departments/data/datasources/departments_local_datasource.dart';
import 'package:bokrah_retail/app/features/departments/data/repositories/departments_repository_impl.dart';
import 'package:bokrah_retail/app/features/departments/data/services/departments_service.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/departments/presentation/pages/add_department_page.dart';
import 'package:bokrah_retail/app/features/departments/presentation/pages/departments_page.dart';
import 'package:bokrah_retail/app/features/departments/presentation/pages/update_department_page.dart';
import 'package:bokrah_retail/app/features/items/data/datasources/items_local_datasource.dart';
import 'package:bokrah_retail/app/features/items/data/repositories/items_repository_impl.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';

Widget _wrapWithL10n(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  late DepartmentsService departmentsService;
  late ItemsService itemsService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    departmentsService = DepartmentsService(
      repository: DepartmentsRepositoryImpl(
        localDataSource: DepartmentsLocalDataSourceImpl(prefs: prefs),
      ),
    );
    itemsService = ItemsService(
      repository: ItemsRepositoryImpl(
        localDataSource: ItemsLocalDataSourceImpl(prefs: prefs),
      ),
    );
  });

  testWidgets('AddDepartmentPage renders form sections and fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithL10n(
        AddDepartmentPage(departmentsService: departmentsService),
      ),
    );

    expect(find.text('Add New Department'), findsOneWidget);
    expect(find.text('Department Name *'), findsOneWidget);
    expect(find.text('Department Code (Optional)'), findsOneWidget);
    expect(find.text('Save Department'), findsOneWidget);
  });

  testWidgets('UpdateDepartmentPage pre-fills existing department data', (
    tester,
  ) async {
    final department = DepartmentEntity(
      id: 1,
      name: 'Electronics',
      code: 'ELEC',
      description: 'Devices',
    );

    await tester.pumpWidget(
      _wrapWithL10n(
        UpdateDepartmentPage(
          department: department,
          itemCount: 3,
          departmentsService: departmentsService,
        ),
      ),
    );

    expect(find.text('Edit Department: Electronics'), findsOneWidget);
    expect(find.text('Electronics'), findsOneWidget);
    expect(find.text('ELEC'), findsOneWidget);
    expect(find.text('Devices'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('DepartmentsPage renders list and filters by search query', (
    tester,
  ) async {
    await departmentsService.saveDepartment(
      DepartmentEntity(name: 'Electronics', code: 'ELEC'),
    );
    await departmentsService.saveDepartment(
      DepartmentEntity(name: 'Groceries', code: 'GROC'),
    );

    await tester.pumpWidget(
      _wrapWithL10n(
        DepartmentsPage(
          departmentsService: departmentsService,
          itemsService: itemsService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Electronics'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'GROC');
    await tester.pump();

    expect(find.text('Electronics'), findsNothing);
    expect(find.text('Groceries'), findsOneWidget);
  });
}
