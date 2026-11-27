import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/domain/usecases/category_usecases.dart';
import 'package:bokrah_retail/app/features/categories/data/models/category_model.dart';
import 'package:bokrah_retail/app/features/categories/data/datasources/categories_local_datasource.dart';
import 'package:bokrah_retail/app/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_cubit.dart';
import 'package:bokrah_retail/app/features/categories/presentation/pages/add_category_page.dart';
import 'package:bokrah_retail/app/features/categories/presentation/pages/update_category_page.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddCategoryPage & UpdateCategoryPage Widget Tests', () {
    late SharedPreferences prefs;
    late CategoriesRepositoryImpl repository;
    late ItemsService itemsService;
    late CategoriesCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      final localDataSource = CategoriesLocalDataSourceImpl(prefs: prefs);
      await localDataSource.saveCategory(
        CategoryModel(
          id: 1,
          name: 'Tech & Electronics',
          code: 'CAT-TECH',
          description: 'Technology hardware',
        ),
      );
      repository = CategoriesRepositoryImpl(localDataSource: localDataSource);
      itemsService = ItemsService();

      cubit = CategoriesCubit(
        getAllCategories: GetAllCategoriesUseCase(repository),
        getCategoryById: GetCategoryByIdUseCase(repository),
        saveCategory: SaveCategoryUseCase(repository),
        updateCategory: UpdateCategoryUseCase(repository),
        deleteCategory: DeleteCategoryUseCase(repository),
        repository: repository,
        itemsService: itemsService,
      );
      await cubit.loadCategories();
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets(
      'AddCategoryPage renders form fields inside FormSectionCards and validates name',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<CategoriesCubit>.value(
              value: cubit,
              child: const AddCategoryPage(),
            ),
          ),
        );

        // Verify ResponsiveFormGrid and FormSectionCards exist
        expect(find.byType(ResponsiveFormGrid), findsOneWidget);
        expect(find.byType(FormSectionCard), findsNWidgets(4));

        // Verify submit button
        final saveButton = find.widgetWithText(FilledButton, 'حفظ الفئة');
        expect(saveButton, findsOneWidget);

        // Tap submit with empty name
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pump();

        expect(find.text('يرجى إدخال اسم الفئة'), findsOneWidget);

        // Fill name and save
        await tester.enterText(
          find.widgetWithText(TextFormField, 'اسم الفئة *'),
          'Electronics and Gadgets',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'كود الفئة (اختياري)'),
          'CAT-GADGETS',
        );
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          cubit.state.categories.any(
            (c) => c.name == 'Electronics and Gadgets',
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'UpdateCategoryPage renders pre-populated fields and StatMetricCards',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final category = CategoryEntity(
          id: 1,
          name: 'Tech & Electronics',
          code: 'CAT-TECH',
          description: 'Technology hardware',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<CategoriesCubit>.value(
              value: cubit,
              child: UpdateCategoryPage(category: category),
            ),
          ),
        );

        // Verify ResponsiveFormGrid, StatMetricCards and FormSectionCards exist
        expect(find.byType(ResponsiveFormGrid), findsOneWidget);
        expect(find.byType(FormSectionCard), findsNWidgets(4));
        expect(find.byType(StatMetricCard), findsNWidgets(3));
        expect(find.text('العناصر المباشرة'), findsOneWidget);
        expect(find.text('إجمالي العناصر بالفروع'), findsOneWidget);
        expect(find.text('الفئات الفرعية'), findsOneWidget);

        // Verify pre-populated values (in form field and in system info path)
        expect(find.text('Tech & Electronics'), findsNWidgets(2));
        expect(find.text('CAT-TECH'), findsOneWidget);
        expect(find.text('Technology hardware'), findsOneWidget);

        // Modify and save
        await tester.enterText(
          find.widgetWithText(TextFormField, 'اسم الفئة *'),
          'Advanced Tech',
        );

        final saveButton = find.widgetWithText(FilledButton, 'حفظ التعديلات');
        expect(saveButton, findsOneWidget);

        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          cubit.state.categories.any((c) => c.name == 'Advanced Tech'),
          isTrue,
        );
      },
    );
  });
}
