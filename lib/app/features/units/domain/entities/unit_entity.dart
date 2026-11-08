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
}
