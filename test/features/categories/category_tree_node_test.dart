import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/domain/usecases/category_usecases.dart';
import 'package:bokrah_retail/app/features/categories/data/models/category_model.dart';
import 'package:bokrah_retail/app/features/categories/data/datasources/categories_local_datasource.dart';
import 'package:bokrah_retail/app/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_cubit.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_state.dart';
import 'package:bokrah_retail/app/features/categories/presentation/widgets/category_tree_node.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CategoryTreeNode Widget Tests', () {
    late SharedPreferences prefs;
    late CategoriesRepositoryImpl repository;
    late ItemsService itemsService;
    late CategoriesCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      final localDataSource = CategoriesLocalDataSourceImpl(prefs: prefs);
      await localDataSource.saveCategory(
        CategoryModel(id: 1, name: 'الإلكترونيات والتقنية', code: 'CAT-ELEC'),
      );
      await localDataSource.saveCategory(
        CategoryModel(
          id: 2,
          name: 'الهواتف المحمولة',
          parentId: 1,
          code: 'CAT-PHONE',
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
      'renders category name, code badge, and menu button for leaf node',
      (tester) async {
        final category = CategoryEntity(
          id: 999,
          name: 'Home Appliances',
          code: 'CAT-APPL',
          description: 'Fridges and washing machines',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategoryTreeNode(
                category: category,
                cubit: cubit,
                depth: 0,
              ),
            ),
          ),
        );

        expect(find.text('Home Appliances'), findsOneWidget);
        expect(find.text('CAT-APPL'), findsOneWidget);
        expect(find.text('Fridges and washing machines'), findsOneWidget);
        expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      },
    );

    testWidgets('toggles node expansion on arrow click when children exist', (
      tester,
    ) async {
      final root = cubit.state.categories.firstWhere((c) => c.id == 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocBuilder<CategoriesCubit, CategoriesState>(
              bloc: cubit,
              builder: (context, state) =>
                  CategoryTreeNode(category: root, cubit: cubit, depth: 0),
            ),
          ),
        ),
      );

      // Root 1 has child Category 2 ('الهواتف المحمولة')
      expect(find.text('الهواتف المحمولة'), findsOneWidget);

      // Tap root's collapse toggle button (first expand icon)
      final expandIcon = find.byIcon(Icons.expand_more_rounded).first;
      expect(expandIcon, findsOneWidget);

      await tester.tap(expandIcon);
      await tester.pumpAndSettle();

      // Child should no longer be visible because it collapsed
      expect(find.text('الهواتف المحمولة'), findsNothing);
    });
  });
}
