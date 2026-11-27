import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  CategoryModel({
    super.id,
    required super.name,
    super.parentId,
    super.description,
    super.code,
    super.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'description': description,
      'code': code,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] is int
          ? map['id'] as int
          : (map['id'] is num
                ? (map['id'] as num).toInt()
                : int.tryParse(map['id']?.toString() ?? '')),
      name: map['name']?.toString() ?? '',
      parentId: map['parentId'] is int
          ? map['parentId'] as int
          : (map['parentId'] is num
                ? (map['parentId'] as num).toInt()
                : int.tryParse(map['parentId']?.toString() ?? '')),
      description: map['description']?.toString(),
      code: map['code']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      parentId: entity.parentId,
      description: entity.description,
      code: entity.code,
      createdAt: entity.createdAt,
    );
  }
}
