import 'package:bokrah_retail/app/features/categories/data/datasources/categories_local_datasource.dart';
import 'package:bokrah_retail/app/features/categories/data/models/category_model.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/domain/repositories/categories_repository.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  final CategoriesLocalDataSource localDataSource;

  CategoriesRepositoryImpl({CategoriesLocalDataSource? localDataSource})
      : localDataSource = localDataSource ?? CategoriesLocalDataSourceImpl();

  @override
  Future<List<CategoryEntity>> getAllCategories() async {
    return await localDataSource.getAllCategories();
  }

  @override
  Future<CategoryEntity?> getCategoryById(int id) async {
    return await localDataSource.getCategoryById(id);
  }

  @override
  Future<CategoryEntity?> saveCategory(CategoryEntity category) async {
    final model = CategoryModel.fromEntity(category);
    return await localDataSource.saveCategory(model);
  }

  @override
  Future<bool> updateCategory(CategoryEntity category) async {
    final model = CategoryModel.fromEntity(category);
    return await localDataSource.updateCategory(model);
  }

  @override
  Future<bool> deleteCategory(
    int id, {
    bool deleteSubCategories = false,
  }) async {
    return await localDataSource.deleteCategory(
      id,
      deleteSubCategories: deleteSubCategories,
    );
  }

  @override
  List<CategoryEntity> getRootCategories(List<CategoryEntity> categories) {
    return categories.where((c) => c.isRoot).toList();
  }

  @override
  List<CategoryEntity> getSubCategories(
    int parentId,
    List<CategoryEntity> categories,
  ) {
    return categories.where((c) => c.parentId == parentId).toList();
  }

  @override
  Set<int> getDescendantIds(int categoryId, List<CategoryEntity> categories) {
    final result = <int>{};
    void recurse(int pId) {
      final children = categories.where((c) => c.parentId == pId);
      for (final child in children) {
        if (child.id != null && !result.contains(child.id)) {
          result.add(child.id!);
          recurse(child.id!);
        }
      }
    }

    recurse(categoryId);
    return result;
  }

  @override
  String getCategoryPath(
    int categoryId,
    List<CategoryEntity> categories, {
    String separator = ' > ',
  }) {
    final catMap = {for (var c in categories) c.id: c};
    final pathNames = <String>[];

    int? currentId = categoryId;
    final visited = <int>{};

    while (currentId != null &&
        catMap.containsKey(currentId) &&
        !visited.contains(currentId)) {
      visited.add(currentId);
      final currentCat = catMap[currentId]!;
      pathNames.insert(0, currentCat.name);
      currentId = currentCat.parentId;
    }

    return pathNames.join(separator);
  }
}
