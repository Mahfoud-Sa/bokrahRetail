import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/domain/usecases/category_usecases.dart';
import 'package:bokrah_retail/app/features/categories/data/models/category_model.dart';
import 'package:bokrah_retail/app/features/categories/data/datasources/categories_local_datasource.dart';
import 'package:bokrah_retail/app/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_cubit.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_state.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CategoriesCubit', () {
    late SharedPreferences prefs;
    late CategoriesRepositoryImpl repository;
    late ItemsService itemsService;
    late CategoriesCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      final localDataSource = CategoriesLocalDataSourceImpl(prefs: prefs);

      // Seed test categories explicitly for unit testing
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
      await localDataSource.saveCategory(
        CategoryModel(
          id: 3,
          name: 'الهواتف الذكية (Smartphones)',
          parentId: 2,
          code: 'CAT-SMART',
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
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has default empty values', () {
      expect(cubit.state.status, CategoriesStatus.initial);
      expect(cubit.state.categories, isEmpty);
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.expandedCategoryIds, isEmpty);
      expect(cubit.state.isSaving, isFalse);
    });

    test(
      'loadCategories populates categories, items, and auto-expands IDs',
      () async {
        await cubit.loadCategories();

        expect(cubit.state.status, CategoriesStatus.loaded);
        expect(cubit.state.categories, isNotEmpty);
        expect(cubit.state.expandedCategoryIds, isNotEmpty);
      },
    );

    test(
      'toggleExpand, expandAll, and collapseAll manipulate expansion set',
      () async {
        await cubit.loadCategories();
        expect(cubit.state.expandedCategoryIds.contains(1), isTrue);

        cubit.toggleExpand(1);
        expect(cubit.state.expandedCategoryIds.contains(1), isFalse);

        cubit.toggleExpand(1);
        expect(cubit.state.expandedCategoryIds.contains(1), isTrue);

        cubit.collapseAll();
        expect(cubit.state.expandedCategoryIds, isEmpty);

        cubit.expandAll();
        expect(cubit.state.expandedCategoryIds, isNotEmpty);
      },
    );

    test('saveCategory adds category and reloads state', () async {
      await cubit.loadCategories();
      final initialCount = cubit.state.categories.length;

      final saved = await cubit.saveCategory(
        CategoryEntity(name: 'Kitchenware', code: 'CAT-KITCHEN'),
      );

      expect(saved, isNotNull);
      expect(cubit.state.categories.length, initialCount + 1);
      expect(
        cubit.state.categories.any((c) => c.name == 'Kitchenware'),
        isTrue,
      );
    });

    test('updateCategory modifies category and reflects in state', () async {
      await cubit.loadCategories();
      final target = cubit.state.categories.first;

      final ok = await cubit.updateCategory(
        target.copyWith(name: 'Modified Tech'),
      );

      expect(ok, isTrue);
      expect(
        cubit.state.categories.firstWhere((c) => c.id == target.id).name,
        'Modified Tech',
      );
    });

    test('deleteCategory removes category and updates state', () async {
      await cubit.loadCategories();
      final countBefore = cubit.state.categories.length;

      final ok = await cubit.deleteCategory(1);
      expect(ok, isTrue);
      expect(cubit.state.categories.length, countBefore - 1);
      expect(cubit.state.categories.any((c) => c.id == 1), isFalse);
    });

    test(
      'filterCategories filters roots by name, code, or subtree matches',
      () async {
        await cubit.loadCategories();

        // Category 3 is 'الهواتف الذكية (Smartphones)' under Category 2 under Root 1 ('الإلكترونيات والتقنية')
        final rootsForPhone = cubit.filterCategories('smartphones');
        expect(rootsForPhone.any((r) => r.id == 1), isTrue);

        final rootsForNonExistent = cubit.filterCategories(
          'non_existent_category_query',
        );
        expect(rootsForNonExistent, isEmpty);
      },
    );
  });
}
