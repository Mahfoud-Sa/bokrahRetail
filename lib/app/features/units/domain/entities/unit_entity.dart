class UnitEntity {
  final int? id;
  final String name;
  final double
  factor; // Conversion factor to base unit (base unit has factor 1.0)
  final int itemId; // Foreign key to ItemEntity
  final List<String> barcodes;

  const UnitEntity({
    this.id,
    required this.name,
    required this.factor,
    required this.itemId,
    this.barcodes = const [],
  });

  /// Returns a copy of this unit with the given fields replaced.
  UnitEntity copyWith({
    int? id,
    String? name,
    double? factor,
    int? itemId,
    List<String>? barcodes,
  }) {
    return UnitEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      factor: factor ?? this.factor,
      itemId: itemId ?? this.itemId,
      barcodes: barcodes ?? this.barcodes,
    );
  }
}
