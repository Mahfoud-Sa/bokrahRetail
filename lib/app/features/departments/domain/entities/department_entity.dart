class DepartmentEntity {
  final int? id;
  final String name;
  final String? description;
  final String? code;
  final DateTime createdAt;

  DepartmentEntity({
    this.id,
    required this.name,
    this.description,
    this.code,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  DepartmentEntity copyWith({
    int? id,
    String? name,
    String? description,
    String? code,
    DateTime? createdAt,
  }) {
    return DepartmentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
