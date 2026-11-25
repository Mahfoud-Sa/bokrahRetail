import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';

class CompanyModel extends CompanyEntity {
  CompanyModel({
    super.id,
    required super.name,
    required super.arabicName,
    required super.englishName,
    super.brands = const [],
    super.image,
    super.code,
    super.description,
    super.website,
    super.email,
    super.phone,
    super.address,
    super.createdAt,
    super.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'arabicName': arabicName,
      'englishName': englishName,
      'brands': brands,
      'image': image,
      'code': code,
      'description': description,
      'website': website,
      'email': email,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? ''),
      name: map['name']?.toString() ?? '',
      arabicName: map['arabicName']?.toString() ?? map['nameAr']?.toString() ?? '',
      englishName: map['englishName']?.toString() ?? map['nameEn']?.toString() ?? '',
      brands: map['brands'] is List
          ? (map['brands'] as List).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
          : <String>[],
      image: map['image']?.toString() ?? map['imageUrl']?.toString() ?? map['logo']?.toString(),
      code: map['code']?.toString(),
      description: map['description']?.toString(),
      website: map['website']?.toString(),
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }

  factory CompanyModel.fromEntity(CompanyEntity entity) {
    return CompanyModel(
      id: entity.id,
      name: entity.name,
      arabicName: entity.arabicName,
      englishName: entity.englishName,
      brands: entity.brands,
      image: entity.image,
      code: entity.code,
      description: entity.description,
      website: entity.website,
      email: entity.email,
      phone: entity.phone,
      address: entity.address,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
