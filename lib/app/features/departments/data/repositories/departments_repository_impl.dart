import 'package:bokrah_retail/app/features/departments/data/datasources/departments_local_datasource.dart';
import 'package:bokrah_retail/app/features/departments/data/models/department_model.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/departments/domain/repositories/departments_repository.dart';
import 'package:bokrah_retail/app/features/sync/data/services/sync_outbox_recorder.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';

class DepartmentsRepositoryImpl implements DepartmentsRepository {
  final DepartmentsLocalDataSource localDataSource;
  final SyncOutboxRecorder _outboxRecorder;

  DepartmentsRepositoryImpl({
    DepartmentsLocalDataSource? localDataSource,
    SyncOutboxRecorder? outboxRecorder,
  })  : localDataSource = localDataSource ?? DepartmentsLocalDataSourceImpl(),
        _outboxRecorder = outboxRecorder ?? SyncOutboxRecorder();

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
    final saved = await localDataSource.saveDepartment(model);
    if (saved != null && saved.id != null) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.department,
        operationType: SyncOperationType.create,
        localEntityId: saved.id!,
        payload: DepartmentModel.fromEntity(saved).toMap(),
      );
    }
    return saved;
  }

  @override
  Future<bool> updateDepartment(DepartmentEntity department) async {
    final model = DepartmentModel.fromEntity(department);
    final ok = await localDataSource.updateDepartment(model);
    if (ok && department.id != null) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.department,
        operationType: SyncOperationType.update,
        localEntityId: department.id!,
        payload: model.toMap(),
      );
    }
    return ok;
  }

  @override
  Future<bool> deleteDepartment(int id) async {
    final ok = await localDataSource.deleteDepartment(id);
    if (ok) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.department,
        operationType: SyncOperationType.delete,
        localEntityId: id,
      );
    }
    return ok;
  }
}
