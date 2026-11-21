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
      id: map['id'],
      name: map['name'] ?? '',
      parentId: map['parentId'],
      description: map['description'],
      code: map['code'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
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
