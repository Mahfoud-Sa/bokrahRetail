import 'package:bokrah_retail/app/features/departments/data/datasources/departments_local_datasource.dart';
import 'package:bokrah_retail/app/features/departments/data/models/department_model.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/departments/domain/repositories/departments_repository.dart';

class DepartmentsRepositoryImpl implements DepartmentsRepository {
  final DepartmentsLocalDataSource localDataSource;

  DepartmentsRepositoryImpl({DepartmentsLocalDataSource? localDataSource})
      : localDataSource =
            localDataSource ?? DepartmentsLocalDataSourceImpl();

  @override
  Future<List<DepartmentEntity>> getAllDepartments() async {
    return await localDataSource.getAllDepartments();
  }

  @override
  Future<DepartmentEntity?> getDepartmentById(int id) async {
    return await localDataSource.getDepartmentById(id);
  }

  @override
  Future<DepartmentEntity?> saveDepartment(DepartmentEntity department) async {
    final model = DepartmentModel.fromEntity(department);
    return await localDataSource.saveDepartment(model);
  }

  @override
  Future<bool> updateDepartment(DepartmentEntity department) async {
    final model = DepartmentModel.fromEntity(department);
    return await localDataSource.updateDepartment(model);
  }

  @override
  Future<bool> deleteDepartment(int id) async {
    return await localDataSource.deleteDepartment(id);
  }
}
