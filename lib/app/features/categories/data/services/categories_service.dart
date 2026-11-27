import 'package:bokrah_retail/app/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/domain/repositories/categories_repository.dart';

class CategoriesService {
  final CategoriesRepository _repository;

  CategoriesService({CategoriesRepository? repository})
    : _repository = repository ?? CategoriesRepositoryImpl();

  Future<List<CategoryEntity>> getAllCategories() =>
      _repository.getAllCategories();
  Future<CategoryEntity?> saveCategory(CategoryEntity category) =>
      _repository.saveCategory(category);
  Future<bool> updateCategory(CategoryEntity category) =>
      _repository.updateCategory(category);
  Future<bool> deleteCategory(int id, {bool deleteSubCategories = false}) =>
      _repository.deleteCategory(id, deleteSubCategories: deleteSubCategories);
  Future<CategoryEntity?> getCategoryById(int id) =>
      _repository.getCategoryById(id);
  List<CategoryEntity> getRootCategories(List<CategoryEntity> categories) =>
      _repository.getRootCategories(categories);
  List<CategoryEntity> getSubCategories(
    int parentId,
    List<CategoryEntity> categories,
  ) => _repository.getSubCategories(parentId, categories);
  Set<int> getDescendantIds(int categoryId, List<CategoryEntity> categories) =>
      _repository.getDescendantIds(categoryId, categories);
  String getCategoryPath(
    int categoryId,
    List<CategoryEntity> categories, {
    String separator = ' > ',
  }) =>
      _repository.getCategoryPath(categoryId, categories, separator: separator);
}
