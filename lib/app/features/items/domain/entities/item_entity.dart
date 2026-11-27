enum ItemUsageStatus {
  newItem('new', 'جديد', 'New'),
  renew('renew', 'مجدد', 'Renew'),
  used('used', 'مستعمل', 'Used');

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
    if (normalized == 'renewed' ||
        normalized == 'second' ||
        normalized == 'open box' ||
        normalized == 'openbox') {
      return ItemUsageStatus.renew;
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
  final List<String> advantages;
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
    this.advantages = const [],
    this.sellPrice = 0.0,
    this.purchasePrice = 0.0,
    this.quantity = 0,
    this.qrCode,
    this.departmentId,
    this.categoryId,
    DateTime? createdAt,
  }) : subname = subname ?? popularName,
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

  // Business logic: profit margin
  double get profitMargin => sellPrice - purchasePrice;

  // Business logic: profit percentage
  double get profitPercentage => purchasePrice > 0
      ? ((sellPrice - purchasePrice) / purchasePrice) * 100
      : 0.0;

  bool get isProfitable => profitMargin > 0;

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
    List<String>? advantages,
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
      advantages: advantages ?? this.advantages,
      sellPrice: sellPrice ?? this.sellPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      quantity: quantity ?? this.quantity,
      qrCode: qrCode ?? this.qrCode,
      departmentId: clearDepartment
          ? null
          : (departmentId ?? this.departmentId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
