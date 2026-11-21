import 'dart:convert';
import 'package:bokrah_retail/app/features/departments/data/models/department_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class DepartmentsLocalDataSource {
  Future<List<DepartmentModel>> getAllDepartments();
  Future<DepartmentModel?> getDepartmentById(int id);
  Future<DepartmentModel?> saveDepartment(DepartmentModel department);
  Future<bool> updateDepartment(DepartmentModel department);
  Future<bool> deleteDepartment(int id);
}

class DepartmentsLocalDataSourceImpl implements DepartmentsLocalDataSource {
  static const String _departmentsKey = 'departments_list';
  final SharedPreferences? _prefs;

  DepartmentsLocalDataSourceImpl({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  @override
  Future<List<DepartmentModel>> getAllDepartments() async {
    final prefs = await _instance;
    final jsonList = prefs.getStringList(_departmentsKey);

    if (jsonList == null || jsonList.isEmpty) {
      final initial = _getDefaultDepartments();
      final initialJson = initial.map((d) => json.encode(d.toMap())).toList();
      await prefs.setStringList(_departmentsKey, initialJson);
      return initial;
    }

    return jsonList.map((jsonString) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return DepartmentModel.fromMap(map);
    }).toList();
  }

  @override
  Future<DepartmentModel?> getDepartmentById(int id) async {
    final departments = await getAllDepartments();
    try {
      return departments.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DepartmentModel?> saveDepartment(DepartmentModel department) async {
    try {
      final prefs = await _instance;
      final departments = await getAllDepartments();

      final newDept = department.id != null
          ? department
          : DepartmentModel(
              id: DateTime.now().millisecondsSinceEpoch,
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
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateDepartment(DepartmentModel department) async {
    try {
      final prefs = await _instance;
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
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteDepartment(int id) async {
    try {
      final prefs = await _instance;
      final departments = await getAllDepartments();

      departments.removeWhere((d) => d.id == id);

      final jsonList =
          departments.map((d) => json.encode(d.toMap())).toList();
      await prefs.setStringList(_departmentsKey, jsonList);

      return true;
    } catch (_) {
      return false;
    }
  }

  List<DepartmentModel> _getDefaultDepartments() {
    return [
      DepartmentModel(
        id: 1,
        name: 'قسم الإلكترونيات',
        code: 'DEPT-ELEC',
        description: 'الأجهزة الإلكترونية والكهربائية',
      ),
      DepartmentModel(
        id: 2,
        name: 'قسم الملابس',
        code: 'DEPT-CLOTH',
        description: 'الملابس والأزياء لجميع الفئات',
      ),
      DepartmentModel(
        id: 3,
        name: 'قسم المواد الغذائية',
        code: 'DEPT-FOOD',
        description: 'الأغذية والمشروبات والمنتجات الاستهلاكية',
      ),
    ];
  }
}
