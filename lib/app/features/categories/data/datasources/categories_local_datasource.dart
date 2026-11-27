import 'dart:convert';
import 'package:bokrah_retail/app/features/categories/data/models/category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class CategoriesLocalDataSource {
  Future<List<CategoryModel>> getAllCategories();
  Future<CategoryModel?> getCategoryById(int id);
  Future<CategoryModel?> saveCategory(CategoryModel category);
  Future<bool> updateCategory(CategoryModel category);
  Future<bool> deleteCategory(int id, {bool deleteSubCategories = false});
}

class CategoriesLocalDataSourceImpl implements CategoriesLocalDataSource {
  static const String _categoriesKey = 'categories_list';
  final SharedPreferences? _prefs;

  CategoriesLocalDataSourceImpl({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    final prefs = await _instance;
    final jsonList = prefs.getStringList(_categoriesKey) ?? const [];
    final categories = <CategoryModel>[];
    for (final jsonString in jsonList) {
      try {
        final decoded = json.decode(jsonString);
        if (decoded is Map) {
          categories.add(
            CategoryModel.fromMap(Map<String, dynamic>.from(decoded)),
          );
        }
      } catch (_) {
        // Skip malformed entries gracefully
      }
    }
    return categories;
  }

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    final categories = await getAllCategories();
    return categories.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<CategoryModel?> saveCategory(CategoryModel category) async {
    try {
      if (category.name.trim().isEmpty) return null;

      final prefs = await _instance;
      final categories = await getAllCategories();

      // Prevent self-parenting
      if (category.id != null && category.parentId == category.id) {
        return null;
      }

      // Validate parent exists if specified
      if (category.parentId != null) {
        final parentExists = categories.any((c) => c.id == category.parentId);
        if (!parentExists) return null;
      }

      final existingIndex = category.id != null
          ? categories.indexWhere((c) => c.id == category.id)
          : -1;

      final CategoryModel newCat;
      if (existingIndex != -1) {
        // Upsert existing category with given ID
        newCat = CategoryModel(
          id: category.id,
          name: category.name.trim(),
          parentId: category.parentId,
          description: category.description,
          code: category.code,
          createdAt: category.createdAt,
        );
        categories[existingIndex] = newCat;
      } else {
        final maxId = categories.fold<int>(
          0,
          (max, c) => (c.id != null && c.id! > max) ? c.id! : max,
        );
        final assignedId = category.id ?? (maxId + 1);

        newCat = CategoryModel(
          id: assignedId,
          name: category.name.trim(),
          parentId: category.parentId,
          description: category.description,
          code: category.code,
          createdAt: category.createdAt,
        );
        categories.add(newCat);
      }

      final jsonList = categories.map((c) => json.encode(c.toMap())).toList();
      await prefs.setStringList(_categoriesKey, jsonList);

      return newCat;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      if (category.id == null || category.name.trim().isEmpty) return false;
      final prefs = await _instance;
      final categories = await getAllCategories();

      final index = categories.indexWhere((c) => c.id == category.id);
      if (index == -1) return false;

      // Prevent circular reference: category cannot be its own parent
      if (category.parentId == category.id) {
        return false;
      }

      if (category.parentId != null) {
        // Validate that specified parent exists
        final parentExists = categories.any((c) => c.id == category.parentId);
        if (!parentExists) return false;

        // Prevent setting parent to one of its descendants
        final descendants = _getDescendantIds(category.id!, categories);
        if (descendants.contains(category.parentId)) {
          return false;
        }
      }

      categories[index] = CategoryModel(
        id: category.id,
        name: category.name.trim(),
        parentId: category.parentId,
        description: category.description,
        code: category.code,
        createdAt: category.createdAt,
      );

      final jsonList = categories.map((c) => json.encode(c.toMap())).toList();
      await prefs.setStringList(_categoriesKey, jsonList);

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteCategory(
    int id, {
    bool deleteSubCategories = false,
  }) async {
    try {
      final prefs = await _instance;
      final categories = await getAllCategories();

      final exists = categories.any((c) => c.id == id);
      if (!exists) {
        return false;
      }

      if (deleteSubCategories) {
        final allDescendants = _getDescendantIds(id, categories);
        final toRemove = {id, ...allDescendants};
        categories.removeWhere((c) => toRemove.contains(c.id));
      } else {
        for (var i = 0; i < categories.length; i++) {
          if (categories[i].parentId == id) {
            categories[i] = CategoryModel(
              id: categories[i].id,
              name: categories[i].name,
              parentId: null,
              description: categories[i].description,
              code: categories[i].code,
              createdAt: categories[i].createdAt,
            );
          }
        }
        categories.removeWhere((c) => c.id == id);
      }

      final jsonList = categories.map((c) => json.encode(c.toMap())).toList();
      await prefs.setStringList(_categoriesKey, jsonList);

      return true;
    } catch (_) {
      return false;
    }
  }

  Set<int> _getDescendantIds(int categoryId, List<CategoryModel> categories) {
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
}
