import 'dart:convert';
import 'package:bokrah_retail/app/features/items/data/entities/unit_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnitsService {
  static const String _unitsKey = 'units_list';

  Future<List<UnitEntity>> getAllUnits() async {
    final prefs = await SharedPreferences.getInstance();
    final unitsJson = prefs.getStringList(_unitsKey) ?? [];

    return unitsJson.map((jsonString) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return UnitEntity.fromMap(map);
    }).toList();
  }

  Future<List<UnitEntity>> getUnitsByItemId(int itemId) async {
    final allUnits = await getAllUnits();
    return allUnits.where((unit) => unit.itemId == itemId).toList();
  }

  Future<bool> saveUnits(List<UnitEntity> units) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allUnits = await getAllUnits();

      // Remove old units for the items affected to prevent duplicates if updating
      final itemIds = units.map((u) => u.itemId).toSet();
      allUnits.removeWhere((u) => itemIds.contains(u.itemId));

      // Add new units with IDs if missing
      final unitsToSave = units.map((u) {
        if (u.id == null) {
          return UnitEntity(
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
      await prefs.setStringList(_unitsKey, unitsJson);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUnitsByItemId(int itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allUnits = await getAllUnits();

      allUnits.removeWhere((u) => u.itemId == itemId);

      final unitsJson = allUnits.map((u) => json.encode(u.toMap())).toList();
      await prefs.setStringList(_unitsKey, unitsJson);

      return true;
    } catch (e) {
      return false;
    }
  }
}
