import 'dart:convert';
import 'package:bokrah_retail/app/features/items/data/entities/category_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesService {
  static const String _categoriesKey = 'categories_list';

  Future<List<CategoryEntity>> getAllCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_categoriesKey);

    if (jsonList == null || jsonList.isEmpty) {
      final initial = _getDefaultCategories();
      final initialJson =
          initial.map((c) => json.encode(c.toMap())).toList();
      await prefs.setStringList(_categoriesKey, initialJson);
      return initial;
    }

    return jsonList.map((jsonString) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return CategoryEntity.fromMap(map);
    }).toList();
  }

  Future<CategoryEntity?> saveCategory(CategoryEntity category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = await getAllCategories();

      final newCat = CategoryEntity(
        id: category.id ?? DateTime.now().millisecondsSinceEpoch,
        name: category.name,
        parentId: category.parentId,
        description: category.description,
        code: category.code,
        createdAt: category.createdAt,
      );

      categories.add(newCat);

      final jsonList =
          categories.map((c) => json.encode(c.toMap())).toList();
      await prefs.setStringList(_categoriesKey, jsonList);

      return newCat;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateCategory(CategoryEntity category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = await getAllCategories();

      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        // Prevent assigning category as its own parent
        if (category.parentId == category.id) {
          return false;
        }

        // Prevent circular hierarchy
        if (category.parentId != null) {
          final descendants =
              getDescendantIds(category.id!, categories);
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
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(
    int id, {
    bool deleteSubCategories = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = await getAllCategories();

      if (deleteSubCategories) {
        final allDescendants = getDescendantIds(id, categories);
        final toRemove = {id, ...allDescendants};
        categories.removeWhere((c) => toRemove.contains(c.id));
      } else {
        // Reassign direct children to root (parentId = null)
        for (var i = 0; i < categories.length; i++) {
          if (categories[i].parentId == id) {
            categories[i] = categories[i].copyWith(clearParent: true);
          }
        }
        categories.removeWhere((c) => c.id == id);
      }

      final jsonList =
          categories.map((c) => json.encode(c.toMap())).toList();
      await prefs.setStringList(_categoriesKey, jsonList);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<CategoryEntity?> getCategoryById(int id) async {
    final categories = await getAllCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CategoryEntity> getRootCategories(List<CategoryEntity> categories) {
    return categories.where((c) => c.isRoot).toList();
  }

  List<CategoryEntity> getSubCategories(
    int parentId,
    List<CategoryEntity> categories,
  ) {
    return categories.where((c) => c.parentId == parentId).toList();
  }

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

  List<CategoryEntity> _getDefaultCategories() {
    return [
      CategoryEntity(
        id: 1,
        name: 'الإلكترونيات والتقنية',
        code: 'CAT-ELEC',
        description: 'الأجهزة الإلكترونية والذكية',
      ),
      CategoryEntity(
        id: 2,
        name: 'الهواتف المحمولة',
        parentId: 1,
        code: 'CAT-PHONE',
        description: 'الهواتف الذكية والأجهزة المحمولة',
      ),
      CategoryEntity(
        id: 3,
        name: 'الهواتف الذكية (Smartphones)',
        parentId: 2,
        code: 'CAT-SMART',
        description: 'أجهزة iOS وأندرويد الذكية',
      ),
      CategoryEntity(
        id: 4,
        name: 'إكسسوارات الهواتف',
        parentId: 2,
        code: 'CAT-ACC',
        description: 'أغطية الحماية والشواحن والسماعات',
      ),
      CategoryEntity(
        id: 5,
        name: 'أجهزة الكمبيوتر',
        parentId: 1,
        code: 'CAT-PC',
        description: 'أجهزة الكمبيوتر المحمولة والمكتبية',
      ),
      CategoryEntity(
        id: 6,
        name: 'الملابس والموضة',
        code: 'CAT-FASH',
        description: 'أزياء وملابس رجالية ونسائية وأطفال',
      ),
      CategoryEntity(
        id: 7,
        name: 'ملابس رجالية',
        parentId: 6,
        code: 'CAT-MEN',
        description: 'قمصان وبناطيل وأثواب وأحذية رجالية',
      ),
    ];
  }
}
