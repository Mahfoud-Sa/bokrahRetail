import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';

class ItemModel extends ItemEntity {
  ItemModel({
    super.id,
    required super.name,
    super.subname,
    super.popularName,
    super.usageStatus = ItemUsageStatus.newItem,
    super.mainImage,
    super.baseImage,
    super.subImages,
    super.images,
    super.video,
    super.company,
    super.companyName,
    super.brand,
    super.manufactureYear,
    super.shortDescription,
    super.fullDescription,
    super.description,
    super.color,
    super.size,
    super.barcodes = const [],
    super.advantages = const [],
    super.sellPrice = 0.0,
    super.purchasePrice = 0.0,
    super.quantity = 0,
    super.qrCode,
    super.departmentId,
    super.categoryId,
    super.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subname': subname ?? popularName,
      'popularName': popularName ?? subname,
      'usageStatus': usageStatus.value,
      'mainImage': mainImage ?? baseImage,
      'baseImage': baseImage ?? mainImage,
      'subImages': subImages.isNotEmpty ? subImages : images,
      'images': images.isNotEmpty ? images : subImages,
      'video': video,
      'company': company ?? companyName,
      'companyName': companyName ?? company,
      'brand': brand,
      'manufactureYear': manufactureYear,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription ?? description,
      'description': description ?? fullDescription,
      'color': color,
      'size': size,
      'barcodes': barcodes,
      'advantages': advantages,
      'sellPrice': sellPrice,
      'purchasePrice': purchasePrice,
      'quantity': quantity,
      'qrCode': qrCode,
      'departmentId': departmentId,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    final mainImg = map['mainImage'] as String? ?? map['baseImage'] as String?;
    final subImgs = List<String>.from(map['subImages'] ?? map['images'] ?? []);
    final subNm = map['subname'] as String? ?? map['popularName'] as String?;
    final comp = map['company'] as String? ?? map['companyName'] as String?;
    final fullDesc =
        map['fullDescription'] as String? ?? map['description'] as String?;
    final shortDesc = map['shortDescription'] as String?;
    final brandVal = map['brand'] as String?;
    final videoVal = map['video'] as String?;
    final yearVal = map['manufactureYear'] != null
        ? int.tryParse(map['manufactureYear'].toString())
        : null;
    final status = ItemUsageStatus.fromString(
      map['usageStatus'] as String? ?? map['usage_status'] as String?,
    );
    int? parseOptionalInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    final itemId = parseOptionalInt(map['id']);
    final deptId = parseOptionalInt(
      map['departmentId'] ?? map['department_id'],
    );
    final catId = parseOptionalInt(map['categoryId'] ?? map['category_id']);

    return ItemModel(
      id: itemId,
      name: map['name'] ?? '',
      subname: subNm,
      popularName: subNm,
      usageStatus: status,
      mainImage: mainImg,
      baseImage: mainImg,
      subImages: subImgs,
      images: subImgs,
      video: videoVal,
      company: comp,
      companyName: comp,
      brand: brandVal,
      manufactureYear: yearVal,
      shortDescription: shortDesc,
      fullDescription: fullDesc,
      description: fullDesc,
      color: map['color'],
      size: map['size'],
      barcodes: List<String>.from(map['barcodes'] ?? []),
      advantages: List<String>.from(map['advantages'] ?? const []),
      sellPrice:
          map['sellPrice']?.toDouble() ?? map['price']?.toDouble() ?? 0.0,
      purchasePrice: map['purchasePrice']?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 0,
      qrCode: map['qrCode'],
      departmentId: deptId,
      categoryId: catId,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory ItemModel.fromEntity(ItemEntity entity) {
    return ItemModel(
      id: entity.id,
      name: entity.name,
      subname: entity.subname,
      popularName: entity.popularName,
      usageStatus: entity.usageStatus,
      mainImage: entity.mainImage,
      baseImage: entity.baseImage,
      subImages: entity.subImages,
      images: entity.images,
      video: entity.video,
      company: entity.company,
      companyName: entity.companyName,
      brand: entity.brand,
      manufactureYear: entity.manufactureYear,
      shortDescription: entity.shortDescription,
      fullDescription: entity.fullDescription,
      description: entity.description,
      color: entity.color,
      size: entity.size,
      barcodes: entity.barcodes,
      advantages: entity.advantages,
      sellPrice: entity.sellPrice,
      purchasePrice: entity.purchasePrice,
      quantity: entity.quantity,
      qrCode: entity.qrCode,
      departmentId: entity.departmentId,
      categoryId: entity.categoryId,
      createdAt: entity.createdAt,
    );
  }
}
