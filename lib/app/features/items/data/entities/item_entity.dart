enum ItemUsageStatus {
  newItem('new', 'جديد', 'New'),
  second('second', 'درجة ثانية', 'Second'),
  used('used', 'مستعمل', 'Used'),
  openBox('open box', 'صندوق مفتوح', 'Open Box');

  final String value;
  final String labelAr;
  final String labelEn;
  const ItemUsageStatus(this.value, this.labelAr, this.labelEn);

  static ItemUsageStatus fromString(String? val) {
    if (val == null || val.trim().isEmpty) return ItemUsageStatus.newItem;
    final normalized = val.trim().toLowerCase();
    for (final status in ItemUsageStatus.values) {
      if (status.value.toLowerCase() == normalized ||
          status.name.toLowerCase() == normalized ||
          status.labelAr == normalized ||
          status.labelEn.toLowerCase() == normalized) {
        return status;
      }
    }
    return ItemUsageStatus.newItem;
  }
}

class ItemEntity {
  final int? id;
  final String name;
  final String? subname;
  final String? popularName; // Alias for backward compatibility
  final ItemUsageStatus usageStatus;
  final String? mainImage;
  final String? baseImage; // Alias for backward compatibility
  final List<String> subImages;
  final List<String> images; // Alias for backward compatibility
  final String? video;
  final String? company;
  final String? companyName; // Alias for backward compatibility
  final String? brand;
  final int? manufactureYear;
  final String? shortDescription;
  final String? fullDescription;
  final String? description; // Alias for backward compatibility
  final String? color;
  final String? size;
  final List<String> barcodes;
  final double sellPrice;
  final double purchasePrice;
  final int quantity;
  final String? qrCode;
  final int? departmentId;
  final int? categoryId;
  final DateTime createdAt;

  ItemEntity({
    this.id,
    required this.name,
    String? subname,
    String? popularName,
    this.usageStatus = ItemUsageStatus.newItem,
    String? mainImage,
    String? baseImage,
    List<String>? subImages,
    List<String>? images,
    this.video,
    String? company,
    String? companyName,
    this.brand,
    this.manufactureYear,
    this.shortDescription,
    String? fullDescription,
    String? description,
    this.color,
    this.size,
    this.barcodes = const [],
    this.sellPrice = 0.0,
    this.purchasePrice = 0.0,
    this.quantity = 0,
    this.qrCode,
    this.departmentId,
    this.categoryId,
    DateTime? createdAt,
  })  : subname = subname ?? popularName,
        popularName = popularName ?? subname,
        mainImage = mainImage ?? baseImage,
        baseImage = baseImage ?? mainImage,
        subImages = subImages ?? images ?? const [],
        images = images ?? subImages ?? const [],
        company = company ?? companyName,
        companyName = companyName ?? company,
        fullDescription = fullDescription ?? description,
        description = description ?? fullDescription,
        createdAt = createdAt ?? DateTime.now();

  // Convenient getters
  String? get effectiveSubname => subname ?? popularName;
  String? get effectiveMainImage => mainImage ?? baseImage;
  List<String> get effectiveSubImages =>
      subImages.isNotEmpty ? subImages : images;
  String? get effectiveCompany => company ?? companyName;
  String? get effectiveFullDescription => fullDescription ?? description;
  int? get effectiveDepartmentId => departmentId;
  int? get effectiveCategoryId => categoryId;

  ItemEntity copyWith({
    int? id,
    String? name,
    String? subname,
    ItemUsageStatus? usageStatus,
    String? mainImage,
    List<String>? subImages,
    String? video,
    String? company,
    String? brand,
    int? manufactureYear,
    String? shortDescription,
    String? fullDescription,
    String? color,
    String? size,
    List<String>? barcodes,
    double? sellPrice,
    double? purchasePrice,
    int? quantity,
    String? qrCode,
    int? departmentId,
    bool clearDepartment = false,
    int? categoryId,
    bool clearCategory = false,
    DateTime? createdAt,
  }) {
    return ItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      subname: subname ?? this.subname,
      usageStatus: usageStatus ?? this.usageStatus,
      mainImage: mainImage ?? this.mainImage,
      subImages: subImages ?? this.subImages,
      video: video ?? this.video,
      company: company ?? this.company,
      brand: brand ?? this.brand,
      manufactureYear: manufactureYear ?? this.manufactureYear,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      color: color ?? this.color,
      size: size ?? this.size,
      barcodes: barcodes ?? this.barcodes,
      sellPrice: sellPrice ?? this.sellPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      quantity: quantity ?? this.quantity,
      qrCode: qrCode ?? this.qrCode,
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
      'sellPrice': sellPrice,
      'purchasePrice': purchasePrice,
      'quantity': quantity,
      'qrCode': qrCode,
      'departmentId': departmentId,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ItemEntity.fromMap(Map<String, dynamic> map) {
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
    final deptId = map['departmentId'] as int?;
    final catId = map['categoryId'] as int?;

    return ItemEntity(
      id: map['id'],
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

  // Calculate profit margin
  double get profitMargin => sellPrice - purchasePrice;

  // Calculate profit percentage
  double get profitPercentage => purchasePrice > 0
      ? ((sellPrice - purchasePrice) / purchasePrice) * 100
      : 0.0;
}
