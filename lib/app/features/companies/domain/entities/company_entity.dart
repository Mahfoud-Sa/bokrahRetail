class CompanyEntity {
  final int? id;
  final String name;
  final String arabicName;
  final String englishName;
  final List<String> brands;
  final String? image;
  final String? code;
  final String? description;
  final String? website;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CompanyEntity({
    this.id,
    String? name,
    required this.arabicName,
    required this.englishName,
    this.brands = const [],
    this.image,
    this.code,
    this.description,
    this.website,
    this.email,
    this.phone,
    this.address,
    DateTime? createdAt,
    this.updatedAt,
  })  : name = (name != null && name.trim().isNotEmpty)
            ? name.trim()
            : (englishName.trim().isNotEmpty
                ? englishName.trim()
                : arabicName.trim()),
        createdAt = createdAt ?? DateTime.now();

  /// Returns localized display name based on locale
  String localizedName(bool isArabic) {
    if (isArabic) {
      return arabicName.isNotEmpty ? arabicName : name;
    } else {
      return englishName.isNotEmpty ? englishName : name;
    }
  }

  /// Domain method: Checks whether any of the company's names match [query] exactly (case-insensitive).
  bool matchesName(String query) {
    if (query.trim().isEmpty) return false;
    final q = query.trim().toLowerCase();
    return name.toLowerCase() == q ||
        arabicName.toLowerCase() == q ||
        englishName.toLowerCase() == q;
  }

  /// Domain method: Checks whether the company matches a free-text search query across names, code, brands, or description.
  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    final nameMatch = name.toLowerCase().contains(q) ||
        arabicName.toLowerCase().contains(q) ||
        englishName.toLowerCase().contains(q);
    final codeMatch = code?.toLowerCase().contains(q) ?? false;
    final brandMatch = brands.any((b) => b.toLowerCase().contains(q));
    final descMatch = description?.toLowerCase().contains(q) ?? false;
    return nameMatch || codeMatch || brandMatch || descMatch;
  }

  /// Domain method: Checks if this company manufactures or distributes the specified brand.
  bool hasBrand(String brand) {
    if (brand.trim().isEmpty) return false;
    final bLower = brand.trim().toLowerCase();
    return brands.any((b) => b.trim().toLowerCase() == bLower);
  }

  CompanyEntity copyWith({
    int? id,
    String? name,
    String? arabicName,
    String? englishName,
    List<String>? brands,
    String? image,
    bool clearImage = false,
    String? code,
    String? description,
    String? website,
    String? email,
    String? phone,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      arabicName: arabicName ?? this.arabicName,
      englishName: englishName ?? this.englishName,
      brands: brands ?? this.brands,
      image: clearImage ? null : (image ?? this.image),
      code: code ?? this.code,
      description: description ?? this.description,
      website: website ?? this.website,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
