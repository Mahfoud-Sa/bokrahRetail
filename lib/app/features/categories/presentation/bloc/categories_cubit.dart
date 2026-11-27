import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/domain/repositories/categories_repository.dart';
import 'package:bokrah_retail/app/features/categories/domain/usecases/category_usecases.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_state.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final GetAllCategoriesUseCase _getAllCategories;
  final GetCategoryByIdUseCase _getCategoryById;
  final SaveCategoryUseCase _saveCategory;
  final UpdateCategoryUseCase _updateCategory;
  final DeleteCategoryUseCase _deleteCategory;
  final CategoriesRepository _repository;
  final ItemsService _itemsService;

  CategoriesCubit({
    required GetAllCategoriesUseCase getAllCategories,
    required GetCategoryByIdUseCase getCategoryById,
    required SaveCategoryUseCase saveCategory,
    required UpdateCategoryUseCase updateCategory,
    required DeleteCategoryUseCase deleteCategory,
    required CategoriesRepository repository,
    required ItemsService itemsService,
  }) : _getAllCategories = getAllCategories,
       _getCategoryById = getCategoryById,
       _saveCategory = saveCategory,
       _updateCategory = updateCategory,
       _deleteCategory = deleteCategory,
       _repository = repository,
       _itemsService = itemsService,
       super(const CategoriesState());

  Future<void> loadCategories() async {
    emit(state.copyWith(status: CategoriesStatus.loading, clearError: true));
    try {
      final categoriesFuture = _getAllCategories();
      final itemsFuture = _itemsService.getAllItems();

      final categories = await categoriesFuture;
      final items = await itemsFuture;

      final expandedIds = <int>{...state.expandedCategoryIds};
      // Expand all categories by default on first load so tree is visible
      if (expandedIds.isEmpty) {
        for (final c in categories) {
          if (c.id != null) {
            expandedIds.add(c.id!);
          }
        }
      }

      emit(
        state.copyWith(
          status: CategoriesStatus.loaded,
          categories: categories,
          items: items,
          expandedCategoryIds: expandedIds,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CategoriesStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void toggleExpand(int categoryId) {
    final next = Set<int>.from(state.expandedCategoryIds);
    if (next.contains(categoryId)) {
      next.remove(categoryId);
    } else {
      next.add(categoryId);
    }
    emit(state.copyWith(expandedCategoryIds: next));
  }

  void expandAll() {
    final allIds = {
      for (final c in state.categories)
        if (c.id != null) c.id!,
    };
    emit(state.copyWith(expandedCategoryIds: allIds));
  }

  void collapseAll() {
    emit(state.copyWith(expandedCategoryIds: const {}));
  }

  Future<CategoryEntity?> saveCategory(CategoryEntity category) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final saved = await _saveCategory(category);
      if (saved == null) {
        emit(
          state.copyWith(
            isSaving: false,
            errorMessage: 'Failed to save category',
          ),
        );
        return null;
      }
      await loadCategories();
      return saved;
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
      return null;
    }
  }

  Future<bool> updateCategory(CategoryEntity category) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final success = await _updateCategory(category);
      if (!success) {
        emit(
          state.copyWith(
            isSaving: false,
            errorMessage: 'Failed to update category',
          ),
        );
        return false;
      }
      await loadCategories();
      return true;
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
      return false;
    }
  }

  Future<bool> deleteCategory(
    int id, {
    bool deleteSubCategories = false,
  }) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final success = await _deleteCategory(
        id,
        deleteSubCategories: deleteSubCategories,
      );
      if (!success) {
        emit(
          state.copyWith(
            isSaving: false,
            errorMessage: 'Failed to delete category',
          ),
        );
        return false;
      }
      await loadCategories();
      return true;
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
      return false;
    }
  }

  Future<CategoryEntity?> getCategoryById(int id) => _getCategoryById(id);

  // ---------------------------------------------------------------------------
  // Tree Hierarchy and Item Metrics Helpers
  // ---------------------------------------------------------------------------

  int getItemCount(int categoryId) {
    return state.items.where((i) => i.effectiveCategoryId == categoryId).length;
  }

  int getTotalItemCountWithSubCategories(int categoryId) {
    final descendants = _repository.getDescendantIds(
      categoryId,
      state.categories,
    );
    final allIds = {categoryId, ...descendants};
    return state.items
        .where((i) => allIds.contains(i.effectiveCategoryId))
        .length;
  }

  List<CategoryEntity> getRootCategories([List<CategoryEntity>? source]) {
    return _repository.getRootCategories(source ?? state.categories);
  }

  List<CategoryEntity> getSubCategories(
    int parentId, [
    List<CategoryEntity>? source,
  ]) {
    return _repository.getSubCategories(parentId, source ?? state.categories);
  }

  Set<int> getDescendantIds(int categoryId) {
    return _repository.getDescendantIds(categoryId, state.categories);
  }

  String getCategoryPath(int categoryId, {String separator = ' > '}) {
    return _repository.getCategoryPath(
      categoryId,
      state.categories,
      separator: separator,
    );
  }

  bool hasMatchInSubtree(int categoryId, String query) {
    final children = getSubCategories(categoryId);
    for (final child in children) {
      if (child.matches(query)) return true;
      if (child.id != null && hasMatchInSubtree(child.id!, query)) return true;
    }
    return false;
  }

  List<CategoryEntity> filterCategories(String query) {
    final roots = getRootCategories();
    if (query.trim().isEmpty) return roots;
    final q = query.trim().toLowerCase();

    return roots.where((root) {
      final directMatch = root.matches(q);
      final subtreeMatch = root.id != null && hasMatchInSubtree(root.id!, q);
      return directMatch || subtreeMatch;
    }).toList();
  }
}
