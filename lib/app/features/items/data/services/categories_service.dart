import 'dart:convert';
import 'package:bokrah_retail/app/features/items/data/entities/category_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesService {
  static const String _categoriesKey = 'categories_list';

  Future<List<CategoryEntity>> getAllCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getStringList(_categoriesKey) ?? [];

    return categoriesJson.map((jsonString) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return CategoryEntity.fromMap(map);
    }).toList();
  }

  Future<bool> saveCategory(CategoryEntity category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = await getAllCategories();

      final newCategory = CategoryEntity(
        id: category.id ?? DateTime.now().millisecondsSinceEpoch,
        name: category.name,
        description: category.description,
        createdAt: category.createdAt,
      );

      categories.add(newCategory);

      final categoriesJson = categories
          .map((c) => json.encode(c.toMap()))
          .toList();
      await prefs.setStringList(_categoriesKey, categoriesJson);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCategory(CategoryEntity category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = await getAllCategories();

      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        categories[index] = category;

        final categoriesJson = categories
            .map((c) => json.encode(c.toMap()))
            .toList();
        await prefs.setStringList(_categoriesKey, categoriesJson);

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = await getAllCategories();

      categories.removeWhere((c) => c.id == id);

      final categoriesJson = categories
          .map((c) => json.encode(c.toMap()))
          .toList();
      await prefs.setStringList(_categoriesKey, categoriesJson);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<CategoryEntity?> getCategoryById(int id) async {
    final categories = await getAllCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
