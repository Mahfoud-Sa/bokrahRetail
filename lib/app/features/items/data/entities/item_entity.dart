class ItemEntity {
  final int? id;
  final String name;
  final String? popularName;
  final List<String> images;
  final String? baseImage;
  final String? companyName;
  final String? color;
  final String? size;
  final List<String> barcodes;
  final double sellPrice;
  final double purchasePrice;
  final int quantity;
  final String? qrCode;
  final String? description;
  final int? categoryId;
  final DateTime createdAt;

  ItemEntity({
    this.id,
    required this.name,
    this.popularName,
    this.images = const [],
    this.baseImage,
    this.companyName,
    this.color,
    this.size,
    this.barcodes = const [],
    required this.sellPrice,
    required this.purchasePrice,
    required this.quantity,
    this.qrCode,
    this.description,
    this.categoryId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'popularName': popularName,
      'images': images,
      'baseImage': baseImage,
      'companyName': companyName,
      'color': color,
      'size': size,
      'barcodes': barcodes,
      'sellPrice': sellPrice,
      'purchasePrice': purchasePrice,
      'quantity': quantity,
      'qrCode': qrCode,
      'description': description,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ItemEntity.fromMap(Map<String, dynamic> map) {
    return ItemEntity(
      id: map['id'],
      name: map['name'],
      popularName: map['popularName'],
      images: List<String>.from(map['images'] ?? []),
      baseImage: map['baseImage'],
      companyName: map['companyName'],
      color: map['color'],
      size: map['size'],
      barcodes: List<String>.from(map['barcodes'] ?? []),
      sellPrice:
          map['sellPrice']?.toDouble() ?? map['price']?.toDouble() ?? 0.0,
      purchasePrice: map['purchasePrice']?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 0,
      qrCode: map['qrCode'],
      description: map['description'],
      categoryId: map['categoryId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Calculate profit margin
  double get profitMargin => sellPrice - purchasePrice;

  // Calculate profit percentage
  double get profitPercentage => purchasePrice > 0
      ? ((sellPrice - purchasePrice) / purchasePrice) * 100
      : 0.0;
}
