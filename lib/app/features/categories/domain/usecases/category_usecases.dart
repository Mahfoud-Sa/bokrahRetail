import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/domain/repositories/categories_repository.dart';

class GetAllCategoriesUseCase {
  final CategoriesRepository repository;
  GetAllCategoriesUseCase(this.repository);

  Future<List<CategoryEntity>> call() async {
    return await repository.getAllCategories();
  }
}

class GetCategoryByIdUseCase {
  final CategoriesRepository repository;
  GetCategoryByIdUseCase(this.repository);

  Future<CategoryEntity?> call(int id) async {
    return await repository.getCategoryById(id);
  }
}

class SaveCategoryUseCase {
  final CategoriesRepository repository;
  SaveCategoryUseCase(this.repository);

  Future<CategoryEntity?> call(CategoryEntity category) async {
    return await repository.saveCategory(category);
  }
}

class UpdateCategoryUseCase {
  final CategoriesRepository repository;
  UpdateCategoryUseCase(this.repository);

  Future<bool> call(CategoryEntity category) async {
    return await repository.updateCategory(category);
  }
}

class DeleteCategoryUseCase {
  final CategoriesRepository repository;
  DeleteCategoryUseCase(this.repository);

  Future<bool> call(int id, {bool deleteSubCategories = false}) async {
    return await repository.deleteCategory(
      id,
      deleteSubCategories: deleteSubCategories,
    );
  }
}
