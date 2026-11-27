import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/data/models/category_model.dart';
import 'package:bokrah_retail/app/features/categories/data/datasources/categories_local_datasource.dart';
import 'package:bokrah_retail/app/features/categories/data/repositories/categories_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CategoryEntity & CategoryModel', () {
    test('creates entity properly and calculates isRoot', () {
      final root = CategoryEntity(
        id: 1,
        name: 'Electronics',
        code: 'CAT-ELEC',
        description: 'Electronic devices',
      );

      final child = CategoryEntity(
        id: 2,
        name: 'Phones',
        parentId: 1,
        code: 'CAT-PHONE',
      );

      expect(root.isRoot, isTrue);
      expect(child.isRoot, isFalse);
      expect(root.name, 'Electronics');
      expect(root.code, 'CAT-ELEC');
      expect(root.description, 'Electronic devices');
    });

    test(
      'matches domain method checks query across name, code, description',
      () {
        final category = CategoryEntity(
          id: 10,
          name: 'Laptops and Computers',
          code: 'CAT-PC',
          description: 'Desktops, laptops and accessories',
        );

        expect(category.matches('laptop'), isTrue);
        expect(category.matches('CAT-PC'), isTrue);
        expect(category.matches('accessories'), isTrue);
        expect(category.matches('clothing'), isFalse);
        expect(category.matches(''), isTrue);
      },
    );

    test('copyWith works with and without clearParent', () {
      final cat = CategoryEntity(
        id: 5,
        name: 'Monitors',
        parentId: 1,
        code: 'CAT-MON',
      );

      final updatedName = cat.copyWith(name: 'Displays');
      expect(updatedName.name, 'Displays');
      expect(updatedName.parentId, 1);

      final clearedParent = cat.copyWith(clearParent: true);
      expect(clearedParent.parentId, isNull);
      expect(clearedParent.isRoot, isTrue);
    });

    test('equality and hashCode match identical properties', () {
      final now = DateTime(2026, 1, 1);
      final cat1 = CategoryEntity(
        id: 1,
        name: 'Shoes',
        code: 'CAT-SHOE',
        createdAt: now,
      );
      final cat2 = CategoryEntity(
        id: 1,
        name: 'Shoes',
        code: 'CAT-SHOE',
        createdAt: now,
      );

      expect(cat1, equals(cat2));
      expect(cat1.hashCode, equals(cat2.hashCode));
    });

    test('CategoryModel serializes toMap and fromMap accurately', () {
      final model = CategoryModel(
        id: 100,
        name: 'Gaming',
        parentId: 5,
        code: 'CAT-GAME',
        description: 'Consoles and games',
      );

      final map = model.toMap();
      expect(map['id'], 100);
      expect(map['name'], 'Gaming');
      expect(map['parentId'], 5);
      expect(map['code'], 'CAT-GAME');
      expect(map['description'], 'Consoles and games');

      final fromMap = CategoryModel.fromMap(map);
      expect(fromMap.id, 100);
      expect(fromMap.name, 'Gaming');
      expect(fromMap.parentId, 5);
      expect(fromMap.code, 'CAT-GAME');
    });

    test(
      'CategoryModel.fromMap handles string, num, and malformed types safely',
      () {
        final parsed = CategoryModel.fromMap({
          'id': '99',
          'name': 12345, // non-string value converts safely
          'parentId': 10.0, // double value
          'code': 999,
          'description': null,
        });

        expect(parsed.id, 99);
        expect(parsed.name, '12345');
        expect(parsed.parentId, 10);
        expect(parsed.code, '999');
        expect(parsed.description, isNull);
      },
    );

    test(
      'CategoryModel.fromMap handles string, num, and malformed types safely',
      () {
        final parsed = CategoryModel.fromMap({
          'id': '99',
          'name': 12345, // non-string value converts safely
          'parentId': 10.0, // double value
          'code': 999,
          'description': null,
        });

        expect(parsed.id, 99);
        expect(parsed.name, '12345');
        expect(parsed.parentId, 10);
        expect(parsed.code, '999');
        expect(parsed.description, isNull);
      },
    );
  });

  group('CategoriesRepository & LocalDataSource', () {
    late SharedPreferences prefs;
    late CategoriesLocalDataSource dataSource;
    late CategoriesRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      dataSource = CategoriesLocalDataSourceImpl(prefs: prefs);
      repository = CategoriesRepositoryImpl(localDataSource: dataSource);
    });

    test(
      'getAllCategories returns empty list on clean preferences without defaults',
      () async {
        final categories = await repository.getAllCategories();
        expect(categories, isEmpty);
      },
    );

    test(
      'saveCategory adds new root category and assigns id if null',
      () async {
        final newCat = CategoryEntity(name: 'Smart Watches', code: 'CAT-WATCH');

        final saved = await repository.saveCategory(newCat);
        expect(saved, isNotNull);
        expect(saved!.id, 1);
        expect(saved.name, 'Smart Watches');

        final all = await repository.getAllCategories();
        expect(all.any((c) => c.name == 'Smart Watches'), isTrue);

        // Rejects non-existent parent
        final invalidParent = CategoryEntity(
          name: 'Invalid Parent Cat',
          parentId: 99999,
        );
        final failedSave = await repository.saveCategory(invalidParent);
        expect(failedSave, isNull);

        // Rejects empty name
        final emptyName = CategoryEntity(name: '   ');
        final failedEmpty = await repository.saveCategory(emptyName);
        expect(failedEmpty, isNull);
      },
    );

    test(
      'saveCategory upserts when category has existing id without duplicating',
      () async {
        await dataSource.saveCategory(
          CategoryModel(id: 1, name: 'Initial Name', code: 'INIT-01'),
        );

        final updatedModel = CategoryModel(
          id: 1,
          name: 'Upserted Name',
          code: 'UPSERT-01',
        );

        final saved = await dataSource.saveCategory(updatedModel);
        expect(saved?.name, 'Upserted Name');

        final all = await dataSource.getAllCategories();
        expect(all.where((c) => c.id == 1).length, 1);
        expect(all.firstWhere((c) => c.id == 1).name, 'Upserted Name');
      },
    );

    test(
      'updateCategory updates category fields and rejects circular parent',
      () async {
        await dataSource.saveCategory(
          CategoryModel(id: 1, name: 'Initial Root', code: 'ROOT-01'),
        );

        final target = (await repository.getCategoryById(1))!;
        final updated = target.copyWith(name: 'Updated Root Name');
        final ok = await repository.updateCategory(updated);
        expect(ok, isTrue);

        final retrieved = await repository.getCategoryById(1);
        expect(retrieved?.name, 'Updated Root Name');

        // Attempt self-referencing parent
        final selfParent = target.copyWith(parentId: target.id);
        final selfParentResult = await repository.updateCategory(selfParent);
        expect(selfParentResult, isFalse);
      },
    );

    test(
      'deleteCategory orphans children when deleteSubCategories is false',
      () async {
        await dataSource.saveCategory(CategoryModel(id: 1, name: 'Parent 1'));
        await dataSource.saveCategory(
          CategoryModel(id: 2, name: 'Child 2', parentId: 1),
        );

        final ok = await repository.deleteCategory(
          1,
          deleteSubCategories: false,
        );
        expect(ok, isTrue);

        final allAfter = await repository.getAllCategories();
        expect(allAfter.any((c) => c.id == 1), isFalse);

        final childAfter = allAfter.firstWhere((c) => c.id == 2);
        expect(childAfter.parentId, isNull);
      },
    );

    test(
      'deleteCategory deletes entire subtree when deleteSubCategories is true',
      () async {
        await dataSource.saveCategory(CategoryModel(id: 1, name: 'Root 1'));
        await dataSource.saveCategory(
          CategoryModel(id: 2, name: 'Node 2', parentId: 1),
        );
        await dataSource.saveCategory(
          CategoryModel(id: 3, name: 'Child 3', parentId: 2),
        );
        await dataSource.saveCategory(
          CategoryModel(id: 4, name: 'Child 4', parentId: 2),
        );

        final ok = await repository.deleteCategory(
          2,
          deleteSubCategories: true,
        );
        expect(ok, isTrue);

        final allAfter = await repository.getAllCategories();
        expect(allAfter.any((c) => c.id == 2), isFalse);
        expect(allAfter.any((c) => c.id == 3), isFalse);
        expect(allAfter.any((c) => c.id == 4), isFalse);
        expect(allAfter.any((c) => c.id == 1), isTrue);
      },
    );

    test('deleteCategory returns false if category id not found', () async {
      final ok = await repository.deleteCategory(999999);
      expect(ok, isFalse);
    });

    test(
      'tree helpers calculate roots, subs, descendants, and path breadcrumbs',
      () async {
        await dataSource.saveCategory(
          CategoryModel(id: 1, name: 'الإلكترونيات والتقنية'),
        );
        await dataSource.saveCategory(
          CategoryModel(id: 2, name: 'الهواتف المحمولة', parentId: 1),
        );
        await dataSource.saveCategory(
          CategoryModel(id: 3, name: 'الهواتف الذكية', parentId: 2),
        );

        final categories = await repository.getAllCategories();

        final roots = repository.getRootCategories(categories);
        expect(roots.every((c) => c.isRoot), isTrue);

        final subsOfRoot1 = repository.getSubCategories(1, categories);
        expect(subsOfRoot1.every((c) => c.parentId == 1), isTrue);

        final descendantsOf1 = repository.getDescendantIds(1, categories);
        expect(descendantsOf1.contains(2), isTrue);
        expect(descendantsOf1.contains(3), isTrue);

        final path = repository.getCategoryPath(
          3,
          categories,
          separator: ' -> ',
        );
        expect(path, contains(' -> '));
        expect(path, startsWith('الإلكترونيات والتقنية'));
      },
    );
  });
}
