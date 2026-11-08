import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';

class UnitModel extends UnitEntity {
  const UnitModel({
    super.id,
    required super.name,
    required super.factor,
    required super.itemId,
    super.barcodes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'factor': factor,
      'itemId': itemId,
      'barcodes': barcodes,
    };
  }

  factory UnitModel.fromMap(Map<String, dynamic> map) {
    return UnitModel(
      id: map['id'],
      name: map['name'],
      factor: map['factor']?.toDouble() ?? 1.0,
      itemId: map['itemId'],
      barcodes: List<String>.from(map['barcodes'] ?? []),
    );
  }

  factory UnitModel.fromEntity(UnitEntity entity) {
    return UnitModel(
      id: entity.id,
      name: entity.name,
      factor: entity.factor,
      itemId: entity.itemId,
      barcodes: entity.barcodes,
    );
  }
}
