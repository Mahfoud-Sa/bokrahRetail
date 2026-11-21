import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/departments/domain/repositories/departments_repository.dart';

class GetAllDepartmentsUseCase {
  final DepartmentsRepository repository;
  GetAllDepartmentsUseCase(this.repository);

  Future<List<DepartmentEntity>> call() async {
    return await repository.getAllDepartments();
  }
}

class GetDepartmentByIdUseCase {
  final DepartmentsRepository repository;
  GetDepartmentByIdUseCase(this.repository);

  Future<DepartmentEntity?> call(int id) async {
    return await repository.getDepartmentById(id);
  }
}

class SaveDepartmentUseCase {
  final DepartmentsRepository repository;
  SaveDepartmentUseCase(this.repository);

  Future<DepartmentEntity?> call(DepartmentEntity department) async {
    return await repository.saveDepartment(department);
  }
}

class UpdateDepartmentUseCase {
  final DepartmentsRepository repository;
  UpdateDepartmentUseCase(this.repository);

  Future<bool> call(DepartmentEntity department) async {
    return await repository.updateDepartment(department);
  }
}

class DeleteDepartmentUseCase {
  final DepartmentsRepository repository;
  DeleteDepartmentUseCase(this.repository);

  Future<bool> call(int id) async {
    return await repository.deleteDepartment(id);
  }
}
