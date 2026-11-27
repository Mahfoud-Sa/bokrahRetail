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

  /// Domain method: Checks whether the category matches a search query across name, code, or description.
  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    final nameMatch = name.toLowerCase().contains(q);
    final codeMatch = code?.toLowerCase().contains(q) ?? false;
    final descMatch = description?.toLowerCase().contains(q) ?? false;
    return nameMatch || codeMatch || descMatch;
  }

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          parentId == other.parentId &&
          code == other.code &&
          description == other.description;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      parentId.hashCode ^
      code.hashCode ^
      description.hashCode;
}
