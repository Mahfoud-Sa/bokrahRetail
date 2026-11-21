import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';

class DepartmentModel extends DepartmentEntity {
  DepartmentModel({
    super.id,
    required super.name,
    super.description,
    super.code,
    super.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'],
      code: map['code'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory DepartmentModel.fromEntity(DepartmentEntity entity) {
    return DepartmentModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      code: entity.code,
      createdAt: entity.createdAt,
    );
  }
}
