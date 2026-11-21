import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';

abstract class DepartmentsRepository {
  Future<List<DepartmentEntity>> getAllDepartments();
  Future<DepartmentEntity?> getDepartmentById(int id);
  Future<DepartmentEntity?> saveDepartment(DepartmentEntity department);
  Future<bool> updateDepartment(DepartmentEntity department);
  Future<bool> deleteDepartment(int id);
}
