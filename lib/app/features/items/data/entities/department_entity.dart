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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DepartmentEntity.fromMap(Map<String, dynamic> map) {
    return DepartmentEntity(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'],
      code: map['code'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
