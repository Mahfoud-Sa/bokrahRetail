import 'package:bokrah_retail/app/features/sync/data/services/sync_outbox_recorder.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:bokrah_retail/app/features/units/data/datasources/unit_local_datasource.dart';
import 'package:bokrah_retail/app/features/units/data/models/unit_model.dart';
import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:bokrah_retail/app/features/units/domain/repositories/unit_repository.dart';

class UnitRepositoryImpl implements UnitRepository {
  final UnitLocalDataSource localDataSource;
  final SyncOutboxRecorder _outboxRecorder;

  UnitRepositoryImpl({
    required this.localDataSource,
    SyncOutboxRecorder? outboxRecorder,
  }) : _outboxRecorder = outboxRecorder ?? SyncOutboxRecorder();

  @override
  Future<List<UnitEntity>> getAllUnits() async {
    return await localDataSource.getAllUnits();
  }

  @override
  Future<List<UnitEntity>> getUnitsByItemId(int itemId) async {
    final allUnits = await localDataSource.getAllUnits();
    return allUnits.where((unit) => unit.itemId == itemId).toList();
  }

  @override
  Future<UnitEntity?> saveUnit(UnitEntity unit) async {
    final model = UnitModel.fromEntity(unit);
    final saved = await localDataSource.saveUnit(model);
    if (saved != null && saved.id != null) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.unit,
        operationType: SyncOperationType.create,
        localEntityId: saved.id!,
        payload: saved.toMap(),
      );
    }
    return saved;
  }

  @override
  Future<bool> updateUnit(UnitEntity unit) async {
    final model = UnitModel.fromEntity(unit);
    final ok = await localDataSource.updateUnit(model);
    if (ok && model.id != null) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.unit,
        operationType: SyncOperationType.update,
        localEntityId: model.id!,
        payload: model.toMap(),
      );
    }
    return ok;
  }

  @override
  Future<bool> deleteUnit(int id) async {
    final ok = await localDataSource.deleteUnit(id);
    if (ok) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.unit,
        operationType: SyncOperationType.delete,
        localEntityId: id,
        payload: {'id': id},
      );
    }
    return ok;
  }

  @override
  Future<bool> saveUnits(List<UnitEntity> units) async {
    final models = units.map((u) => UnitModel.fromEntity(u)).toList();
    final ok = await localDataSource.saveUnits(models);
    if (ok && units.isNotEmpty) {
      final itemIds = units.map((u) => u.itemId).toSet();
      final savedAll = await localDataSource.getAllUnits();
      for (final unit in savedAll.where((u) => itemIds.contains(u.itemId))) {
        if (unit.id != null) {
          await _outboxRecorder.record(
            entityType: SyncEntityType.unit,
            operationType: SyncOperationType.create,
            localEntityId: unit.id!,
            payload: unit.toMap(),
          );
        }
      }
    }
    return ok;
  }

  @override
  Future<bool> deleteUnitsByItemId(int itemId) async {
    final existing = await getUnitsByItemId(itemId);
    final ok = await localDataSource.deleteUnitsByItemId(itemId);
    if (ok) {
      for (final unit in existing) {
        if (unit.id != null) {
          await _outboxRecorder.record(
            entityType: SyncEntityType.unit,
            operationType: SyncOperationType.delete,
            localEntityId: unit.id!,
            payload: {'itemId': itemId},
          );
        }
      }
    }
    return ok;
  }
}
