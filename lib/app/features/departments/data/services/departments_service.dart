import 'package:bokrah_retail/app/features/departments/data/repositories/departments_repository_impl.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/departments/domain/repositories/departments_repository.dart';

class DepartmentsService {
  final DepartmentsRepository _repository;

  DepartmentsService({DepartmentsRepository? repository})
      : _repository = repository ?? DepartmentsRepositoryImpl();

  Future<List<DepartmentEntity>> getAllDepartments() =>
      _repository.getAllDepartments();
  Future<DepartmentEntity?> saveDepartment(DepartmentEntity department) =>
      _repository.saveDepartment(department);
  Future<bool> updateDepartment(DepartmentEntity department) =>
      _repository.updateDepartment(department);
  Future<bool> deleteDepartment(int id) => _repository.deleteDepartment(id);
  Future<DepartmentEntity?> getDepartmentById(int id) =>
      _repository.getDepartmentById(id);
}
