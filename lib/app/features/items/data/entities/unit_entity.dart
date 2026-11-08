class UnitEntity {
  final int? id;
  final String name;
  final double
  factor; // Conversion factor to base unit (base unit has factor 1.0)
  final int itemId; // Foreign key to ItemEntity
  final List<String> barcodes;

  UnitEntity({
    this.id,
    required this.name,
    required this.factor,
    required this.itemId,
    this.barcodes = const [],
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

  factory UnitEntity.fromMap(Map<String, dynamic> map) {
    return UnitEntity(
      id: map['id'],
      name: map['name'],
      factor: map['factor']?.toDouble() ?? 1.0,
      itemId: map['itemId'],
      barcodes: List<String>.from(map['barcodes'] ?? []),
    );
  }
}
