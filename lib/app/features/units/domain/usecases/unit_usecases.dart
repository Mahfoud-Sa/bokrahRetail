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
