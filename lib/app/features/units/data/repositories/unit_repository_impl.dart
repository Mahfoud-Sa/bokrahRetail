import 'package:bokrah_retail/app/features/units/data/datasources/unit_local_datasource.dart';
import 'package:bokrah_retail/app/features/units/data/models/unit_model.dart';
import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:bokrah_retail/app/features/units/domain/repositories/unit_repository.dart';

class UnitRepositoryImpl implements UnitRepository {
  final UnitLocalDataSource localDataSource;

  UnitRepositoryImpl({required this.localDataSource});

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
  Future<bool> saveUnits(List<UnitEntity> units) async {
    final models = units.map((u) => UnitModel.fromEntity(u)).toList();
    return await localDataSource.saveUnits(models);
  }

  @override
  Future<bool> deleteUnitsByItemId(int itemId) async {
    return await localDataSource.deleteUnitsByItemId(itemId);
  }
}
