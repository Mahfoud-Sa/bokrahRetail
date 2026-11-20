class CategoryEntity {
  final int? id;
  final String name;
  final int? parentId; // null means root category
  final String? description;
  final String? code;
  final DateTime createdAt;

  CategoryEntity({
    this.id,
    required this.name,
    this.parentId,
    this.description,
    this.code,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isRoot => parentId == null;

  CategoryEntity copyWith({
    int? id,
    String? name,
    int? parentId,
    bool clearParent = false,
    String? description,
    String? code,
    DateTime? createdAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      description: description ?? this.description,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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

  factory CategoryEntity.fromMap(Map<String, dynamic> map) {
    return CategoryEntity(
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
}
