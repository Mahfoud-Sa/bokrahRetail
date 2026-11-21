import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';

abstract class CategoriesRepository {
  Future<List<CategoryEntity>> getAllCategories();
  Future<CategoryEntity?> getCategoryById(int id);
  Future<CategoryEntity?> saveCategory(CategoryEntity category);
  Future<bool> updateCategory(CategoryEntity category);
  Future<bool> deleteCategory(int id, {bool deleteSubCategories = false});
  List<CategoryEntity> getRootCategories(List<CategoryEntity> categories);
  List<CategoryEntity> getSubCategories(
    int parentId,
    List<CategoryEntity> categories,
  );
  Set<int> getDescendantIds(int categoryId, List<CategoryEntity> categories);
  String getCategoryPath(
    int categoryId,
    List<CategoryEntity> categories, {
    String separator = ' > ',
  });
}
