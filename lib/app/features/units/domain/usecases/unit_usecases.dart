import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:bokrah_retail/app/features/units/domain/repositories/unit_repository.dart';

class GetAllUnitsUseCase {
  final UnitRepository repository;
  GetAllUnitsUseCase(this.repository);

  Future<List<UnitEntity>> call() async {
    return await repository.getAllUnits();
  }
}

class GetUnitsByItemIdUseCase {
  final UnitRepository repository;
  GetUnitsByItemIdUseCase(this.repository);

  Future<List<UnitEntity>> call(int itemId) async {
    return await repository.getUnitsByItemId(itemId);
  }
}

class SaveUnitUseCase {
  final UnitRepository repository;
  SaveUnitUseCase(this.repository);

  Future<UnitEntity?> call(UnitEntity unit) async {
    return await repository.saveUnit(unit);
  }
}

class UpdateUnitUseCase {
  final UnitRepository repository;
  UpdateUnitUseCase(this.repository);

  Future<bool> call(UnitEntity unit) async {
    return await repository.updateUnit(unit);
  }
}

class DeleteUnitUseCase {
  final UnitRepository repository;
  DeleteUnitUseCase(this.repository);

  Future<bool> call(int id) async {
    return await repository.deleteUnit(id);
  }
}

class SaveUnitsUseCase {
  final UnitRepository repository;
  SaveUnitsUseCase(this.repository);

  Future<bool> call(List<UnitEntity> units) async {
    return await repository.saveUnits(units);
  }
}

class DeleteUnitsByItemIdUseCase {
  final UnitRepository repository;
  DeleteUnitsByItemIdUseCase(this.repository);

  Future<bool> call(int itemId) async {
    return await repository.deleteUnitsByItemId(itemId);
  }
}

/// Filters units by name, conversion factor, or associated barcodes.
class SearchUnitsUseCase {
  List<UnitEntity> call(List<UnitEntity> units, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return units;
    return units.where((unit) {
      if (unit.name.toLowerCase().contains(q)) return true;
      if (unit.factor.toString().contains(q)) return true;
      return unit.barcodes.any((b) => b.toLowerCase().contains(q));
    }).toList();
  }
}
