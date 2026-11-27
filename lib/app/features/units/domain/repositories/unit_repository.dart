import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';

abstract class UnitRepository {
  Future<List<UnitEntity>> getAllUnits();
  Future<List<UnitEntity>> getUnitsByItemId(int itemId);
  Future<UnitEntity?> saveUnit(UnitEntity unit);
  Future<bool> updateUnit(UnitEntity unit);
  Future<bool> deleteUnit(int id);
  Future<bool> saveUnits(List<UnitEntity> units);
  Future<bool> deleteUnitsByItemId(int itemId);
}
