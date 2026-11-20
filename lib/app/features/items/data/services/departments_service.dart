import 'dart:convert';
import 'package:bokrah_retail/app/features/items/data/entities/department_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DepartmentsService {
  static const String _departmentsKey = 'departments_list';

  Future<List<DepartmentEntity>> getAllDepartments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_departmentsKey);

    if (jsonList == null || jsonList.isEmpty) {
      final initial = _getDefaultDepartments();
      final initialJson =
          initial.map((d) => json.encode(d.toMap())).toList();
      await prefs.setStringList(_departmentsKey, initialJson);
      return initial;
    }

    return jsonList.map((jsonString) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return DepartmentEntity.fromMap(map);
    }).toList();
  }

  Future<DepartmentEntity?> saveDepartment(DepartmentEntity department) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final departments = await getAllDepartments();

      final newDept = DepartmentEntity(
        id: department.id ?? DateTime.now().millisecondsSinceEpoch,
        name: department.name,
        description: department.description,
        code: department.code,
        createdAt: department.createdAt,
      );

      departments.add(newDept);

      final jsonList =
          departments.map((d) => json.encode(d.toMap())).toList();
      await prefs.setStringList(_departmentsKey, jsonList);

      return newDept;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateDepartment(DepartmentEntity department) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final departments = await getAllDepartments();

      final index = departments.indexWhere((d) => d.id == department.id);
      if (index != -1) {
        departments[index] = department;

        final jsonList =
            departments.map((d) => json.encode(d.toMap())).toList();
        await prefs.setStringList(_departmentsKey, jsonList);

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDepartment(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final departments = await getAllDepartments();

      departments.removeWhere((d) => d.id == id);

      final jsonList =
          departments.map((d) => json.encode(d.toMap())).toList();
      await prefs.setStringList(_departmentsKey, jsonList);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<DepartmentEntity?> getDepartmentById(int id) async {
    final departments = await getAllDepartments();
    try {
      return departments.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<DepartmentEntity> _getDefaultDepartments() {
    return [
      DepartmentEntity(
        id: 1,
        name: 'الأجهزة الإلكترونية',
        code: 'ELEC',
        description: 'الأجهزة الكهربائية والذكية وملحقاتها',
      ),
      DepartmentEntity(
        id: 2,
        name: 'الهواتف الذكية والإكسسوارات',
        code: 'PHONE',
        description: 'الهواتف المحمولة والسماعات والشواحن',
      ),
      DepartmentEntity(
        id: 3,
        name: 'الحواسيب واللابتوب',
        code: 'PC',
        description: 'أجهزة الكمبيوتر المحمولة والمكتبية والشاشات',
      ),
      DepartmentEntity(
        id: 4,
        name: 'الملابس والأزياء',
        code: 'CLOTH',
        description: 'الملابس والأحذية والإكسسوارات',
      ),
      DepartmentEntity(
        id: 5,
        name: 'المواد الغذائية والتموينية',
        code: 'FOOD',
        description: 'المواد التموينية والأغذية المعلبة والمشروبات',
      ),
    ];
  }
}
