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
    final jsonList = prefs.getStringList(_categoriesKey);

    if (jsonList == null || jsonList.isEmpty) {
      final initial = _getDefaultCategories();
      final initialJson = initial.map((c) => json.encode(c.toMap())).toList();
      await prefs.setStringList(_categoriesKey, initialJson);
      return initial;
    }

    return jsonList.map((jsonString) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return CategoryModel.fromMap(map);
    }).toList();
  }

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    final categories = await getAllCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CategoryModel?> saveCategory(CategoryModel category) async {
    try {
      final prefs = await _instance;
      final categories = await getAllCategories();

      final newCat = category.id != null
          ? category
          : CategoryModel(
              id: DateTime.now().millisecondsSinceEpoch,
              name: category.name,
              parentId: category.parentId,
              description: category.description,
              code: category.code,
              createdAt: category.createdAt,
            );

      categories.add(newCat);

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
      final prefs = await _instance;
      final categories = await getAllCategories();

      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        if (category.parentId == category.id) {
          return false;
        }

        if (category.parentId != null) {
          final descendants = _getDescendantIds(category.id!, categories);
          if (descendants.contains(category.parentId)) {
            return false;
          }
        }

        categories[index] = category;

        final jsonList =
            categories.map((c) => json.encode(c.toMap())).toList();
        await prefs.setStringList(_categoriesKey, jsonList);

        return true;
      }
      return false;
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

  List<CategoryModel> _getDefaultCategories() {
    return [
      CategoryModel(
        id: 1,
        name: 'الإلكترونيات والتقنية',
        code: 'CAT-ELEC',
        description: 'الأجهزة الإلكترونية والذكية',
      ),
      CategoryModel(
        id: 2,
        name: 'الهواتف المحمولة',
        parentId: 1,
        code: 'CAT-PHONE',
        description: 'الهواتف الذكية والأجهزة المحمولة',
      ),
      CategoryModel(
        id: 3,
        name: 'الهواتف الذكية (Smartphones)',
        parentId: 2,
        code: 'CAT-SMART',
        description: 'أجهزة iOS وأندرويد الذكية',
      ),
      CategoryModel(
        id: 4,
        name: 'إكسسوارات الهواتف',
        parentId: 2,
        code: 'CAT-ACC',
        description: 'أغطية الحماية والشواحن والسماعات',
      ),
      CategoryModel(
        id: 5,
        name: 'أجهزة الكمبيوتر',
        parentId: 1,
        code: 'CAT-PC',
        description: 'أجهزة الكمبيوتر المحمولة والمكتبية',
      ),
      CategoryModel(
        id: 6,
        name: 'الملابس والموضة',
        code: 'CAT-FASH',
        description: 'أزياء وملابس رجالية ونسائية وأطفال',
      ),
      CategoryModel(
        id: 7,
        name: 'ملابس رجالية',
        parentId: 6,
        code: 'CAT-MEN',
        description: 'قمصان وبناطيل وأثواب وأحذية رجالية',
      ),
    ];
  }
}
