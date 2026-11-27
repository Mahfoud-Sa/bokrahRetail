import 'dart:convert';
import 'package:bokrah_retail/app/features/units/data/models/unit_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class UnitLocalDataSource {
  Future<List<UnitModel>> getAllUnits();
  Future<UnitModel?> saveUnit(UnitModel unit);
  Future<bool> updateUnit(UnitModel unit);
  Future<bool> deleteUnit(int id);
  Future<bool> saveUnits(List<UnitModel> units);
  Future<bool> deleteUnitsByItemId(int itemId);
}

class UnitLocalDataSourceImpl implements UnitLocalDataSource {
  static const String _unitsKey = 'units_list';
  final SharedPreferences sharedPreferences;

  UnitLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<UnitModel>> getAllUnits() async {
    final unitsJson = sharedPreferences.getStringList(_unitsKey) ?? [];
    return unitsJson.map((jsonString) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return UnitModel.fromMap(map);
    }).toList();
  }

  @override
  Future<UnitModel?> saveUnit(UnitModel unit) async {
    try {
      final allUnits = await getAllUnits();
      final nextId = unit.id ??
          (allUnits.fold<int>(
                0,
                (max, u) => (u.id != null && u.id! > max) ? u.id! : max,
              ) +
              1);
      final saved = UnitModel(
        id: nextId,
        name: unit.name.trim(),
        factor: unit.factor,
        itemId: unit.itemId,
        barcodes: unit.barcodes,
      );
      allUnits.add(saved);
      final unitsJson = allUnits.map((u) => json.encode(u.toMap())).toList();
      final ok = await sharedPreferences.setStringList(_unitsKey, unitsJson);
      return ok ? saved : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateUnit(UnitModel unit) async {
    try {
      if (unit.id == null) return false;
      final allUnits = await getAllUnits();
      final index = allUnits.indexWhere((u) => u.id == unit.id);
      if (index == -1) return false;

      allUnits[index] = UnitModel(
        id: unit.id,
        name: unit.name.trim(),
        factor: unit.factor,
        itemId: unit.itemId,
        barcodes: unit.barcodes,
      );
      final unitsJson = allUnits.map((u) => json.encode(u.toMap())).toList();
      return await sharedPreferences.setStringList(_unitsKey, unitsJson);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteUnit(int id) async {
    try {
      final allUnits = await getAllUnits();
      final initialLength = allUnits.length;
      allUnits.removeWhere((u) => u.id == id);
      if (allUnits.length == initialLength) return false;

      final unitsJson = allUnits.map((u) => json.encode(u.toMap())).toList();
      return await sharedPreferences.setStringList(_unitsKey, unitsJson);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> saveUnits(List<UnitModel> units) async {
    try {
      final allUnits = await getAllUnits();

      // Remove old units for the items affected to prevent duplicates
      final itemIds = units.map((u) => u.itemId).toSet();
      allUnits.removeWhere((u) => itemIds.contains(u.itemId));

      // Add new units with IDs if missing
      final unitsToSave = units.map((u) {
        if (u.id == null) {
          return UnitModel(
            id: DateTime.now().millisecondsSinceEpoch + units.indexOf(u),
            name: u.name,
            factor: u.factor,
            itemId: u.itemId,
            barcodes: u.barcodes,
          );
        }
        return u;
      }).toList();

      allUnits.addAll(unitsToSave);

      final unitsJson = allUnits.map((u) => json.encode(u.toMap())).toList();
      return await sharedPreferences.setStringList(_unitsKey, unitsJson);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteUnitsByItemId(int itemId) async {
    try {
      final allUnits = await getAllUnits();
      allUnits.removeWhere((u) => u.itemId == itemId);

      final unitsJson = allUnits.map((u) => json.encode(u.toMap())).toList();
      return await sharedPreferences.setStringList(_unitsKey, unitsJson);
    } catch (e) {
      return false;
    }
  }
}
